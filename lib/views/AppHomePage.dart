import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'DashPage.dart';
import 'SignInPage.dart';
import '../utils/constants.dart';

class AppHomePage extends StatefulWidget {
  @override
  _AppHomePageState createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {
  String token = "";

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = (prefs.getString(prefToken) ?? "");
    });
    print("AppHomePage Token load : $token");
  }

  @override
  Widget build(BuildContext context) {
    if (token.isEmpty) {
      // empty token
      return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Material(
          child: SignInPage(),
        ),
      );
    } else {
      // token exist
      return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Material(
          child: DashPage(
            token: token,
          ),
        ),
      );
    }
  }
}
