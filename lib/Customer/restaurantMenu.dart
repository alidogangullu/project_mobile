import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/customerPanel.dart';
import 'package:project_mobile/Customer/order.dart';

//todo detaylandirma (managerin menu olusturma ekrani ile birlikte)

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.id, required this.tableNo});

  final String id;
  final String tableNo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrdersPage(
                ordersRef: FirebaseFirestore.instance
                    .collection("Restaurants/$id/Tables")
                    .doc(tableNo)
                    .collection("Orders"),
              ),
            ),
          );
        },
        child: const Icon(Icons.shopping_basket),
      ),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const CustomerHome()));
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: RestaurantNameText(
          id: id,
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Restaurants/$id/MenuCategory")
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
                          restaurantPath: "Restaurants/$id",
                          selectedCategory: document['name'],
                          table: tableNo,
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

class CategoryItemsList extends StatefulWidget {
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
  State<CategoryItemsList> createState() => _CategoryItemsListState();
}

class _CategoryItemsListState extends State<CategoryItemsList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedCategory),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrdersPage(
                ordersRef: FirebaseFirestore.instance
                    .collection("${widget.restaurantPath}/Tables")
                    .doc(widget.table)
                    .collection("Orders"),
              ),
            ),
          );
        },
        child: const Icon(Icons.shopping_basket),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(
                  '${widget.restaurantPath}/MenuCategory/${widget.selectedCategory}/list')
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
                  //todo fiyat, yorum, estimated time vb diğer bilgiler
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.emoji_food_beverage),
                      title: Text(document['name']),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection("${widget.restaurantPath}/Tables")
                              .doc(widget.table)
                              .collection("Orders")
                              .where("itemRef", isEqualTo: document.reference)
                              .get();
                          if (querySnapshot.size > 0) {
                            // Item already exists in order, update its quantity
                            final orderDoc = querySnapshot.docs.first;
                            final quantity = orderDoc["quantity_notSubmitted_notServiced"] + 1;
                            orderDoc.reference.update({"quantity_notSubmitted_notServiced": quantity});
                          } else {
                            // Item doesn't exist in order, add it with quantity 1
                            FirebaseFirestore.instance
                                .collection("${widget.restaurantPath}/Tables")
                                .doc(widget.table)
                                .collection("Orders")
                                .doc()
                                .set({
                              "itemRef": document.reference,
                              "quantity_notSubmitted_notServiced" : 1,
                              "quantity_Submitted_notServiced" : 0,
                              "quantity_Submitted_Serviced" : 0,
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
