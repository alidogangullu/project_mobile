import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';


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


  @override
  void initState() {
    super.initState();
    checkFollowingStatus();
  }

  void checkFollowingStatus() async {
    String userID = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userID).get();

    if (snapshot.exists) {
      List<dynamic>? followedRestaurants = snapshot?['followedRestaurants'] as List<dynamic>?;
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

      print('Restaurant followed successfully!');

      setState(() {
        isFollowing = true;
      });
    } catch (error) {
      print('Error following restaurant: $error');
    }
    const snackBar = SnackBar(
      content: Text('The Restaurant followed successfully'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
    const snackBar = SnackBar(
      content: Text('You have unfollowed the restaurant.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void launchMap(String address) async {
    Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
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
                launchMap(address);
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
                  backgroundImage: NetworkImage(widget.restaurantImageUrl),
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
                            ),
                          ),
                        );
                      },
                      child:Padding(
                        padding: const EdgeInsets.only(left: 5.0), // adjust the padding as needed
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(snapshot.data!.docs[index]['imageUrl']),
                              ),
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
  const PostsScreen({
    Key? key,
    required this.posts,
    required this.initialPostIndex,
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
          String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(post['imageUrl']),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    post['caption'],
                    style: const TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedTimestamp,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}