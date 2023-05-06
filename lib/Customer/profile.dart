import 'dart:io';

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
  String _selectedOption = 'Option 1'; //DropDown button için
  File? _image;
  final _picker = ImagePicker();
  String _profilePhotoUrl = '';

  final List<TextEditingController> _controllers = [
    TextEditingController()
  ]; //Comment kısmı için

  void _addTextField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeTextField(int index) {
    setState(() {
      _controllers.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _getProfilePhoto(widget.userId);
  }

  Future<void> _getProfilePhoto(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userSnapshot = await userRef.get();
    final profileImageUrl =  userSnapshot.data()?['profileImageUrl'];
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
    final storageReference =
    FirebaseStorage.instance.ref().child('profileImageUrl/${widget.userId}');
    final uploadTask = storageReference.putFile(image);
    final downloadURL = await (await uploadTask).ref.getDownloadURL();
    return downloadURL;
  }

  Future<void> _updateProfileImageUrl(String profileImageUrl) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    await userRef.update({'profileImageUrl': profileImageUrl});
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 4),
          Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
      body: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: [
                  ClipOval(
                    child: _image != null
                        ? Image.file(
                      _image!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                        : Image.network(
                      _profilePhotoUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Wrap(
                            children: [
                              ListTile(
                                leading: Icon(Icons.photo_camera),
                                title: Text(
                                  'Take a photo',
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _getImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text(
                                  'Select from gallery',
                                  style: Theme.of(context).textTheme.bodyText2,
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
                      child: Icon(Icons.camera_alt, size: 20),
                      mini: true,
                    ),
                  ),
                ],
              ),

        ),
            SizedBox(width: 20),
            Expanded(
              child: MyAppBar(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'My Cart',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Help',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Language',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Notification',
                    style: Theme.of(context).textTheme.headline6,

                  ),

                ],
              ),
            ),


          ],
        ),

      ),





    );
  }
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const MyAppBar({
    Key? key,
    this.height = kToolbarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(LoginPage.userID).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return AppBar(title: const Text('Error', style: TextStyle(color: Colors.black)),backgroundColor: Colors.white,);
          } else {
            final customerName = snapshot.data!.get('name');
            final customerPhone = snapshot.data!.get('phone');

            return AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,

              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
              ),
            );
          }
        } else {
          return AppBar(title: const Text('Loading...', style: TextStyle(color: Colors.black),),backgroundColor: Colors.white,);
        }
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height * 1.1);
}
