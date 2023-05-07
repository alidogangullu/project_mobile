import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/completedOrders.dart';
import 'package:project_mobile/Customer/profile.dart';
import 'package:project_mobile/Customer/qrScanner.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({Key? key}) : super(key: key);

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  //Yer Tespiti
  Location _location = Location();
  bool _locationEnabled = false;
  LocationData? _locationData;

  double _maxDistanceMeters =
      1000000.0; // Metre cinsinden, sonra 60-70 metreye düşürülür

  double _desiredLatitude =
      38.39607; // Narlıdere Belediyesi latitude sonradan firebase ile çekilmesi gerek
  double _desiredLongitude =
      26.9964453; // Narlıdere Belediyesi longitude sonradan firebase ile çekilmesi gerek

  @override
  void initState() {
    super.initState();
    _checkLocationEnabled();
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<void> _checkLocationEnabled() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
    _locationEnabled = true;
    _location.onLocationChanged.listen((LocationData? locationData) {
      if (mounted) {
        setState(() {
          _locationData = locationData;
        });
      }
    });
  }

  bool _isDesiredLocation() {
    if (!_locationEnabled || _locationData == null) {
      return false;
    }
    double distanceInMeters = Geolocator.distanceBetween(
      _desiredLatitude,
      _desiredLongitude,
      _locationData!.latitude!,
      _locationData!.longitude!,
    );
    return distanceInMeters <= _maxDistanceMeters;
  }

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
          if (_isDesiredLocation()) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MenuScreen(
                        id: "vAkYpJA6Pd6UTEPDysvj", tableNo: "1")));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You have to be at the restaurant to access the menu!")
              )
            );
          }
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
