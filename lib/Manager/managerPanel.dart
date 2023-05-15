import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:project_mobile/Manager/stats.dart';
import 'management.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({Key? key}) : super(key: key);

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _selectedIndex = 1;
  final _pageOptions = [
    //bottom bar sekmeleri
    ManagerPanel(),
    Home(userId: FirebaseAuth.instance.currentUser!.uid,),
    Stats(),
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
            icon: Icon(Icons.edit_note),
            label: 'Management',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats),
            label: 'Stats',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
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
      appBar: MyAppBar(),
      body:  Center(
        child:
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('/comments')
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (BuildContext context, int index) {
                final order = snapshot.data!.docs[index];
                DocumentReference item = order.get("itemRef") ;
                final restaurantRef = item.path.split("/")[1];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.doc("Restaurants/$restaurantRef").get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }
                    final restaurantName = snapshot.data!.get('name') as String;
                    final managers = snapshot.data!.get('managers') as List<dynamic>;
                    final currentUserID = LoginPage.userID;

                    if (!managers.contains(currentUserID)) {
                      // if the current user is not a manager of the restaurant, do not show the comment
                      return const SizedBox();
                    }

                    return FutureBuilder<DocumentSnapshot>(
                          future: item.get(),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }
                            if (snapshot.data == null || !snapshot.data!.exists) {
                              return const SizedBox();
                            }
                            final itemName = snapshot.data!.get('name') as String;
                            final timestamp = order["timestamp"];
                            final comment = order["text"];
                            final rating = order["rating"];
                            final dateTime = timestamp.toDate().toLocal();
                            final formattedDate =
                                "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()} ${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}";
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$itemName',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8.0),
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber[700],
                                      ),
                                      SizedBox(width: 4.0),
                                      Text(
                                        '$rating',
                                        style: TextStyle(fontSize: 18.0),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.0),
                                  Text(
                                    '$comment',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                  SizedBox(height: 12.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$formattedDate',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '$restaurantName',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                );
              },
            );
          },
        ),
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
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                  },
                  icon: const Icon(Icons.logout, color: Colors.black),
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
                    'Get your restaurant\'s information here!',
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

