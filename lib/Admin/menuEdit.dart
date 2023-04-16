import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Admin/qrGenerator.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class editRestaurant extends StatelessWidget {
  editRestaurant(
      {Key? key,
      required this.collection,
      required this.restaurantName,
      required this.restaurantID})
      : super(key: key);
  final String collection;
  final String restaurantName;
  final String restaurantID;

  void onPressed() {
    //TODO Edit Restaurant Managers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(collection)
                  .orderBy("name", descending: true)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: snapshot.data!.docs.map((document) {
                      return Card(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: ListTile(
                                leading: const Icon(Icons.emoji_food_beverage),
                                title: Text(document['name']),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => editCategoryItems(
                                            collection: collection,
                                            selected: document.id),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection(collection)
                                      .doc(document.id)
                                      .delete();
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
          Flexible(
            //height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MenuButton(
                  "Add Menu Category",
                  const Icon(Icons.restaurant_menu_outlined),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => addCategory(
                          collection: collection,
                        ),
                      ),
                    );
                  },
                ),
                MenuButton("Edit Restaurant Managers",
                    const Icon(Icons.manage_accounts), onPressed),
                MenuButton(
                  "Create QR Codes for Tables",
                  const Icon(Icons.qr_code_2),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QR_HomePage(
                          selectedRestaurantID: restaurantID,
                        ),
                      ),
                    );
                  },
                ),
                MenuButton(
                  "Edit Waiter Acces",
                  const Icon(Icons.desktop_windows_outlined),
                  () {
                    //TODO Garsonların DESKTOP APP GIRIS BILGILERINI yönetme
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class addCategory extends StatelessWidget {
  addCategory({Key? key, required this.collection}) : super(key: key);
  String collection;
  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Category"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue)),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Name",
                    ),
                    controller: myController,
                  ),
                ),
              ),
              ElevatedButton(
                child: const Text(
                  "Add",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection(collection)
                      .doc(myController.text)
                      .set({
                    "name": myController.text,
                  });
                  myController.clear();
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class editCategoryItems extends StatelessWidget {
  editCategoryItems(
      {Key? key, required this.collection, required this.selected})
      : super(key: key);
  final String selected;
  final String collection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Items",
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => addCategoryItems(
                    collection: collection, selected: selected)),
          );
        },
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('$collection/$selected/list')
              .orderBy('name', descending: true)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return ListView(
                children: snapshot.data!.docs.map((document) {
                  return Card(
                    child: ListTile(
                      leading: document['image_url'] != null
                          ? Image.network(
                              document['image_url'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox.shrink(),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(document['name']),
                          Text('Price: ' + document['price']),
                          Text('Content: ' + document['content']),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('$collection/$selected/list')
                              .doc(document["name"])
                              .delete();
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          }),
    );
  }
}

class addCategoryItems extends StatelessWidget {
  addCategoryItems({Key? key, required this.collection, required this.selected})
      : super(key: key);
  final String collection;
  final String selected;
  final myController = TextEditingController();
  final priceController = TextEditingController();
  final contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Item"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue)),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Name",
                    ),
                    controller: myController,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue)),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Price",
                    ),
                    controller: priceController,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue)),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Content",
                    ),
                    controller: contentController,
                  ),
                ),
              ),
              ElevatedButton(
                child: const Text(
                  "Add",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  if (myController.text.isNotEmpty &&
                      priceController.text.isNotEmpty &&
                      contentController.text.isNotEmpty) {
                    try {
                      XFile? image =
                          await _picker.pickImage(source: ImageSource.gallery);

                      var imageFile = File(image!.path);
                      String fileName = basename(imageFile.path);

                      final compressedImageFile =
                          await FlutterImageCompress.compressAndGetFile(
                        imageFile.absolute.path,
                        fileName,
                        minWidth: 800, // Adjust width and height accordingly
                        minHeight: 600,
                        quality: 75,
                      );

                      FirebaseStorage storage = FirebaseStorage.instance;
                      Reference ref =
                          storage.ref().child("Image-" + myController.text);

                      TaskSnapshot snapshot =
                          await ref.putFile(compressedImageFile!);
                      String imageUrl = await snapshot.ref.getDownloadURL();

                      final firestoreRef = FirebaseFirestore.instance
                          .collection("$collection/$selected/list");

                      await firestoreRef.doc(myController.text).set({
                        "name": myController.text,
                        "price": priceController.text,
                        "content": contentController.text,
                        "image_url": imageUrl
                      });

                      print('Data added successfully to Firestore.');

                      myController.clear();
                      priceController.clear();
                      contentController.clear();
                      Navigator.pop(context);
                    } catch (e) {
                      print(
                          'An error occurred while adding data to Firestore:');
                      print(e);
                    }
                  } else {
                    final snackBar = SnackBar(
                      content: Text('Please fill in all required fields.'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget MenuButton(String text, Icon icon, void Function() onPressed) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size(150, 55)),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
