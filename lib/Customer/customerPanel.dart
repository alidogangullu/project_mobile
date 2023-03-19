import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/loginPage.dart';

//todo !!! restorant müşterisi arayüzü detaylandırma !!!, security, location check vb...
//todo uygulama içi qr scanner
//todo uygulama içi menü görüntüleme
//todo eski siparişler ve yorum ekleme
//todo profil ekranı
//todo müşteri uygulaması için webteki gibi sipariş ekranı

class CustomerHome extends StatefulWidget {
  const CustomerHome({Key? key}) : super(key: key);

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 0;
  final _pageOptions = [
    //bottom bar sekmeleri
    Home(userId: FirebaseAuth.instance.currentUser!.uid,),
    Home(userId: FirebaseAuth.instance.currentUser!.uid,),
    Home(userId: FirebaseAuth.instance.currentUser!.uid,)
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
            icon: Icon(Icons.search),
            label: 'Search',
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
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        //todo
        child: Text("test"),
      ),
    );
  }
}