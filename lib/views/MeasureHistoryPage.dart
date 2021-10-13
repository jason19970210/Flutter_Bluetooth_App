import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../utils/constants.dart';

class MeasureHistoryPage extends StatefulWidget {
  MeasureHistoryPage({Key? key, required this.token}) : super(key: key);
  final String token;

  @override
  _MeasureHistoryPageState createState() => _MeasureHistoryPageState();
}

class _MeasureHistoryPageState extends State<MeasureHistoryPage> {
  late Future _dataFuture;

  @override
  void initState() {
    super.initState();
    print("MeasureHistoryPage init");

    _dataFuture = _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    print('MeasureHistoryPage is builded');
    _dataFuture = _refreshData();
    // return FutureBuilder(
    //   future: _dataFuture,
    //   builder: (context, AsyncSnapshot async) {
    //     if (async.connectionState == ConnectionState.active || async.connectionState == ConnectionState.waiting) {
    //       return Center(child: Text("Loading"));
    //     }

    //     if (async.connectionState == ConnectionState.done) {
    //       if (async.hasError) {
    //         return Center(child: Text("Error"));
    //       } else if (async.hasData && async.data != null && async.data.length > 0) {
    //         return RefreshIndicator(
    //           onRefresh: _refreshData,
    //           child: ListView.builder(
    //             itemCount: async.data.length,
    //             itemBuilder: (BuildContext context, int index) {
    //               try {
    //                 // print("index : $index");
    //                 return _buildListItem(
    //                   async.data[index]['create_date'].substring(0, 10),
    //                   async.data[index]['create_date'].substring(11, 19),
    //                   async.data[index]["systolic_pressure"].toString(),
    //                   async.data[index]["diastolic_pressure"].toString(),
    //                   async.data[index]["heart_rhythm"].toString(),
    //                   context,
    //                 );
    //               } on RangeError catch (e) {
    //                 print(e);
    //                 return Padding(padding: EdgeInsets.all(40.0), child: Text('data'));
    //               }
    //             },
    //           ),
    //         );
    //       } else {
    //         return Center(child: Text("No Data"));
    //       }
    //     } else {
    //       return Center(child: Text("Error"));
    //     }
    //   },
    // );

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder(
        future: _dataFuture,
        builder: (context, AsyncSnapshot async) {
          if (async.connectionState == ConnectionState.active || async.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (async.connectionState == ConnectionState.done) {
            if (async.hasError) {
              return Center(child: Text("Error"));
            } else if (async.hasData && async.data != null && async.data.length > 0) {
              return ListView.builder(
                itemCount: async.data.length,
                itemBuilder: (BuildContext context, int index) {
                  try {
                    // print("index : $index");
                    return _buildListItem(
                      async.data[index]['create_date'].substring(0, 10),
                      async.data[index]['create_date'].substring(11, 19),
                      async.data[index]["systolic_pressure"].toString(),
                      async.data[index]["diastolic_pressure"].toString(),
                      async.data[index]["heart_rhythm"].toString(),
                      context,
                    );
                  } on RangeError catch (e) {
                    print(e);
                    return Padding(padding: EdgeInsets.all(40.0), child: Text('data'));
                  }
                },
              );
            } else {
              return Center(child: Text("No Data"));
            }
          } else {
            return Center(child: Text("Error"));
          }
        },
      ),
    );
  }

  Widget _buildListItem(String date, String time, String systolicData, String diastolicData, String heartRhythm, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 2.0), child: Column(children: [Text(date), Text(time)])),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.0), child: Text(systolicData, style: TextStyle(fontSize: 18))),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.0), child: Text(diastolicData, style: TextStyle(fontSize: 18))),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.0), child: Text(heartRhythm, style: TextStyle(fontSize: 18))),
          ],
        ),
      ),
    );
  }

  Future _refreshData() async {
    // await Future.delayed(Duration(seconds: 2));
    print("_refreshData()");

    var url = Uri.parse(measureApi + "/user/bloodpressures");
    try {
      var res = await http.get(url, headers: {"Authorization": "Bearer ${widget.token}"});
      if (res.statusCode == 200) {
        return await json.decode(res.body)['data'];
      }
    } on SocketException {
      print("No Network Connection");
    }
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
}

class MeasurementData {
  late final String uuid;
  late final int systolicData;
  late final int diastolicData;
  late final int heartRhythm;
  late final String date;
  late final String time;

  MeasurementData(
    this.uuid,
    this.systolicData,
    this.diastolicData,
    this.heartRhythm,
    this.date,
    this.time,
  );

  factory MeasurementData.fromJson(Map<String, dynamic> parsedJson) {
    return MeasurementData(
      parsedJson['uuid'],
      parsedJson['systolic_pressure'],
      parsedJson['diastolic_pressure'],
      parsedJson['heart_rhythm'],
      parsedJson['create_date'].substring(0, 10),
      parsedJson['create_date'].substring(11, 19),
    );
  }
}
