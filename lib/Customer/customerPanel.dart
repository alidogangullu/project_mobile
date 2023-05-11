import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/recentOrders.dart';
import 'package:project_mobile/Customer/profile.dart';
import 'package:project_mobile/Customer/qrScanner.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';
import '../Authentication/loginPage.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({Key? key}) : super(key: key);

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 1;

  final _pageOptions = [
    //bottom bar sekmeleri
    Profile(userId: FirebaseAuth.instance.currentUser!.uid),
    Home(userId: FirebaseAuth.instance.currentUser!.uid),
    RecentOrdersScreen(customerId: FirebaseAuth.instance.currentUser!.uid)
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.redo),
            label: 'Recent',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScanner()));

          //kolaylık açısından direkt yönlendirme
          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const MenuScreen(id: "GixzDeIROMDRAn2mAnMG", tableNo: "1"),),);
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      appBar: const MyAppBar(),
      body: const Center(
        //todo
        child: Text("Customer Screen Test"),
      ),
    );
  }
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const MyAppBar({
    Key? key,
    this.height = kToolbarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(LoginPage.userID).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return AppBar(title: const Text('Error', style: TextStyle(color: Colors.black)),backgroundColor: Colors.white,elevation: 0,);
          } else {
            final managerName = snapshot.data!.get('name');
            return AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: () async {
                    //todo search for restaurant, another user etc
                  },
                  icon: const Icon(Icons.search),
                ),
              ],
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hi, $managerName',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Get your favourite food here!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }
        } else {
          return AppBar(title: const Text('Loading...', style: TextStyle(color: Colors.black),),backgroundColor: Colors.white,elevation: 0,);
        }
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height * 1.1);
}