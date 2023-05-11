import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:project_mobile/Admin/desktopApplicationConnection.dart';
import 'package:project_mobile/Admin/qrGenerator.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_mobile/Admin/restaurantManagers.dart';
import 'package:simple_speed_dial/simple_speed_dial.dart';

import '../customWidgets.dart';

class EditRestaurant extends StatefulWidget {
  const EditRestaurant(
      {Key? key,
      required this.collection,
      required this.restaurantName,
      required this.restaurantID})
      : super(key: key);
  final String collection;
  final String restaurantName;
  final String restaurantID;

  @override
  State<EditRestaurant> createState() => _EditRestaurantState();
}

class _EditRestaurantState extends State<EditRestaurant> {
  String selected = "";
  String _searchQuery = '';
  final searchController = TextEditingController();

  Future<List<QueryDocumentSnapshot>> getItemsForAllCategories(
      List<QueryDocumentSnapshot> categories) async {
    List<QueryDocumentSnapshot> allDocuments = [];
    for (var doc in categories) {
      final items = await FirebaseFirestore.instance
          .collection('${widget.collection}/${doc.id}/list')
          .get();
      allDocuments.addAll(items.docs);
    }
    return allDocuments;
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void passSetState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.restaurantName,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        openBackgroundColor: Colors.black,
        speedDialChildren: [
          SpeedDialChild(
            child: const Icon(Icons.category),
            label: 'Add Menu Category',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCategory(
                    collection: widget.collection,
                  ),
                ),
              );
            },
            closeSpeedDialOnPressed: true,
          ),
          SpeedDialChild(
            child: const Icon(Icons.restaurant_menu_outlined),
            label: 'Add Category Item',
            onPressed: () {
              if (selected.isEmpty) {
                const snackBar = SnackBar(
                  content: Text(
                      'Please choose a category before adding a new item.'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCategoryItems(
                        collection: widget.collection, selected: selected),
                  ),
                );
              }
            },
            closeSpeedDialOnPressed: true,
          ),
          SpeedDialChild(
            child: const Icon(Icons.manage_accounts),
            label: 'Edit Restaurant Managers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRestaurantManagers(
                    restaurantId: widget.restaurantID,
                  ),
                ),
              );
            },
            closeSpeedDialOnPressed: true,
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code_2),
            label: 'Create QR Codes for Tables',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRHomePage(
                    selectedRestaurantID: widget.restaurantID,
                  ),
                ),
              );
            },
            closeSpeedDialOnPressed: true,
          ),
          SpeedDialChild(
            child: const Icon(Icons.desktop_windows_outlined),
            label: 'Edit Waiters Access',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DesktopAppConnect(
                    restaurantId: widget.restaurantID,
                  ),
                ),
              );
            },
            closeSpeedDialOnPressed: true,
          ),
        ],
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          textInputField(context, "Search Item", searchController, false,
              iconData: Icons.search, onChanged: _onSearchQueryChanged),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 5, 0, 0),
            child: SizedBox(
              height: 30,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(widget.collection)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading categories...');
                  }
                  final categories =
                      snapshot.data!.docs.map((doc) => doc.id).toList();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () => setState(() => selected == category
                            ? selected = ''
                            : selected = category),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected == category
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: selected == category
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(widget.collection)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categories = snapshot.data!.docs;
                  return FutureBuilder(
                    future: getItemsForAllCategories(categories),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<QueryDocumentSnapshot>>
                            itemsSnapshot) {
                      if (itemsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = itemsSnapshot.data!;
                      final visibleItems = selected.isEmpty
                          ? items
                          : items
                              .where((item) => item.reference.path
                                  .startsWith('${widget.collection}/$selected'))
                              .toList();
                      final filteredItems = visibleItems.where((item) {
                        final name = item['name'].toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();
                      return createItemsGrid(
                          filteredItems, context, selected, widget.collection, setState: passSetState);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget createItemsGrid(
    List<QueryDocumentSnapshot> documents, context, selected, collection, {required VoidCallback setState}) {
  return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.70,
      children: documents.map((document) {
        String initialPrice = document['price'].toString();
        TextEditingController priceController = TextEditingController();

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              isScrollControlled: true,
              enableDrag: true,
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              builder: (BuildContext context) {
                var selectedItem = document.reference;
                return Wrap(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.5,
                        child: Image.network(
                          document["image_url"],
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 15, 10),
                      child: Text(
                        document['name'],
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 15, 15),
                      child: Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              if (index < document["rating"]) {
                                return const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                );
                              } else {
                                return const Icon(
                                  Icons.star_border,
                                  color: Colors.amber,
                                );
                              }
                            }),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            document["rating"].toString(),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 15, 15),
                      child: Row(
                        children: [
                          const Text(
                            'Price: ',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: initialPrice,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    menuButton("Save", () {
                      final newPrice =
                          double.tryParse(priceController.text) ??
                              document['price'];
                      FirebaseFirestore.instance.doc(selectedItem.path).update({'price': newPrice});
                      setState();
                      Navigator.pop(context);
                    }),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            FirebaseFirestore.instance.doc(selectedItem.path).delete();
                            setState();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: Image.network(
                      document["image_url"],
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      document['name'],
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document["rating"].toString(),
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Text(
                      "\$ ${document['price']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList());
}

class AddCategory extends StatelessWidget {
  AddCategory({Key? key, required this.collection}) : super(key: key);
  final String collection;
  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Add Category",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
              textInputField(context, "Category Name", myController, false),
              menuButton("Add Category", () {
                FirebaseFirestore.instance
                    .collection(collection)
                    .doc(myController.text)
                    .set({
                  "name": myController.text,
                });
                myController.clear();
                Navigator.pop(context);
              })
            ],
          ),
        ),
      ),
    );
  }
}

class AddCategoryItems extends StatefulWidget {
  const AddCategoryItems(
      {Key? key, required this.collection, required this.selected})
      : super(key: key);
  final String collection;
  final String selected;

  @override
  State<AddCategoryItems> createState() => _AddCategoryItemsState();
}

class _AddCategoryItemsState extends State<AddCategoryItems> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final contentController = TextEditingController();

  final picker = ImagePicker();
  File? _imageFile;

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
                  'Restaurant Image',
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
                          .collection(
                              "${widget.collection}/${widget.selected}/list");

                      await firestoreRef.doc(nameController.text).set({
                        "name": nameController.text,
                        "price": double.parse(priceController.text),
                        "content": contentController.text,
                        "image_url": imageUrl,
                        "rating": 0,
                        "ratingCount" : 0
                      });

                      nameController.clear();
                      priceController.clear();
                      contentController.clear();

                      Navigator.pop(context);
                    } else {
                      const snackBar = SnackBar(
                        content: Text('Please fill in all required fields.'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  }),
          ],
        ),
      ),
    );
  }
}