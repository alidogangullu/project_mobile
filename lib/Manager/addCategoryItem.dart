import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../customWidgets.dart';

class AddCategoryItems extends StatefulWidget {
  const AddCategoryItems({
    Key? key,
    required this.collection,
    required this.selected,
    required this.restaurantID,
  }) : super(key: key);

  final String collection;
  final String selected;
  final String restaurantID;

  @override
  State<AddCategoryItems> createState() => _AddCategoryItemsState();
}

class _AddCategoryItemsState extends State<AddCategoryItems> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final contentController = TextEditingController();

  final picker = ImagePicker();
  File? _imageFile;

  late String restaurantName;
  late String restaurantImageUrl;

  bool createPost = false; // Checkbox state

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
    Reference ref =
    storage.ref().child("Image-${DateTime.now().millisecondsSinceEpoch}");

    TaskSnapshot snapshot = await ref.putData(imageBytes!);
    return snapshot.ref.getDownloadURL();
  }

  bool get canAddItem {
    return nameController.text.isNotEmpty &&
        priceController.text.isNotEmpty &&
        contentController.text.isNotEmpty &&
        _imageFile != null;
  }

  bool loading = false;

  Future<void> fetchRestaurantInfo() async {
    DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
        .doc('Restaurants/${widget.restaurantID}')
        .get();
    if (restaurantSnapshot.exists) {
      setState(() {
        restaurantName = restaurantSnapshot['name'];
        restaurantImageUrl = restaurantSnapshot['imageUrl'];
      });
    }
  }

  @override
  void initState() {
    fetchRestaurantInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Add Item",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            textInputField(context, "Name", nameController, false),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Content',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            textInputField(context, "Content", contentController, false),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            textInputField(context, "Price", priceController, true),
            Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 10),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Item Image',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Container(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final pickedFile =
                        await picker.pickImage(source: ImageSource.camera);
                        if (pickedFile != null) {
                          _imageFile = File(pickedFile.path);
                          if (_imageFile != null) {
                            setState(() {});
                          }
                        }
                      },
                      child: const Text('Take Picture'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          _imageFile = File(pickedFile.path);
                          if (_imageFile != null) {
                            setState(() {});
                          }
                        }
                      },
                      child: const Text('Select from Gallery'),
                    ),
                    _imageFile != null
                        ? Image.file(
                      _imageFile!,
                      width: 100,
                      height: 100,
                    )
                        : Container(),
                  ],
                ),
              ),
            ),
            CheckboxListTile(
              title: const Text('Share as post'),
              value: createPost,
              onChanged: (bool? value) {
                setState(() {
                  createPost = value ?? false;
                });
              },
            ),
            loading
                ? const Center(child: CircularProgressIndicator())
                : menuButton("Add New Item", () async {
              if (canAddItem) {
                setState(() {
                  loading = true;
                });

                String? imageUrl =
                await uploadImageToFirebaseStorage(_imageFile!);

                final firestoreRef = FirebaseFirestore.instance
                    .collection("${widget.collection}/${widget.selected}/list");

                await firestoreRef.doc(nameController.text).set({
                  "name": nameController.text,
                  "price": double.parse(priceController.text),
                  "content": contentController.text,
                  "image_url": imageUrl,
                  "rating": 0,
                  "ratingCount": 0,
                  "estimatedTime": 0,
                  "orderCount": 0,
                });

                if (createPost) {
                  await FirebaseFirestore.instance
                      .collection('Restaurants/${widget.restaurantID}/Posts')
                      .add({
                    'caption':
                    ' WOW! ${nameController.text} is new at $restaurantName!',
                    'imageUrl': imageUrl,
                    'timestamp': DateTime.now(),
                  });
                }

                nameController.clear();
                priceController.clear();
                contentController.clear();
                setState(() {
                  _imageFile = null;
                  loading = false;
                });

                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    customSnackBar('Please fill in all required fields.')
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
