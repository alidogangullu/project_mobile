import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:project_mobile/Customer/qrScanner.dart';
import 'package:project_mobile/Customer/recentOrders.dart';
import 'package:project_mobile/Customer/profile.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';
import 'package:project_mobile/Customer/restaurantProfile.dart';
import 'package:project_mobile/customWidgets.dart';
import '../Authentication/loginPage.dart';
import 'FollowedRestaurantsPage.dart';
import 'package:intl/intl.dart';


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
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final searchButtonController = TextEditingController();
  final searchFocusNode = FocusNode();
  bool _searchMode = false;
  List<DocumentSnapshot> searchResults = [];

  final ScrollController _scrollController = ScrollController();
  bool _showSearchAndQR = true;

  Future<List<Map<String, dynamic>>>? _postsFuture;


  @override
  void initState() {
    super.initState();

    _postsFuture = fetchFollowedRestaurantPosts(LoginPage.userID);

    // Add a listener to the scroll controller
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showSearchAndQR == true) {
          setState(() {
            _showSearchAndQR = false;
          });
        }
      } else {
        if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward) {
          if (_showSearchAndQR == false) {
            setState(() {
              _showSearchAndQR = true;
            });
          }
        }
      }
    });
  }


  @override
  void dispose() {
    searchButtonController.dispose();
    searchFocusNode.dispose();
    _scrollController.dispose(); // Dispose the controller
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
          .where("name", isLessThanOrEqualTo: "${searchText.toLowerCase()}\uf8ff")
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
  Future<List<String>> getFollowedRestaurantIds(String userId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    List<dynamic> followedRestaurants = snapshot['followedRestaurants'];
    return followedRestaurants.cast<String>();
  }
  Future<List<Map<String, dynamic>>> fetchFollowedRestaurantPosts(String userId) async {
    List<String> followedRestaurantIds = await getFollowedRestaurantIds(userId);

    List<Map<String, dynamic>> posts = [];

    for (String restaurantId in followedRestaurantIds) {
      DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .get();

      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .collection('Posts')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> restaurantPosts = postsSnapshot.docs.map((doc) {
        Map<String, dynamic> postData = (doc.data() as Map<String, dynamic>);
        postData['restaurantImageUrl'] = restaurantSnapshot['image_url'];
        postData['restaurantName'] = restaurantSnapshot['name'];
        postData['restaurantFollowersCount'] = restaurantSnapshot['followerCount'];
        postData['restaurantPostsCount'] = restaurantSnapshot['postCount'];
        postData['restaurantAddress'] = restaurantSnapshot['address'];
        postData['restaurantID'] = restaurantSnapshot.id;
        return postData;
      }).toList();

      posts.addAll(restaurantPosts);
    }

    posts.sort((a, b) => b['timestamp'].compareTo(a['timestamp'])); // Sort posts by timestamp

    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showSearchAndQR // Conditionally render the floating action button
          ? FloatingActionButton(
        onPressed: () {
          //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const QRScanner()));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MenuScreen(id: "GixzDeIROMDRAn2mAnMG", tableNo: "1")));
        },
        child: const Icon(Icons.qr_code_scanner),
      ) : null,
      appBar: const MyAppBar(),
      body: Column(
        children: [
          if (_showSearchAndQR &&!_searchMode)
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
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (!snapshot.hasData ) {
                    return const Text('No posts found');
                  } else {
                    List<Map<String, dynamic>>? posts = snapshot.data;

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: posts?.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> post = posts![index];
                        String imageUrl = post['imageUrl'];
                        String caption = post['caption'];
                        String restaurantImageUrl = post['restaurantImageUrl'];
                        String restaurantName = post['restaurantName'];
                        int restaurantFollowersCount = post['restaurantFollowersCount'];
                        int restaurantPostsCount = post['restaurantPostsCount'];
                        String restaurantAddress = post['restaurantAddress'];
                        String restaurantID = post['restaurantID'];
                        Timestamp timestamp = post['timestamp'];
                        String formattedDate = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                        String formattedTime = DateFormat('HH:mm:ss').format(timestamp.toDate());

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align all elements to the start, i.e., left.
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RestaurantProfile(
                                            restaurantID: restaurantID,
                                            restaurantName: restaurantName,
                                            restaurantImageUrl: restaurantImageUrl,
                                            restaurantFollowersCount: restaurantFollowersCount,
                                            restaurantPostsCount: restaurantPostsCount,
                                            restaurantAddress: restaurantAddress),
                                      ),
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius:20,
                                    backgroundImage: NetworkImage(restaurantImageUrl),
                                  ),
                                ),

                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const FollowedRestaurantsPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    restaurantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Image.network(
                              imageUrl,
                              width: MediaQuery.of(context).size.width,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 15),
                              child: Text(
                                caption,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
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
                                  fit: BoxFit.cover,
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
