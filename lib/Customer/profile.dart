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
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
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
                const ProfilePageButton(
                  icon: Icon(Icons.credit_card),
                  text: "Payment Methods",
                ),
                //todo column icinde ProfilePageButton kullan.
                const SizedBox(height: 20),
                Text(
                  'My Cart',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 20),
                Text(
                  'Help',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 20),
                Text(
                  'Language',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 20),
                Text(
                  'Notification',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ],
            ),
          ],
        ),
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
