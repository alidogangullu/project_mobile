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
            .collection("Restaurants")
            .where('managers', arrayContains: LoginPage.userID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            //manager olunan restorantların listelenmesi
            children: snapshot.data!.docs
                .map((doc) => Card(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: ListTile(
                              leading: const Icon(Icons.storefront),
                              title: Text(doc["name"]),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => editRestaurant(
                                        collection:
                                            "Restaurants/${doc.id}/MenuCategory",
                                        restaurantName: doc["name"],
                                        restaurantID: doc.id,
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
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class addRestaurant extends StatelessWidget {
  addRestaurant({Key? key}) : super(key: key);
  final myController = TextEditingController();

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
                  //todo başka manager'lar da olabilir, restorant oluşturulurken ve daha sonrasında eklenebilmeli (userid, phone number vb. kullanara)
                  var list = [LoginPage.userID];
                  FirebaseFirestore.instance
                      .collection("Restaurants")
                      .doc()
                      .set({
                    "name": myController.text,
                    "managers": FieldValue.arrayUnion(list)
                  });

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
