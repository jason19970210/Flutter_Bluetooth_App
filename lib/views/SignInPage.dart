import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../utils/constants.dart';
import 'DashPage.dart';
import 'SignUpPage.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String _userNameEntered = "";
  String _passwordEntered = "";
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getAssetImage(),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person,
                  color: Colors.blueAccent,
                ),
                hintText: "Username",
              ),
              keyboardType: TextInputType.number,
              autocorrect: false,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))],
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  _userNameEntered = value;
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _userNameEntered = value;
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.vpn_key,
                  color: Colors.blueAccent,
                ),
                hintText: "Password",
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isVisible = !_isVisible;
                    });
                  },
                  icon: !_isVisible
                      ? Icon(
                          Icons.visibility,
                          color: Colors.blueAccent,
                        )
                      : Icon(
                          Icons.visibility_off,
                          color: Colors.blueAccent,
                        ),
                ),
              ),
              keyboardType: TextInputType.text,
              autocorrect: false,
              obscureText: !_isVisible,
              textInputAction: TextInputAction.send,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))],
              onChanged: (value) {
                setState(() {
                  _passwordEntered = value;
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _passwordEntered = value;
                });
                _login(_userNameEntered, _passwordEntered);
              },
            ),
          ),

          // Sign In Btn
          Padding(
            padding: const EdgeInsets.only(top: padding_10, right: padding_20, left: padding_20),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 5.0)],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 1.0],
                  colors: [
                    Color(0xff6bceff),
                    Color(0xFF00abff),
                  ],
                ),
                color: Colors.deepPurple.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  minimumSize: MaterialStateProperty.all(Size(200, 50)),
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  // elevation: MaterialStateProperty.all(3),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                onPressed: () {
                  // print("Sign In Btn username : $_userNameEntered, password : $_passwordEntered");
                  _disableKeyboard();
                  _login(_userNameEntered, _passwordEntered);
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                  ),
                  child: Text(
                    signin,
                    style: TextStyle(
                      fontSize: 18,
                      // fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sign Up Text & Btn
          Padding(
            padding: const EdgeInsets.only(top: 0, right: padding_20, left: padding_20),
            child: Center(
              child: Row(
                // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account ?"),
                  const SizedBox(height: 100),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF00abff),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                      );
                    },
                    child: Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Functions
  Widget getAssetImage() {
    AssetImage assetImage = AssetImage('images/flutter.png');
    Image image = Image(image: assetImage, width: 125.0, height: 125.0);
    return Container(padding: EdgeInsets.only(top: padding_20, bottom: padding_20), child: image, alignment: Alignment.center);
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

  _disableKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefToken, token);
    print("_saveToken");
  }

  _login(String username, String password) async {
    // TextInput Empty Validation
    // print("_login  username : $username, password : $password");
    if (username.isEmpty || password.isEmpty) {
      showAlert("Something missing");
    } else {
      // send http GET
      Map body = {
        "username": username,
        "password": password,
        "method": "password",
        "expired": false,
      };

      var url = Uri.parse(commonauthApi + "/user/tokens");
      var res = await http.post(url, body: json.encode(body));

      var token = json.decode(res.body)['data']['token'].toString();

      if (token.isEmpty) {
        // bad token
        showAlert("Login Failed");
      } else {
        // Login Successful
        print("_login : $token");
        _saveToken(token);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DashPage(
                    token: token,
                  )),
        );
      }
    }
  }
}
