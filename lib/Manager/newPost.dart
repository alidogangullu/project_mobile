import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import 'package:project_mobile/customWidgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CreateNewPost extends StatefulWidget {
  const CreateNewPost({Key? key, required this.restaurantID}) : super(key: key);
  final String restaurantID;

  @override
  CreateNewPostState createState() => CreateNewPostState();
}

class CreateNewPostState extends State<CreateNewPost> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.requestPermission();
  }

  final captionController = TextEditingController();
  final picker = ImagePicker();
  File? _imageFile;

  bool get canCreatePost {
    return captionController.text.isNotEmpty && _imageFile != null;
  }

  bool loading = false;

  Future<Uint8List?> compressFile(File file) async {
    var result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 25,
    );
    return result;
  }

  Future<String?> uploadImageToFirebaseStorage(File imageFile) async {
    Uint8List? imageBytes = await compressFile(imageFile);

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("Image-${DateTime.now().millisecondsSinceEpoch}");

    TaskSnapshot snapshot = await ref.putData(imageBytes!);
    return snapshot.ref.getDownloadURL();
  }


Future<void> sendNotificationToFollowers(String restaurantID) async {
  // Get the list of user tokens from Firestore
  QuerySnapshot followersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('followedRestaurants', arrayContains: restaurantID)
      .get();

  List<String> userTokens = followersSnapshot.docs
      .map((doc) => doc['fcmToken'] as String)
      .toList();

  // Prepare the notification payload
  final message = {
    'notification': {
      'title': 'New Post',
      'body': 'A new post has been created for the restaurant!',
    },
    'data': {
      // Additional data you want to send with the notification
    },
  };

  List<Future> sendFutures = [];
  for (String token in userTokens) {
    RemoteMessage notification = RemoteMessage(
  data: message['data'] as Map<String, dynamic>,
  notification: RemoteNotification(
    title: message['notification']?['title'],
    body: message['notification']?['body'],
  ),
);

    sendFutures.add(FirebaseMessaging.instance.sendMessage(
));

  }

  // Send the notifications using FCM
  await Future.wait(sendFutures);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Share New Post",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Caption',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          textInputField(context, 'Caption', captionController, false),
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 10),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Image',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: <Widget>[
                TextButton(
                  child: const Text("Take Picture"),
                  onPressed: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.camera);

                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path);
                      });
                    }
                  },
                ),
                TextButton(
                  child: const Text("Select from Gallery"),
                  onPressed: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path);
                      });
                    }
                  },
                ),
                if (_imageFile != null)
                  Image.file(
                    _imageFile!,
                    width: 100,
                    height: 100,
                  ),
              ],
            ),
          ),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else
            menuButton("Share Post", () async {
              if (canCreatePost) {
                setState(() {
                  loading = true;
                });

                String? imageUrl = await uploadImageToFirebaseStorage(_imageFile!);

                await FirebaseFirestore.instance
                    .collection('Restaurants/${widget.restaurantID}/Posts')
                    .add({
                  'caption': captionController.text,
                  'imageUrl': imageUrl,
                  'timestamp': DateTime.now(),
                });

                await FirebaseFirestore.instance
                    .doc('Restaurants/${widget.restaurantID}')
                    .update({
                  'postCount': FieldValue.increment(1),
                });

                // Send notifications to the followers
                await sendNotificationToFollowers(widget.restaurantID);

                captionController.clear();
                setState(() {
                  _imageFile = null;
                });

                Navigator.pop(context);

                setState(() {
                  loading = false;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    customSnackBar("'Please fill in all required fields.'")
                );
              }
            }),
        ],
      ),
    );
  }
}
