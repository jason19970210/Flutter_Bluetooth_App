import 'package:flutter/material.dart';

import 'MeasurePage.dart';
import 'MeasureHistoryPage.dart';
import 'SportHistoryPage.dart';
import 'UserPage.dart';

class DashPage extends StatefulWidget {
  DashPage({Key? key, required this.token}) : super(key: key);
  final String token;

  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      MeasurePage(token: widget.token),
      MeasureHistoryPage(token: widget.token),
      SportHistoryPage(token: widget.token),
      UserPage(token: widget.token),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("全家寶")),
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // https://stackoverflow.com/questions/53758698/flutter-dart-customize-bottom-navigation-bar-height
      bottomNavigationBar: SizedBox(
        height: 70,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.workspaces_filled),
              title: Text("測量"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              title: Text("歷史"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              title: Text("歷史"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              title: Text("User"),
            ),
          ],
        ),
      ),
    );
  }
}
