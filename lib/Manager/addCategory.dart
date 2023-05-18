import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../customWidgets.dart';

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