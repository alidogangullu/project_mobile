import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_mobile/Admin/menuEdit.dart';

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
          //TODO - Add new restaurant
        },
      ),
      body: StreamBuilder(
        //TODO - change database (same name restaurant will be problem)
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var items = snapshot.data!['managerOf'];
          //TODO - if managerOf does not exist it gives error.
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Card(
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: ListTile(
                        leading: const Icon(Icons.storefront),
                        title: Text(items[index]),
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
                                      "Restaurants/${items[index]}/MenuCategory",
                                      restaurantName: items[index],
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
                              .doc(items[index])
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
