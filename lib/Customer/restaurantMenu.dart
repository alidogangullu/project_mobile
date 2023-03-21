import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/customerPanel.dart';

//TAMAMEN WEB APP'ten ALINDI
//todo detaylandirma (managerin menu olusturma ekrani ile birlikte)

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.id, required this.tableNo});

  final String id;
  final String tableNo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  late List<dynamic> orders = [];

  Future<void> placeOrder() async {
    var document = FirebaseFirestore.instance
        .collection("${widget.restaurantPath}/Tables")
        .doc(widget.table);
    await document.update({'OrderList': orders});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedCategory),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              //test için sipariş oluşturma ekranı
              //todo daha iyisi
              title: const Text("Order List"),
              content: SizedBox(
                width: 500,
                height: 500,
                child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(orders[index]),
                          trailing: InkWell(
                              onTap: () {
                                setState(() {
                                  orders.removeAt(index);
                                });
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.remove,
                                color: Colors.red,
                              )),
                        ),
                      );
                    }),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    placeOrder();
                    Navigator.pop(context);
                  },
                  child: const Text("Place the Order"),
                )
              ],
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
                        onPressed: () {
                          orders.add(document['name']);
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
        return CircularProgressIndicator();
      },
    );
  }
}
