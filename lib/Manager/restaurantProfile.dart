import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Manager/newPost.dart';
import 'package:project_mobile/Manager/qrGenerator.dart';
import 'package:project_mobile/Manager/restaurantManagers.dart';
import 'package:simple_speed_dial/simple_speed_dial.dart';
import 'package:intl/intl.dart';
import 'desktopApplicationConnection.dart';
import 'manageRestaurant.dart';


class RestaurantProfile extends StatelessWidget {
  const RestaurantProfile({
    Key? key,
    required this.restaurantID,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.restaurantFollowersCount,
    required this.restaurantPostsCount,
    required this.restaurantAddress
  }) : super(key: key);

  final String restaurantID;
  final String restaurantName;
  final String restaurantImageUrl;
  final String restaurantAddress;
  final int restaurantFollowersCount;
  final int restaurantPostsCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SpeedDial(
        openBackgroundColor: Colors.black,
        speedDialChildren: [
          SpeedDialChild(

            child: const Icon(Icons.manage_accounts),
            label: 'Edit Restaurant Managers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRestaurantManagers(
                    restaurantId: restaurantID,
                  ),
                ),
              );
            },
            closeSpeedDialOnPressed: true,
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code_2),
            label: 'Create QR Codes for Tables',
            onPressed: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRHomePage(
                    selectedRestaurantID: restaurantID,
                  ),
                ),
              );
            },
            closeSpeedDialOnPressed: true,
          ),
          SpeedDialChild(
            child: const Icon(Icons.desktop_windows_outlined),
            label: 'Edit Waiters Access',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DesktopAppConnect(
                    restaurantId: restaurantID,
                  ),
                ),
              );
            },
            closeSpeedDialOnPressed: true,
          ),

        ],
        child: const Icon(Icons.settings),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          restaurantName,
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
                  backgroundImage: CachedNetworkImageProvider(restaurantImageUrl),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          buildStatColumn('Posts', restaurantPostsCount),
                          buildStatColumn(
                              'Followers', restaurantFollowersCount),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Text(
              restaurantAddress,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
          const SizedBox(height: 15,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateNewPost(
                        restaurantID: restaurantID,
                      ),
                    ),
                  );
                },
                child: const Text('Share New Post'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context

                          ) => EditRestaurantMenu(
                        collection: "Restaurants/$restaurantID/MenuCategory",
                        restaurantName: restaurantName,
                        restaurantID: restaurantID,
                      ),
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
                  .collection('Restaurants/$restaurantID/Posts').orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(5),
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
                              restaurantID: restaurantID,
                              posts: snapshot.data!.docs,
                              initialPostIndex: index,
                              restaurantImageUrl: restaurantImageUrl,
                              restaurantName: restaurantName,
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
  final String restaurantImageUrl;
  final String restaurantName;

  const PostsScreen({
    Key? key,
    required this.posts,
    required this.initialPostIndex,
    required this.restaurantID,
    required this.restaurantImageUrl,
    required this.restaurantName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(
      initialPage: initialPostIndex,
    );

    Future<void> deletePost(String postId) async {
      await FirebaseFirestore.instance
          .collection('Restaurants/$restaurantID/Posts')
          .doc(postId)
          .delete();

      await FirebaseFirestore.instance.doc('Restaurants/$restaurantID').update({
        'postCount': FieldValue.increment(-1),
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Posts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: posts.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          DocumentSnapshot post = posts[index];

          DateTime timestamp = (post['timestamp'] as Timestamp).toDate();
          String formattedTimestamp = DateFormat('yyyy-MM-dd').format(timestamp);
          String formattedTime = DateFormat('HH:mm:ss').format(timestamp);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(restaurantImageUrl),
                    radius: 23,
                  ),
                  title: Text(
                    restaurantName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: CachedNetworkImage(
                  imageUrl: post['imageUrl'],
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    post['caption'],
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
                child: Row(
                  children: [
                    Text(
                      formattedTimestamp,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 25,
                    onPressed: () {
                      deletePost(post.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}








