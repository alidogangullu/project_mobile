import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';

class RestaurantProfile extends StatelessWidget {
  const RestaurantProfile({
    Key? key,
    required this.restaurantID,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.restaurantFollowersCount,
    required this.restaurantPostsCount,
  }) : super(key: key);

  final String restaurantID;
  final String restaurantName;
  final String restaurantImageUrl;
  final int restaurantFollowersCount;
  final int restaurantPostsCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(restaurantImageUrl),
                ),
                const SizedBox(width: 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {},
                child: const Text('Follow Restaurant'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuBrowseScreen(id: restaurantID),
                    ),
                  );
                },
                child: const Text('Restaurant Menu'),
              ),
            ],
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              children: <Widget>[
                Image.network('https://link-to-your-image.jpg'),
                // Add more images
              ],
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
