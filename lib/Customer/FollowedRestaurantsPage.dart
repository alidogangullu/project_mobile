import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import '../Customer/restaurantProfile.dart';

class FollowedRestaurantsPage extends StatelessWidget {
  const FollowedRestaurantsPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title:
            const Text('Followed Restaurants', style: TextStyle(color: Colors.black)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(LoginPage.userID).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          List<dynamic> followedRestaurants =
              snapshot.data!['followedRestaurants'];

          if (followedRestaurants.isEmpty) {
            return const Center(
                child: Text('You are not following any restaurants.'));
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(10,10,10,0),
            child: GridView.count(
              crossAxisCount: 1,
              childAspectRatio: 1.075,
              children: followedRestaurants.map<Widget>((restaurantID) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Restaurants')
                      .doc(restaurantID)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData) {
                      return const Text('No data');
                    }

                    var doc = snapshot.data!;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantProfile(
                              restaurantID: doc.id,
                              restaurantName: doc['name'],
                              restaurantImageUrl: doc['image_url'],
                              restaurantFollowersCount: doc['followerCount'],
                              restaurantPostsCount: doc['postCount'],
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
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
