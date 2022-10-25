import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCategories extends StatefulWidget {
  const EditCategories({Key? key}) : super(key: key);
  @override
  _EditCategoriesState createState() => _EditCategoriesState();
}

class _EditCategoriesState extends State<EditCategories> {
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
          "Categories",
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
            .collection("Category").orderBy("name",descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                            FirebaseFirestore.instance.collection("Category").doc(document["name"]).delete();
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
        },
      ),
    );
  }}

class addCategory extends StatefulWidget {
  const addCategory({Key? key}) : super(key: key);

  @override
  State<addCategory> createState() => _addCategoryState();
}

class _addCategoryState extends State<addCategory> {
  @override

  final myController = TextEditingController();

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Category"),),
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
