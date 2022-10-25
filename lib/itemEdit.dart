import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditItems extends StatefulWidget {
  const EditItems({Key? key}) : super(key: key);

  @override
  State<EditItems> createState() => _EditItemsState();
}

class _EditItemsState extends State<EditItems> {

  var selected;

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
            MaterialPageRoute(builder: (context) => addItems()),
          );
        },
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Category").orderBy("name",descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          List<DropdownMenuItem> Categories = [];
          for (int i = 0; i < snapshot.data!.docs.length; i++) {
            DocumentSnapshot snap = snapshot.data!.docs[i];
            Categories.add(
              DropdownMenuItem(
                child: Text(
                  snap["name"],
                  style: TextStyle(color: Colors.blue),
                ),
                value: snap["name"].toString(),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButton(
                  items: Categories,
                  onChanged: (category) {
                    setState(() {
                      selected = category;
                    });
                  },
                  value: selected,
                  isExpanded: false,
                  hint: new Text(
                    "Choose Category",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              Expanded(
                flex: 10,
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('Category/$selected/list').orderBy('name', descending: true).snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    return ListView(
                      children: snapshot.data!.docs.map((document) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    document['name'],
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 30.0),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      FirebaseFirestore.instance.collection("Category/$selected/list").doc(document["name"]).delete();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 50.0,
                              color: Colors.blue,
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class addItems extends StatefulWidget {
  const addItems({Key? key}) : super(key: key);

  @override
  State<addItems> createState() => _addItemsState();
}
final myController = TextEditingController();

class _addItemsState extends State<addItems> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Item"),),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0,4,0,4),
                child: Container(
                  padding: EdgeInsets.fromLTRB(10,2,10,2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue)
                  ),
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
                child: Text("Add", style: TextStyle(color: Colors.white),),
                onPressed: (){
                  final ref = FirebaseFirestore.instance.collection("Category/Drinks/list");
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
