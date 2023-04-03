import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/completedOrders.dart';
import 'package:project_mobile/Customer/profile.dart';
import 'package:project_mobile/Customer/qrScanner.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';

//todo security, location check vb...

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
    CompletedOrdersScreen(customerId: FirebaseAuth.instance.currentUser!.uid)
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //Navigator.push(context, MaterialPageRoute(builder: (context) => QRScanner()));
          //kolaylık açısından direkt yönlendirme
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MenuScreen(id: "w2I2nZ1laB7xN0HF7m2R", tableNo: "1")));
        },
        child: const Icon(Icons.qr_code_scanner),

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
            icon: Icon(Icons.view_list),
            label: 'Completed Orders',
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
  const Home({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Name"),
        actions: [
          IconButton(
            onPressed: () async {
              //todo search for restaurant, another user etc
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: const Center(
        //todo
        child: Text("Customer Screen Test"),
      ),
    );
  }
}