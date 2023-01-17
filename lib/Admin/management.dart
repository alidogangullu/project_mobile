import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_mobile/Admin/menuEdit.dart';
import 'package:project_mobile/Authentication/loginPage.dart';

class ManagementPanel extends StatelessWidget {
  const ManagementPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurants"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => addRestaurant(),
            ),
          );
        },
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var accessibleRestaurantIDs = snapshot.data!['managerOf'];
          return ListView.builder(
            itemCount: accessibleRestaurantIDs.length,
            itemBuilder: (context, index) {
              return Card(
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: ListTile(
                        leading: const Icon(Icons.storefront),
                        title: Text(accessibleRestaurantIDs[index].toString().split("#creator").first),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    editMenu(
                                      collection:
                                      "Restaurants/${accessibleRestaurantIDs[index]}/MenuCategory",
                                      restaurantName: accessibleRestaurantIDs[index].toString().split("#creator").first,
                                    ),
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
                              .collection("Restaurants/")
                              .doc(accessibleRestaurantIDs[index])
                              .delete();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },),
    );
  }
}

class addRestaurant extends StatelessWidget {
  addRestaurant({Key? key})
      : super(key: key);
  final myController = TextEditingController();
  late String restaurantID= myController.text+"#creator"+LoginPage.userID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Restaurant"),
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
                  //create database doc
                  FirebaseFirestore.instance
                      .collection("Restaurants").doc(restaurantID).set({
                    "name": myController.text,
                  });

                  //add restaurant id to creator's manager list
                  var list = [restaurantID];
                  FirebaseFirestore.instance
                      .collection("users").doc(LoginPage.userID).update({
                    "managerOf": FieldValue.arrayUnion(list)});

                  //exit
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
