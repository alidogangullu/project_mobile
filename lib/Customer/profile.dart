import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../Authentication/loginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  File? _image;
  final _picker = ImagePicker();
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _getProfilePhoto(widget.userId);
  }

  Future<void> _getProfilePhoto(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userSnapshot = await userRef.get();
    final profileImageUrl = userSnapshot.data()?['profileImageUrl'];
    if (profileImageUrl != null) {
      setState(() {
        _profilePhotoUrl = profileImageUrl;
      });
    } else {
      setState(() {
        _profilePhotoUrl =
            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
      });
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      final downloadURL = await _uploadImage(_image!);
      await _updateProfileImageUrl(downloadURL);
    }
  }

  Future<String> _uploadImage(File image) async {
    final storageReference = FirebaseStorage.instance
        .ref()
        .child('profileImageUrl/${widget.userId}');
    final uploadTask = storageReference.putFile(image);
    final downloadURL = await (await uploadTask).ref.getDownloadURL();
    return downloadURL;
  }

  Future<void> _updateProfileImageUrl(String profileImageUrl) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);
    await userRef.update({'profileImageUrl': profileImageUrl});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            height: 1.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: _image != null
                      ? Image.file(
                          _image!,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                        )
                      : _profilePhotoUrl != null
                          ? Image.network(
                              _profilePhotoUrl!,
                              width: 75,
                              height: 75,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(),
                ),
                const SizedBox(
                  width: 15,
                ),
                const Expanded(
                  child: ProfileDetails(),
                ),
                IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text(
                                'Take a photo',
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _getImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text(
                                'Select from gallery',
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _getImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit)),
                const Text('Edit'),
                const SizedBox(
                  width: 15,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 30, 0, 20),
              child: Text(
                "Account",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //column icinde ProfilePageButton kullan.
                const ProfilePageButton(
                  text: 'Help',
                  icon: Icon(Icons.help),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CommentsPage()),
                    );
                  },
                  child: const ProfilePageButton(
                    icon: Icon(Icons.rate_review),
                    text: 'Comments',
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {},
                  child: const ProfilePageButton(
                    text: 'Notifications',
                    icon: Icon(Icons.notifications),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                    },
                    child: const ProfilePageButton(
                        text: 'Logout', icon: Icon(Icons.logout))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({Key? key}) : super(key: key);

  @override
  CommentsPageState createState() => CommentsPageState();
}

class CommentsPageState extends State<CommentsPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String? _selectedRestaurantId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Comments',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            height: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('comments')
                  .where('userId', isEqualTo: userId)
                  .get(),
              builder: (context, commentSnapshot) {
                if (!commentSnapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final restaurantIds = commentSnapshot.data!.docs
                    .map((comment) =>
                        comment.get('itemRef').toString().split('/')[1])
                    .toSet()
                    .toList();
                return FutureBuilder<List<DocumentSnapshot>>(
                  future: Future.wait(
                    restaurantIds.map((restaurantId) => FirebaseFirestore
                        .instance
                        .collection('Restaurants')
                        .doc(restaurantId)
                        .get()),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final restaurants = snapshot.data!;

                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select a restaurant',
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 0.0),
                        ),
                        labelStyle: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      value: _selectedRestaurantId,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRestaurantId = newValue;
                        });
                      },
                      items: restaurants.map((restaurant) {
                        final restaurantName = restaurant.get('name') as String;
                        final restaurantId = restaurant.id;

                        return DropdownMenuItem<String>(
                          value: restaurantId,
                          child: Text(restaurantName),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('/comments')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final List<DocumentSnapshot> documents = snapshot.data!.docs;
                final List<DocumentSnapshot> filteredDocuments = documents
                    .where((doc) =>
                        doc.get('userId') == userId &&
                        doc.get('itemRef').toString().split('/')[1] ==
                            _selectedRestaurantId)
                    .toList();
                return ListView.builder(
                  itemCount: filteredDocuments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final commentDoc = filteredDocuments[index];
                    DocumentReference itemRef = commentDoc.get("itemRef");
                    final restaurantID = itemRef.path.split("/")[1];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .doc("Restaurants/$restaurantID")
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }
                        final restaurantName =
                            snapshot.data!.get('name') as String;

                        return FutureBuilder<DocumentSnapshot>(
                          future: itemRef.get(),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }
                            final itemName =
                                snapshot.data!.get('name') as String;
                            final timestamp = commentDoc["timestamp"];
                            final comment = commentDoc["text"];
                            final rating = commentDoc["rating"];
                            final dateTime = timestamp.toDate().toLocal();
                            final formattedDate =
                                "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()} ${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}";
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          showDialog<void>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              //this codes (inside of the alert dialog) pasted here from recentOrders.dart and modified
                                              Future<void>
                                                  updateItemRatingAndCount(
                                                      DocumentReference itemRef,
                                                      double newRating) async {
                                                final itemSnapshot =
                                                    await itemRef.get();
                                                double currentAvgRating =
                                                    double.parse(itemSnapshot[
                                                                'rating']
                                                            .toString()) ??
                                                        0.0;
                                                int currentRatingCount =
                                                    itemSnapshot[
                                                            'ratingCount'] ??
                                                        0;

                                                // Check if the user has previously rated
                                                final previousFeedbackSnapshot =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('comments')
                                                        .where('userId',
                                                            isEqualTo: LoginPage
                                                                .userID)
                                                        .where('itemRef',
                                                            isEqualTo: itemRef)
                                                        .limit(1)
                                                        .get();
                                                bool hasPreviouslyRated =
                                                    previousFeedbackSnapshot
                                                            .size >
                                                        0;

                                                if (hasPreviouslyRated) {
                                                  // User has previously rated, update the average rating
                                                  final previousFeedback =
                                                      previousFeedbackSnapshot
                                                          .docs[0];
                                                  double userOldRating =
                                                      previousFeedback
                                                          .get('rating')
                                                          .toDouble();
                                                  double updatedAvgRating =
                                                      (currentAvgRating *
                                                              currentRatingCount) -
                                                          userOldRating +
                                                          newRating /
                                                              currentRatingCount;

                                                  await itemRef.update({
                                                    'rating': updatedAvgRating,
                                                  });
                                                } else {
                                                  // User's first rating, set the average rating and increment rating count

                                                  //items first rating
                                                  if (currentRatingCount == 0) {
                                                    currentRatingCount++;
                                                    double updatedAvgRating =
                                                        newRating /
                                                            currentRatingCount;
                                                    await itemRef.update({
                                                      'rating':
                                                          updatedAvgRating,
                                                      'ratingCount': 1,
                                                    });
                                                  } else {
                                                    double updatedAvgRating =
                                                        (currentAvgRating *
                                                                    currentRatingCount +
                                                                newRating) /
                                                            (currentRatingCount +
                                                                1);
                                                    await itemRef.update({
                                                      'rating':
                                                          updatedAvgRating,
                                                      'ratingCount':
                                                          currentRatingCount +
                                                              1,
                                                    });
                                                  }
                                                }
                                              }

                                              var commentController =
                                                  TextEditingController();
                                              var showCommentSection = false;
                                              bool isChanged = false;
                                              double itemRating = rating;

                                              if (commentController
                                                      .text.isEmpty &&
                                                  !isChanged) {
                                                commentController.text =
                                                    comment;
                                                showCommentSection = true;
                                              }

                                              return AlertDialog(
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: const Text('Save'),
                                                    onPressed: () async {
                                                      if (isChanged) {
                                                        // Update the item rating and count
                                                        await updateItemRatingAndCount(
                                                            itemRef,
                                                            itemRating);

                                                        final commentText =
                                                            commentController
                                                                .text
                                                                .trim();
                                                        final commentQuerySnapshot =
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'comments')
                                                                .where('userId',
                                                                    isEqualTo:
                                                                        LoginPage
                                                                            .userID)
                                                                .where(
                                                                    'itemRef',
                                                                    isEqualTo:
                                                                        itemRef)
                                                                .limit(1)
                                                                .get();
                                                        if (commentQuerySnapshot
                                                                .size >
                                                            0) {
                                                          // Update the existing comment
                                                          final commentRef =
                                                              commentQuerySnapshot
                                                                  .docs[0]
                                                                  .reference;
                                                          await commentRef.set(
                                                              {
                                                                'rating':
                                                                    itemRating,
                                                                'text':
                                                                    commentText,
                                                                'timestamp':
                                                                    FieldValue
                                                                        .serverTimestamp(),
                                                              },
                                                              SetOptions(
                                                                  merge: true));
                                                        } else {
                                                          // Save a new comment
                                                          final commentRef =
                                                              FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'comments')
                                                                  .doc();
                                                          await commentRef.set({
                                                            'rating':
                                                                itemRating,
                                                            'text': commentText,
                                                            'timestamp': FieldValue
                                                                .serverTimestamp(),
                                                            'itemRef': itemRef,
                                                            'userId': LoginPage
                                                                .userID,
                                                          });
                                                        }
                                                      }
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                                content: SizedBox(
                                                  height: 275,
                                                  width: 500,
                                                  child: StatefulBuilder(
                                                    builder:
                                                        (BuildContext context,
                                                            setState) {
                                                      return FutureBuilder<
                                                          DocumentSnapshot>(
                                                        future: itemRef.get(),
                                                        builder: (BuildContext
                                                                context,
                                                            AsyncSnapshot<
                                                                    DocumentSnapshot>
                                                                snapshot) {
                                                          if (snapshot
                                                                  .hasError ||
                                                              !snapshot.data!
                                                                  .exists ||
                                                              !snapshot
                                                                  .hasData) {
                                                            return const SizedBox();
                                                          }
                                                          final itemData =
                                                              snapshot.data!;
                                                          final itemName =
                                                              itemData.get(
                                                                      'name')
                                                                  as String;
                                                          final itemPrice =
                                                              itemData
                                                                  .get('price');
                                                          final imageUrl =
                                                              itemData.get(
                                                                      'image_url')
                                                                  as String;
                                                          return Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(6),
                                                                    child:
                                                                        SizedBox(
                                                                      width: 75,
                                                                      child: Image
                                                                          .network(
                                                                        imageUrl,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                          itemName),
                                                                      Text(
                                                                        '$itemPrice\$',
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                14),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .comment),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        showCommentSection =
                                                                            !showCommentSection;
                                                                      });
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 20),
                                                              RatingBar.builder(
                                                                glowColor:
                                                                    Colors
                                                                        .amber,
                                                                glowRadius: 0.5,
                                                                initialRating:
                                                                    itemRating,
                                                                minRating: 0,
                                                                direction: Axis
                                                                    .horizontal,
                                                                allowHalfRating:
                                                                    true,
                                                                itemCount: 5,
                                                                itemPadding:
                                                                    const EdgeInsets
                                                                            .fromLTRB(
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        5),
                                                                itemBuilder:
                                                                    (context,
                                                                            _) =>
                                                                        const Icon(
                                                                  Icons.star,
                                                                  color: Colors
                                                                      .amber,
                                                                ),
                                                                onRatingUpdate:
                                                                    (rating) {
                                                                  setState(() {
                                                                    showCommentSection =
                                                                        true;
                                                                    isChanged =
                                                                        true;
                                                                    itemRating =
                                                                        rating;
                                                                  });
                                                                },
                                                              ),
                                                              if (showCommentSection)
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          8),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      if (commentController
                                                                              .text
                                                                              .isNotEmpty &&
                                                                          !isChanged)
                                                                        const Text(
                                                                          'You previously left this comment:',
                                                                          style:
                                                                              TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                      TextField(
                                                                        onChanged:
                                                                            (value) {
                                                                          setState(
                                                                              () {
                                                                            isChanged =
                                                                                true;
                                                                          });
                                                                        },
                                                                        controller:
                                                                            commentController,
                                                                        decoration:
                                                                            const InputDecoration(hintText: 'Type your comment here'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8.0),
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        '$rating',
                                        style: const TextStyle(fontSize: 18.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    '$comment',
                                    style: const TextStyle(fontSize: 18.0),
                                  ),
                                  const SizedBox(height: 12.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        restaurantName,
                                        style: const TextStyle(
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
        ],
      ),
    );
  }
}

class ProfileDetails extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const ProfileDetails({
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
            return const Text(
              'Error',
              style: TextStyle(color: Colors.black),
            );
          } else {
            final customerName = snapshot.data!.get('name') +
                ' ' +
                snapshot.data!.get('surname');
            final customerPhone = snapshot.data!.get('phone');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$customerName',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    height: 1.5,
                  ),
                ),
                Text(
                  '$customerPhone',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            );
          }
        } else {
          return const Text(
            'Loading...',
            style: TextStyle(color: Colors.black),
          );
        }
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height * 1.1);
}

class ProfilePageButton extends StatelessWidget {
  const ProfilePageButton({
    super.key,
    required this.text,
    required this.icon,
  });

  final String text;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
        const Expanded(child: SizedBox()),
        const Icon(Icons.arrow_forward, size: 20),
      ],
    );
  }
}
