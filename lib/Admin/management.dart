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
          //Add new restaurant
        },
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("users/${LoginPage.userID}/Restaurants")
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
                                leading: const Icon(Icons.storefront),
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
                                        builder: (context) => editMenu(
                                          collection:
                                              "users/${LoginPage.userID}/Restaurants/${document['name']}/MenuCategory",
                                          restaurantName: document['name'],
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
                                      .collection(
                                          "users/${LoginPage.userID}/Restaurants/${document['name']}/MenuCategory")
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
        ],
      ),
    );
  }
}