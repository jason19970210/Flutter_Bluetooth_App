import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart'; // for sum values in  list
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../utils/constants.dart';

List<int> CMD_READ_Battery_Level = [0xA5, 0x04, 0x10, 0x00, 0x14];
List<int> CMD_STOP_Measurement = [0xA5, 0x04, 0x13, 0x00, 0x17];
List<int> CMD_READ_Measurement = [0xA5, 0x04, 0x14, 0x00, 0x18];
List<int> CMD_READ_Device_SN = [0xA5, 0x04, 0x18, 0x00, 0x1C];
List<int> CMD_READ_Device_Software_Version = [0xA5, 0x04, 0x19, 0x00, 0x1D];

FlutterBlue flutterBlue = FlutterBlue.instance;

class MeasurePage extends StatefulWidget {
  MeasurePage({Key? key, required this.token}) : super(key: key);
  final String token;

  @override
  _MeasurePageState createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> {
  late Timer _timer;

  final List<BluetoothDevice> devicesList = [];
  bool isBleReady = false;
  bool isBleScanning = false;
  bool isDeviceConnected = false;
  bool isDeviceReady = false;

  late BluetoothDevice _targetDevice;
  DeviceInfo _connectDeviceInfo = DeviceInfo.init();
  late List<BluetoothService> _services;
  late final BluetoothCharacteristic characteristic_1212;
  late final BluetoothCharacteristic characteristic_1211;
  late final BluetoothCharacteristic characteristic_2a35;

  String displayText = "S: -- , D: -- , H: --";
  int measuringText = 0;

  int commandID = 0x00;

  String _getMacAddr(Map<int, List<int>> manufacturerData) {
    String macAddr = "";
    try {
      macAddr = manufacturerData.keys.first.toRadixString(16).toUpperCase().splitByLength(2).reversed.join();
      manufacturerData.values.first.forEach((element) {
        macAddr = macAddr + element.toRadixString(16).toUpperCase();
      });
    } catch (e) {
      print(e);
    }
    return toSpaceSeparatedString(macAddr);
  }

  _init() async {
    setState(() {
      commandID = 0x10;
    });
    await characteristic_1212.write(CMD_READ_Battery_Level);
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      isDeviceReady = true;
    });
  }

  _scan() async {
    if (isDeviceConnected) return;

    // print('_scan()');
    try {
      flutterBlue.scan(
        timeout: Duration(seconds: 4), // onDone()
        withServices: [],
      ).listen((scanResult) {
        if (scanResult.device.name == "Jian Jian Bao J21") {
          setState(() {
            _connectDeviceInfo.macAddr = _getMacAddr(scanResult.advertisementData.manufacturerData);
          });
          BluetoothDevice device = scanResult.device;
          if (!devicesList.contains(device)) {
            // print("_addDeviceTolist : $device");
            setState(() {
              devicesList.add(device);
            });
          }
        }
      }).onDone(() async {
        // timeout
        // print("onDone");
        // print(devicesList);
        if (devicesList.length == 0) {
          showAlert("No device founded !");
        } else {
          _targetDevice = devicesList.first;
          try {
            await _targetDevice.connect().timeout(Duration(seconds: 4));
            _targetDevice.state.listen((event) async {
              // print("_targetDevice.state : $event");
              if (event == BluetoothDeviceState.connected) {
                setState(() {
                  isDeviceConnected = true;
                });
                _services = await _targetDevice.discoverServices();
                _services.forEach((service) {
                  if (service.uuid.toString() == "0000180a-0000-1000-8000-00805f9b34fb") {
                    service.characteristics.forEach((characteristic) async {
                      if (characteristic.uuid.toString() == "00002a28-0000-1000-8000-00805f9b34fb") {
                        var tmp = await characteristic.read();
                        String tmp1 = "";
                        tmp.forEach((element) {
                          tmp1 = tmp1 + element.toRadixString(16).toString(); // int to hex
                        });
                        setState(() {
                          _connectDeviceInfo.bleVersion = _hexToString(tmp1);
                        });
                        // print("deviceBV : $deviceBV");
                      }
                    });
                  }
                  if (service.uuid.toString() == "00001810-0000-1000-8000-00805f9b34fb" ||
                      service.uuid.toString() == "00001210-0000-1000-8000-00805f9b34fb") {
                    service.characteristics.forEach((characteristic) {
                      // print("characteristic : ${characteristic.uuid.toString()}");
                      // _openNotify(characteristic);
                      characteristic.setNotifyValue(true);
                      if (characteristic.uuid.toString() == "00001212-0000-1000-8000-00805f9b34fb") {
                        setState(() {
                          characteristic_1212 = characteristic;
                        });
                      }
                      if (characteristic.uuid.toString() == "00001211-0000-1000-8000-00805f9b34fb") {
                        setState(() {
                          characteristic_1211 = characteristic;
                        });
                      }
                      if (characteristic.uuid.toString() == "00002a35-0000-1000-8000-00805f9b34fb") {
                        setState(() {
                          characteristic_2a35 = characteristic;
                        });
                      }
                    });
                  }
                });

                characteristic_1212.value.listen((event) {
                  // print("characteristic_1212.value.listen $event");
                  if (event.isNotEmpty) {
                    if (commandID == 0x10 && event.length == 7) {
                      setState(() {
                        _connectDeviceInfo.batteryLevel = event[3];
                        _connectDeviceInfo.isCharging = event[4].isOdd; // true = 1
                      });
                    }
                  }
                });
                characteristic_1211.value.listen((event) {
                  // print("characteristic_1211.value.listen $event");
                  if (event.isNotEmpty) {
                    if (event[0] == 170) {
                      // start with 0xaa
                      setState(() {
                        measuringText = event[4];
                      });
                    }
                  }
                });
                characteristic_2a35.value.listen((event) async {
                  // print("characteristic_2a35.value.listen $event");
                  if (event.isNotEmpty) {
                    setState(() {
                      displayText = "S: ${event[1]}, D: ${event[3]}, H: ${event[14]}";
                      measuringText = 0;
                    });
                    _uploadMeasurement(event[1], event[3], event[14]);
                    await Future.delayed(Duration(seconds: 2));
                    _targetDevice.disconnect();
                  }
                });
                _init();
              } else {
                // event != BluetoothDeviceState.connected
                setState(() {
                  isDeviceConnected = false;
                  isDeviceReady = false;
                  _connectDeviceInfo = DeviceInfo.init();
                });
                flutterBlue.connectedDevices.asStream().listen((device) {
                  // print("flutterBlue.connectedDevices : $device");
                });
              }
            });
          } catch (e) {
            print(e);
          }
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    // print("MeasurePage init");

    flutterBlue.state.listen((event) {
      print(event);
      if (event == BluetoothState.on) {
        setState(() {
          isBleReady = true;
        });
      } else {
        setState(() {
          isBleReady = false;
        });
      }
    });
    flutterBlue.isScanning.listen((event) {
      // print("isScanning : $event");
      if (event) {
        setState(() {
          isBleScanning = true;
        });
      } else {
        setState(() {
          isBleScanning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "measuring : ${measuringText.toString()}",
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            "$displayText",
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: isBleReady
                ? isBleScanning
                    ? null
                    : isDeviceConnected
                        ? null
                        : () {
                            _scan();
                          }
                : null,
            child: isBleReady
                ? isBleScanning
                    ? Text("Scanning")
                    : Text("Scan & Connect")
                : Text("Please turn on Bluetooth"),
          ),
          ElevatedButton(
            onPressed: isDeviceReady
                ? () {
                    // print("start measurement");
                    setState(() {
                      commandID = 12;
                    });
                    characteristic_1212.write(_cmdStartMeasurement(1));
                  }
                : null,
            child: isDeviceReady ? Text("Start Measurement") : Text("Start Measurement"),
          ),
          ElevatedButton(
            onPressed: isDeviceReady
                ? () {
                    // print("stop measurement");
                    setState(() {
                      commandID = 13;
                      measuringText = 0;
                    });
                    characteristic_1212.write(CMD_STOP_Measurement);
                  }
                : null,
            child: isDeviceReady ? Text("Stop Measurement") : Text("Stop Measurement"),
          ),
          Text("MAC Addr : ${_connectDeviceInfo.macAddr}"),
          Text("Battery Level : ${_connectDeviceInfo.batteryLevel}"),
          Text("Battery Charging : ${_connectDeviceInfo.isCharging.toString()}"),
        ],
      ),
    );
  }

  _uploadMeasurement(int systolic, int diastolic, int heart_beat) async {
    Map body = {
      "systolic_pressure": systolic,
      "diastolic_pressure": diastolic,
      "heart_rhythm": heart_beat,
    };

    var url = Uri.parse(measureApi + "/user/bloodpressures");
    var res = await http.post(url, body: json.encode(body), headers: {
      "Authorization": "Bearer ${widget.token}",
      "Conetent-Type": "application/json",
    });

    // print(res.body);

    // https://stackoverflow.com/questions/61307264/autoclose-dialog-in-flutter
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          _timer = Timer(Duration(seconds: 3), () {
            // Navigator.of(context).pop();
            Navigator.of(context, rootNavigator: true).pop(context);
          });

          return AlertDialog(
            // backgroundColor: Colors.red,
            title: Text('Data Uploaded !'),
            // content: SingleChildScrollView(
            //   child: Text('Content'),
            // ),
          );
        }).then((val) {
      if (_timer.isActive) {
        _timer.cancel();
      }
    });
  }

  List<int> _cmdStartMeasurement(int measureType) {
    List<int> bytes = [0xA5, 0x09, 0x12];
    // List<int> bytes = [0xA5, 0x09,];
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yy-MM-dd-HH-mm').format(now);
    // print(formattedDate);
    // print(formattedDate.split("-")[0]);
    var year = int.parse(formattedDate.split("-")[0], radix: 10).toRadixString(2).padLeft(7, "0");
    var year_high = year.substring(0, 3); // 3
    var year_low = year.substring(3, 7); // 4
    // print('$year_high , $year_low');
    var month = int.parse(formattedDate.split("-")[1], radix: 10).toRadixString(2).padLeft(4, "0");
    // print(month);
    var day = int.parse(formattedDate.split("-")[2], radix: 10).toRadixString(2).padLeft(5, "0");
    // print(day);

    var hour = int.parse(formattedDate.split("-")[3], radix: 10).toRadixString(16).padLeft(2, "0");
    // print(hour);

    var minute = int.parse(formattedDate.split("-")[4], radix: 10).toRadixString(16).padLeft(2, "0");
    // print(minute);

    // print("== : $month/$day $hour:$minute");

    var Byte3 = int.parse(year_low + month, radix: 2);
    var Byte4 = int.parse(year_high + day, radix: 2);
    var Byte5 = int.parse(formattedDate.split("-")[3], radix: 10);
    var Byte6 = int.parse(formattedDate.split("-")[4], radix: 10);
    var Byte7 = measureType; // Measure Type

    bytes.addAll([Byte3, Byte4, Byte5, Byte6, Byte7]);

    // print("bytes 0 : $bytes");

    var checksum = bytes.sublist(1).sum;
    var checksum_bytes = checksum.toRadixString(2).padLeft(16, "0");

    var chechsum_byte0 = int.parse(checksum_bytes.substring(0, 8), radix: 2);
    var chechsum_byte1 = int.parse(checksum_bytes.substring(8, 16), radix: 2);

    bytes.addAll([chechsum_byte0, chechsum_byte1]);

    // print("bytes : $bytes");
    return bytes;
  }

  void showAlert(String message) {
    showPlatformDialog(
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: Text(alert),
        content: Text(message),
        actions: <Widget>[
          PlatformDialogAction(
            child: Text(ok),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(context);
            },
          ),
        ],
      ),
    );
  }

  // https://gist.github.com/saitbnzl/69264ca62e6acea58c8e10becf5bf0e0
  String _hexToString(String hexString) {
    List<String> splitted = [];
    for (int i = 0; i < hexString.length; i = i + 2) {
      splitted.add(hexString.substring(i, i + 2));
    }
    String ascii = List.generate(splitted.length, (i) => String.fromCharCode(int.parse(splitted[i], radix: 16))).join();
    return ascii;
  }

  String toSpaceSeparatedString(String s) {
    var start = 0;
    final strings = <String>[];
    while (start < s.length) {
      final end = start + 2;
      strings.add(s.substring(start, end));
      start = end;
    }
    return strings.join(':');
  }
}

extension on String {
  List<String> splitByLength(int length) => [substring(0, length), substring(length)];
}

class DeviceInfo {
  String uuid;
  String macAddr;
  String name;
  String bleVersion;
  int batteryLevel;
  bool isCharging;
  String lastConnectTime;

  DeviceInfo(
    this.uuid,
    this.macAddr,
    this.name,
    this.bleVersion,
    this.batteryLevel,
    this.isCharging,
    this.lastConnectTime,
  );

  static DeviceInfo init() {
    return DeviceInfo("", "--", "", "", 0, false, "");
  }
}
