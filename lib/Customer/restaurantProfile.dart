import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../customWidgets.dart';


class RestaurantProfile extends StatefulWidget {
  const RestaurantProfile({
    Key? key,
    required this.restaurantID,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.restaurantFollowersCount,
    required this.restaurantPostsCount,
    required this.restaurantAddress,
  }) : super(key: key);

  final String restaurantID;
  final String restaurantName;
  final String restaurantImageUrl;
  final String restaurantAddress;
  final int restaurantFollowersCount;
  final int restaurantPostsCount;

  @override
  RestaurantProfileState createState() => RestaurantProfileState();
}

class RestaurantProfileState extends State<RestaurantProfile> {
  bool isFollowing = false;

  var latitude;
  var longitude;

  @override
  void initState() {
    super.initState();
    checkFollowingStatus();
  }

  Future<void> getLatLong() async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection("Restaurants")
        .doc(widget.restaurantID)
        .get();
    if (documentSnapshot.exists) {
    Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;

    if (data['position'] != null) {
      Map<String, dynamic> positionMap = data['position'];

      if (positionMap['geopoint'] != null) {
        // Get the GeoPoint
        GeoPoint geoPoint = positionMap['geopoint'];
        // Print it out or do anything you want with it
        latitude = geoPoint.latitude;
        longitude = geoPoint.longitude;
      }
    }
  }
  }

  void checkFollowingStatus() async {
    String userID = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userID).get();

    if (snapshot.exists) {
      List<dynamic>? followedRestaurants = snapshot['followedRestaurants'] as List<dynamic>?;
      setState(() {
        isFollowing = followedRestaurants != null && followedRestaurants.contains(widget.restaurantID);
      });
    }
  }

  Future<void> followRestaurant() async {
    try {
      String userID = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(userID).update({
        'followedRestaurants': FieldValue.arrayUnion([widget.restaurantID])
      });

      await FirebaseFirestore.instance.doc('Restaurants/${widget.restaurantID}').update({
        'followerCount': FieldValue.increment(1),
      });

      setState(() {
        isFollowing = true;
      });
    } catch (error) {
      print('Error following restaurant: $error');
    }
    ScaffoldMessenger.of(context).showSnackBar(
        customSnackBar('The Restaurant followed successfully')
    );
  }

  Future<void> unfollowRestaurant() async {
    try {
      String userID = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(userID).update({
        'followedRestaurants': FieldValue.arrayRemove([widget.restaurantID])
      });

      await FirebaseFirestore.instance.doc('Restaurants/${widget.restaurantID}').update({
        'followerCount': FieldValue.increment(-1),
      });

      print('Restaurant unfollowed successfully!');

      setState(() {
        isFollowing = false;
      });
    } catch (error) {
      print('Error unfollowing restaurant: $error');
    }
    ScaffoldMessenger.of(context).showSnackBar(
        customSnackBar('You have unfollowed the restaurant.')
    );
  }

  void launchMap(double latitude, double longitude) async {
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not launch $googleUrl';
    }
  }

  void _showMapAlert(BuildContext context, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Open in Map'),
          content: Text('Do you want to open map for this address: $address?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                getLatLong();
                launchMap(latitude, longitude);
                Navigator.of(context).pop();
              },
              child: const Text('Open in Map'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.restaurantName,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 50,
                  backgroundImage: CachedNetworkImageProvider(widget.restaurantImageUrl),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          buildStatColumn('Posts', widget.restaurantPostsCount),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('Restaurants').doc(widget.restaurantID).snapshots(),
                            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (!snapshot.hasData) {
                                return buildStatColumn('Followers', 0);
                              } else {
                                return buildStatColumn('Followers', snapshot.data!['followerCount']);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TextButton(child: Text(widget.restaurantAddress), onPressed:() {
            //not work on emulator but work on real devices
            _showMapAlert(context, widget.restaurantAddress);
          },),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  isFollowing ? unfollowRestaurant() : followRestaurant();
                },
                child: Text(
                  isFollowing ? 'Unfollow Restaurant' : 'Follow Restaurant',
                ),

              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuBrowseScreen(id: widget.restaurantID),
                    ),
                  );
                },
                child: const Text('Restaurant Menu'),
              ),
            ],
          ),
          const SizedBox(height: 15,),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Restaurants/${widget.restaurantID}/Posts').orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostsScreen(
                              posts: snapshot.data!.docs,
                              initialPostIndex: index,
                              restaurantID: widget.restaurantID,
                              restaurantName: widget.restaurantName,
                              restaurantImageUrl: widget.restaurantImageUrl,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: CachedNetworkImageProvider(snapshot.data!.docs[index]['imageUrl']),
                          ),
                        ),
                      ),

                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Column buildStatColumn(String label, int number) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}


class PostsScreen extends StatelessWidget {
  final List<DocumentSnapshot> posts;
  final int initialPostIndex;
  final String restaurantID;
  final String restaurantName;
  final String restaurantImageUrl;
  const PostsScreen({
    Key? key,
    required this.posts,
    required this.initialPostIndex,
    required this.restaurantID,
    required this.restaurantName,
    required this.restaurantImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(
      initialPage: initialPostIndex,

    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Posts",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: posts.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          DocumentSnapshot post = posts[index];

          DateTime timestamp = (post['timestamp'] as Timestamp).toDate();
          String formattedDate = DateFormat('yyyy-MM-dd').format(timestamp);
          String formattedTime = DateFormat('HH:mm:ss').format(timestamp);

          return InkWell(
            onTap: () {
              pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
            child: RestaurantPostsWidget(
              restaurantImageUrl: restaurantImageUrl,
              restaurantName: restaurantName,
              post: post,
              formattedDate: formattedDate,
              formattedTime: formattedTime,
            ),
          );
        },
      ),
    );
  }
}

class RestaurantPostsWidget extends StatelessWidget {
  const RestaurantPostsWidget({
    super.key,
    required this.restaurantImageUrl,
    required this.restaurantName,
    required this.post,
    required this.formattedDate,
    required this.formattedTime,
  });

  final String restaurantImageUrl;
  final String restaurantName;
  final DocumentSnapshot<Object?> post;
  final String formattedDate;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            leading: InkWell(
              onTap: () => Navigator.pop(context),
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(restaurantImageUrl),
                radius: 25,
              ),
            ),
            title: InkWell(
              onTap: () => Navigator.pop(context),
              child: Text(
                restaurantName,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          Expanded(
            child: CachedNetworkImage(
              imageUrl: post['imageUrl'],
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                post['caption'],
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}