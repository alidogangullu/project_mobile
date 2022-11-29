import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuEditor extends StatelessWidget {
  const MenuEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Menu Editor",
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => addCategory()),
          );
        },
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Category")
            .orderBy("name", descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          return ListView(
            children: snapshot.data!.docs.map((document) {
              return Card(
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: ListTile(
                        leading: Icon(Icons.emoji_food_beverage),
                        title: Text(document['name']),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    editMenuItems(selected: document['name']),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection("Category")
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
        },
      ),
    );
  }
}

class addCategory extends StatelessWidget {
  addCategory({Key? key}) : super(key: key);

  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Category"),
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
                  padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue)),
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: "Name",
                    ),
                    controller: myController,
                  ),
                ),
              ),
              ElevatedButton(
                child: Text(
                  "Add",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  final ref = FirebaseFirestore.instance.collection("Category");
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

class editMenuItems extends StatelessWidget {
  editMenuItems({Key? key, required this.selected}) : super(key: key);
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Items",
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => addItems(selected: selected)),
          );
        },
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Category/$selected/list')
              .orderBy('name', descending: true)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            return ListView(
              children: snapshot.data!.docs.map((document) {
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.emoji_food_beverage),
                    title: Text(document['name']),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('Category/$selected/list')
                            .doc(document["name"])
                            .delete();
                      },
                    ),
                  ),
                );
              }).toList(),
            );
          }),
    );
  }
}

class addItems extends StatelessWidget {
  addItems({Key? key, required this.selected}) : super(key: key);

  final String selected;
  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Item"),
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
                  padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue)),
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: "Name",
                    ),
                    controller: myController,
                  ),
                ),
              ),
              ElevatedButton(
                child: Text(
                  "Add",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  final ref = FirebaseFirestore.instance
                      .collection("Category/$selected/list");
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