import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Admin/qrGenerator.dart';

class editMenu extends StatelessWidget {
  editMenu({Key? key, required this.collection, required this.restaurantName}) : super(key: key);
  final String collection;
  final String restaurantName;

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
            flex: 2,
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
                                            selected: document['name']),
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
                                      .doc(document["name"])
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
          Expanded(
            flex: 1,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                  "Create QR Codes for Tables", const Icon(Icons.qr_code_2), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QR_HomePage(selectedRestaurant: restaurantName,),
                  ),
                );
              },),
            ]),
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
                  final ref = FirebaseFirestore.instance.collection(collection);
                  ref.doc(myController.text).set({
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
                      leading: const Icon(Icons.emoji_food_beverage),
                      title: Text(document['name']),
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
              ElevatedButton(
                child: const Text(
                  "Add",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  final ref = FirebaseFirestore.instance
                      .collection("$collection/$selected/list");
                  ref.doc(myController.text).set({
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
