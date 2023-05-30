import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import '../Customer/restaurantProfile.dart';
import '../customWidgets.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final searchButtonController = TextEditingController();
  final searchFocusNode = FocusNode();
  bool _searchMode = false;
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> searchResults = [];
  var latitude = 0.0;
  var longitude = 0.0;

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

  void _toggleSearchMode() {
    setState(() {
      _searchMode = !_searchMode;
      if (_searchMode) {
        searchFocusNode.requestFocus();
      } else {
        searchFocusNode.unfocus();
        searchButtonController.clear();
        searchResults.clear();
      }
    });
  }

  Stream<List<DocumentSnapshot>> getNearbyRestaurants() {

      final geo = GeoFlutterFire();
      final center = geo.point(latitude: latitude, longitude: longitude);

      final collectionReference = FirebaseFirestore.instance.collection('Restaurants');

      final radius = 50000000.0;
      final field = "position";

      final stream = geo.collection(collectionRef: collectionReference)
          .within(center: center, radius: radius, field: field);
      return stream;
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied, we cannot request permissions.';
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        throw 'Location permissions are denied (actual value: $permission).';
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();
    determinePosition().then((position) {
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    });
  }

  @override
  void dispose() {
    searchButtonController.dispose();
    searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            height: 1.5,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_searchMode)
            textInputField(
              context,
              "Search Restaurant",
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
                    "Search Restaurant",
                    searchButtonController,
                    false,
                    iconData: Icons.arrow_back,
                    onChanged: (String value) {
                      _searchRestaurants(value);
                    },
                    iconOnTap: _toggleSearchMode,
                    focusNode: searchFocusNode,
                  ),
                ),
              ],
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
                                child: CachedNetworkImage(
                                  imageUrl: doc["image_url"],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
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
          if (!_searchMode)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
                      child: Text('Top Rated Restaurants',
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 20)),
                    ),
                    SizedBox(
                      height: 275,
                      child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Restaurants')
                            .orderBy('rating', descending: true)
                            .limit(10)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final restaurants = snapshot.data!.docs;
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: restaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = restaurants[index];
                                final id = restaurant.id;
                                final name = restaurant['name'];
                                final image = restaurant['image_url'];
                                final rating = restaurant['rating'];
                                final fullAddress = restaurant['address'];
                                final followerCount = restaurant['followerCount'];
                                final postCount = restaurant['postCount'];
                                List<String> addressParts =
                                    fullAddress.split(', ');
                                String addressText = addressParts
                                    .sublist(addressParts.length - 2)
                                    .join(', ');
                                return GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantProfile(
                                        restaurantID: id,
                                        restaurantName: name,
                                        restaurantImageUrl: image,
                                        restaurantFollowersCount: followerCount, restaurantPostsCount: postCount, restaurantAddress: fullAddress)));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 160,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6.0),
                                        color: Colors.white,
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Color.fromRGBO(0, 0, 0, 0.12),
                                              offset: Offset(0, 1),
                                              blurRadius: 10)
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              Container(
                                                width: 160.0,
                                                height: 180.0,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    topLeft: Radius.circular(6.0),
                                                    topRight: Radius.circular(6.0),
                                                  ),
                                                  image: DecorationImage(
                                                    fit: BoxFit.cover,
                                                    image: CachedNetworkImageProvider(image),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.55),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(6.0),
                                                      topRight:
                                                          Radius.circular(6.0),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 16.0,
                                                      ),
                                                      const SizedBox(width: 2.0),
                                                      Text(
                                                        rating.toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          fontSize: 14.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 8, 4),
                                            child: Text(
                                              name,
                                              style:
                                                  const TextStyle(fontSize: 20.0),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 0, 8, 8),
                                            child: Text(addressText),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
                      child: Text('Nearby Restaurants',
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 20)),
                    ),
                    SizedBox(
                      height: 275,
                      child: StreamBuilder<List<DocumentSnapshot>>(
                        stream: getNearbyRestaurants(),
                        builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                          if (snapshot.hasData) {
                            final restaurants = snapshot.data!;
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: restaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = restaurants[index];
                                final restaurantData = restaurant.data() as Map<String, dynamic>;
                                final name = restaurantData['name'];
                                final image = restaurantData['image_url'];
                                final rating = restaurantData['rating'];
                                final fullAddress = restaurantData['address'];
                                final followerCount = restaurant['followerCount'];
                                final postCount = restaurant['postCount'];
                                final id = restaurant.id;
                                List<String> addressParts =
                                fullAddress.split(', ');
                                String addressText = addressParts
                                    .sublist(addressParts.length - 2)
                                    .join(', ');
                                return GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantProfile(
                                        restaurantID: id,
                                        restaurantName: name,
                                        restaurantImageUrl: image,
                                        restaurantFollowersCount: followerCount, restaurantPostsCount: postCount, restaurantAddress: fullAddress)));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 160,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6.0),
                                        color: Colors.white,
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Color.fromRGBO(0, 0, 0, 0.12),
                                              offset: Offset(0, 1),
                                              blurRadius: 10)
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              Container(
                                                width: 160.0,
                                                height: 180.0,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(6.0),
                                                    topRight: Radius.circular(6.0),
                                                  ),
                                                  image: DecorationImage(
                                                    fit: BoxFit.cover,
                                                    image: CachedNetworkImageProvider(image),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  padding:
                                                  const EdgeInsets.all(4.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.55),
                                                    borderRadius:
                                                    const BorderRadius.only(
                                                      bottomLeft:
                                                      Radius.circular(6.0),
                                                      topRight:
                                                      Radius.circular(6.0),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 16.0,
                                                      ),
                                                      const SizedBox(width: 2.0),
                                                      Text(
                                                        rating.toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          fontSize: 14.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 8, 4),
                                            child: Text(
                                              name,
                                              style:
                                              const TextStyle(fontSize: 20.0),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 0, 8, 8),
                                            child: Text(addressText),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
