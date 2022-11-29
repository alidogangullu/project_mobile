import 'package:flutter/material.dart';
import 'package:project_mobile/Admin/menuEditorPage.dart';
import 'package:project_mobile/Authentication/loginPage.dart';

class AdminHome extends StatefulWidget {
  AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {

  int _selectedIndex = 1;
  final _pageOptions = [
    const MenuEditor(),
    Home(userId: LoginPage.userID,)
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

class Home extends StatelessWidget {
  Home({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Name"),
      ),
      body: Center(child: Text(userId),),
    );
  }
}