import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/recentOrders.dart';
import 'package:project_mobile/Customer/profile.dart';
import 'package:project_mobile/Customer/qrScanner.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';
import 'package:project_mobile/Customer/restaurantProfile.dart';
import 'package:project_mobile/customWidgets.dart';
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

class Home extends StatefulWidget {
  const Home({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final searchButtonController = TextEditingController();
  final searchFocusNode = FocusNode();
  bool _searchMode = false;
  List<DocumentSnapshot> searchResults = [];

  @override
  void dispose() {
    searchButtonController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _searchMode = !_searchMode;
      if (_searchMode) {
        searchFocusNode
            .requestFocus();
      } else {
        searchFocusNode.unfocus();
        searchButtonController.clear();
        searchResults.clear();
      }
    });
  }

  Future<void> _searchRestaurants(String searchText) async {
    if (searchText.length >= 3) {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Restaurants')
          .where("name", isGreaterThanOrEqualTo: searchText.toUpperCase())
          .where("name",
              isLessThanOrEqualTo: "${searchText.toLowerCase()}\uf8ff")
          .get();
      setState(() {
        searchResults = querySnapshot.docs;
      });
    } else {
      setState(() {
        searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MenuScreen(
                id: "GixzDeIROMDRAn2mAnMG",
                tableNo: "1",
              ),
            ),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      appBar: const MyAppBar(),
      body: Column(
        children: [
          if (!_searchMode)
            textInputField(
              context,
              "Search restaurant",
              searchButtonController,
              false,
              iconData: Icons.search,
              onTap: _toggleSearchMode,
            ),
          if (_searchMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: textInputField(
                    context,
                    "Search restaurant",
                    searchButtonController,
                    false,
                    iconData: Icons.arrow_back,
                    onChanged: (String value) {
                      _searchRestaurants(value);
                    },
                    iconOnTap: _toggleSearchMode,
                    focusNode: searchFocusNode, // Pass the searchFocusNode
                  ),
                ),
              ],
            ),
          if (!_searchMode)
            Expanded(
              child: Text("this is timeline"),
            ),
          if (_searchMode)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.count(
                  crossAxisCount: 1,
                  childAspectRatio: 1.075,
                  children: searchResults.map((doc) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantProfile(
                              restaurantID: doc.id,
                              restaurantName: doc['name'],
                              restaurantFollowersCount: doc['followerCount'],
                              restaurantPostsCount: doc['postCount'],
                              restaurantImageUrl: doc['image_url'],
                              restaurantAddress: doc['address'],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 2,
                                child: Image.network(
                                  doc["image_url"],
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Text(
                                  doc["name"],
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 0, 15, 15),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doc["rating"].toString(),
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 0, 15, 15),
                                child: Text(
                                  doc['address'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
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
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(LoginPage.userID)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return AppBar(
              title: const Text('Error', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0,
            );
          } else {
            final managerName = snapshot.data!.get('name');
            return AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
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
          return AppBar(
            title: const Text(
              'Loading...',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          );
        }
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height * 1.1);
}
