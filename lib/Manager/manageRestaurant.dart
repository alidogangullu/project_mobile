import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:simple_speed_dial/simple_speed_dial.dart';
import '../customWidgets.dart';
import 'addCategory.dart';
import 'addCategoryItem.dart';

class EditRestaurantMenu extends StatefulWidget {
  const EditRestaurantMenu(
      {Key? key,
      required this.collection,
      required this.restaurantName,
      required this.restaurantID})
      : super(key: key);
  final String collection;
  final String restaurantName;
  final String restaurantID;

  @override
  State<EditRestaurantMenu> createState() => _EditRestaurantMenuState();
}

class _EditRestaurantMenuState extends State<EditRestaurantMenu> {
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
                          filteredItems, context, selected, widget.collection);
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
    List<QueryDocumentSnapshot> documents, context, selected, collection) {
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