import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:project_mobile/Customer/customerPanel.dart';
import 'package:project_mobile/Customer/order.dart';

//todo detaylandirma (managerin menu olusturma ekrani ile birlikte)

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.id, required this.tableNo});

  final String id;
  final String tableNo;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection("Restaurants/${widget.id}/Tables")
        .doc(widget.tableNo)
        .get()
        .then((document) {
      users = document.data()!['users'];
      bool isAdmin = users.isEmpty ||
          users.contains(
              "${LoginPage.userID}-admin"); // First accessed user is admin

      if (isAdmin) {
        String userId = '${LoginPage.userID}${isAdmin ? '-admin' : ''}';
        FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/Tables")
            .doc(widget.tableNo)
            .update({
          'users': FieldValue.arrayUnion([userId]),
        });
      } else if (users.contains(LoginPage.userID)) {
      } else {
        FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/Tables")
            .doc(widget.tableNo)
            .update({
          'unAuthorizedUsers': FieldValue.arrayUnion([LoginPage.userID]),
        });
      }

      if (users.contains("${LoginPage.userID}-admin")) {
        // Listen for changes to the users array
        FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/Tables")
            .doc(widget.tableNo)
            .snapshots()
            .listen((documentSnapshot) {
          List<dynamic> unAuthorizedUsers =
              documentSnapshot.data()!['unAuthorizedUsers'];
          if (unAuthorizedUsers.isNotEmpty) {
            // New user joined, display popup dialog to admin
            for (var user in unAuthorizedUsers) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('New User Joined'),
                    content: Text('Allow user $user to access orders?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Allow user to access menu
                          Navigator.of(context).pop();
                          FirebaseFirestore.instance
                              .collection("Restaurants/${widget.id}/Tables")
                              .doc(widget.tableNo)
                              .update({
                            'users': FieldValue.arrayUnion([user]),
                            'unAuthorizedUsers': FieldValue.arrayRemove([user]),
                          });
                        },
                        child: const Text('Allow'),
                      ),
                    ],
                  );
                },
              );
            }
          }
          users = documentSnapshot.data()!['users'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ShoppingCartFloatingButton(
          userID: LoginPage.userID,
          tableNo: widget.tableNo,
          restaurantID: widget.id),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const CustomerHome()));
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: RestaurantNameText(
          id: widget.id,
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/MenuCategory")
            .orderBy("name", descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return ListView(
              children: snapshot.data!.docs.map((document) {
                //restorant menüsü kategorileri listeleme
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryItemsList(
                          restaurantPath: "Restaurants/${widget.id}",
                          selectedCategory: document['name'],
                          table: widget.tableNo,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.emoji_food_beverage),
                      title: Text(document['name']),
                    ),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}

class CategoryItemsList extends StatelessWidget {
  const CategoryItemsList(
      {Key? key,
      required this.restaurantPath,
      required this.selectedCategory,
      required this.table})
      : super(key: key);

  final String restaurantPath;
  final String selectedCategory;
  final String table;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedCategory),
      ),
      floatingActionButton: ShoppingCartFloatingButton(
          restaurantID: restaurantPath.split("/").last,
          tableNo: table,
          userID: LoginPage.userID),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('$restaurantPath/MenuCategory/$selectedCategory/list')
              .orderBy('name', descending: true)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return ListView(
                children: snapshot.data!.docs.map((document) {
                  //kategornin içindeki ürünleri listeme
                  //todo yorum, estimated time vb diğer bilgiler
                  return Card(
                    child: ListTile(
                      leading: document['image_url'] != null
                          ? Image.network(
                        document['image_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : const SizedBox.shrink(),
                      title: Text(document['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: ${document['price']}'),
                          Text('Content: ${document['content']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection("$restaurantPath/Tables")
                              .doc(table)
                              .collection("Orders")
                              .where("itemRef", isEqualTo: document.reference)
                              .get();
                          if (querySnapshot.size > 0) {
                            // Item already exists in order, update its quantity
                            final orderDoc = querySnapshot.docs.first;
                            final quantity =
                                orderDoc["quantity_notSubmitted_notServiced"] +
                                    1;
                            orderDoc.reference.update({
                              "quantity_notSubmitted_notServiced": quantity
                            });
                          } else {
                            // Item doesn't exist in order, add it with quantity 1
                            FirebaseFirestore.instance
                                .collection("$restaurantPath/Tables")
                                .doc(table)
                                .collection("Orders")
                                .doc()
                                .set({
                              "itemRef": document.reference,
                              "quantity_notSubmitted_notServiced": 1,
                              "quantity_Submitted_notServiced": 0,
                              "quantity_Submitted_Serviced": 0,
                            });
                          }
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

class ShoppingCartFloatingButton extends StatelessWidget {
  const ShoppingCartFloatingButton({
    super.key,
    required this.restaurantID,
    required this.tableNo,
    required this.userID,
  });

  final String restaurantID;
  final String tableNo;
  final String userID;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: FirebaseFirestore.instance
          .collection("Restaurants/$restaurantID/Tables")
          .doc(tableNo)
          .snapshots()
          .map<List<dynamic>>((snapshot) => snapshot.data()!['users']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final users = snapshot.data ?? [];
        final isAdmin = users.isEmpty || users.contains("$userID-admin");
        final currentUserIsAuthorized = users.contains(userID) || isAdmin;
        return FloatingActionButton(
          onPressed: currentUserIsAuthorized
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrdersPage(
                        ordersRef: FirebaseFirestore.instance
                            .collection("Restaurants/$restaurantID/Tables")
                            .doc(tableNo)
                            .collection("Orders"),
                        tableRef: FirebaseFirestore.instance
                            .collection("Restaurants/$restaurantID/Tables")
                            .doc(tableNo),
                      ),
                    ),
                  );
                }
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Unauthorized User'),
                      content: const Text(
                          'You are not authorized to access orders.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
          child: const Icon(Icons.shopping_basket),
        );
      },
    );
  }
}

class RestaurantNameText extends StatelessWidget {
  const RestaurantNameText({Key? key, required this.id}) : super(key: key);
  final String id;

  //restorant id'sinden restorant ismini Text Widget olarak döndürme

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection("Restaurants").doc(id).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data!['name']);
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
