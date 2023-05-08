import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Authentication/loginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key, required this.userId}) : super(key: key);
  final String userId;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
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
                    icon: Icon(Icons.edit)),
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
                //todo column icinde ProfilePageButton kullan.
                Text(
                  'Help',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CommentsPage()),
                    );
                  },
                  child: ProfilePageButton(
                    icon: Icon(Icons.rate_review),
                    text: 'Comments',
                  ),
                ),
                const SizedBox(height: 20),
                ProfilePageButton(text: 'Notifications', icon: Icon(Icons.notifications)),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                  },
                    child: ProfilePageButton(text: 'Logout', icon: Icon(Icons.logout))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsPage extends StatefulWidget {
  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Restaurants')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final restaurants = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select a restaurant',
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.black, width: 0.0),
                    ),
                    labelStyle: TextStyle(
                      color: Colors
                          .black, // sets the color of the label text to black
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
                        doc.get('itemRef').toString().split('/')[1] ==
                        _selectedRestaurantId)
                    .toList();
                return ListView.builder(
                  itemCount: filteredDocuments.length,
                  itemBuilder: (BuildContext context, int index) {
                    final order = filteredDocuments[index];
                    final userId = order.get('userId');
                    if (userId != LoginPage.userID) {
                      // if the comment was not made by the current user, do not show it
                      return const SizedBox();
                    }
                    DocumentReference item = order.get("itemRef");
                    final restaurantRef = item.path.split("/")[1];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .doc("Restaurants/$restaurantRef")
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
                          future: item.get(),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ' + '  ${snapshot.error}');
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }
                            final itemName =
                                snapshot.data!.get('name') as String;
                            final timestamp = order["timestamp"];
                            final comment = order["text"];
                            final rating = order["rating"];
                            final dateTime = timestamp.toDate().toLocal();
                            final formattedDate =
                                "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()} ${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}";
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          // navigate to edit comment page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditCommentPage(order: order),
                                            ),
                                          );
                                        },
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
        ],
      ),
    );
  }
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

class EditCommentPage extends StatefulWidget {
  final DocumentSnapshot order;

  const EditCommentPage({Key? key, required this.order}) : super(key: key);

  @override
  _EditCommentPageState createState() => _EditCommentPageState();
}

class _EditCommentPageState extends State<EditCommentPage> {
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.order.get('text'));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _updateComment() async {
    await widget.order.reference.update({
      'text': _commentController.text,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Edit Comment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            height: 1.5,
          ),
        ),
        textTheme: Theme.of(context).textTheme.copyWith(
              headline6: TextStyle(color: Colors.black),
            ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Current Comment:',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.grey[200],
              ),
              child: Text(
                '${widget.order.get('text')}',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            SizedBox(height: 24.0),
            Text(
              'Edit Comment:',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _commentController,
              maxLines: null,
              style: TextStyle(fontSize: 18.0),
              decoration: InputDecoration(
                hintText: 'Enter your edited comment here',
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.all(16.0),
              ),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _updateComment,
              child: Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 16.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                primary: Theme.of(context).shadowColor,
                elevation: 5.0,
              ),
            ),
          ],
        ),
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
