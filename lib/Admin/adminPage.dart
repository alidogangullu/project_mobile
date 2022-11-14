import 'package:flutter/material.dart';
import 'package:project_mobile/Admin/menu_editorPage.dart';

class AdminHome extends StatefulWidget {
  AdminHome({Key? key}) : super(key: key);
  static String uid = '';

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 1;
  final _pageOptions = [
    MenuEdit(),
    Home(AdminHome.uid),
    //ActionsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _pageOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Restaurant Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: 'Another Tab',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,

      ),
    );
  }
}

class MenuEdit extends StatefulWidget {
  const MenuEdit({Key? key}) : super(key: key);

  @override
  State<MenuEdit> createState() => _MenuEditState();
}

class _MenuEditState extends State<MenuEdit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EditMenu()
    );
  }
}

class Home extends StatefulWidget {
  Home(this.uid);
  String uid;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Name"),
      ),
      body: Center(child: Text(widget.uid),),
    );
  }
}

