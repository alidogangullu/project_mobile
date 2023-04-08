import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//todo eski siparişlere yorum ekleme

class CompletedOrdersScreen extends StatelessWidget {
  final String customerId;

  const CompletedOrdersScreen({Key? key, required this.customerId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Orders'),
        actions: [
          IconButton(
            onPressed: () {}, //todo sort
            icon: const Icon(Icons.sort),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('/users/$customerId/completedOrders').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(),);
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              final order = snapshot.data!.docs[index];
              final items = order.get('items') as List<dynamic>;
              final restaurantRef = order.get('restaurantRef') as DocumentReference;
              return FutureBuilder<DocumentSnapshot>(
                future: restaurantRef.get(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  final restaurantName = snapshot.data!.get('name') as String;
                  final timestamp = order["timestamp"];
                  final dateTime = timestamp.toDate().toLocal();
                  final formattedDate = "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()} ${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}";

                  return Card(
                    child: ListTile(
                      title: Text(restaurantName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (BuildContext context, int index) {
                                final itemRef = items[index]['itemRef'] as DocumentReference;
                                return FutureBuilder<DocumentSnapshot>(
                                  future: itemRef.get(),
                                  builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                    if (!snapshot.hasData) {
                                      return const SizedBox();
                                    }
                                    final itemName = snapshot.data!.get('name') as String;
                                    return Text(
                                        '- $itemName'
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Text(formattedDate),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("250\$"), //test için eklendi databaseden çekilecek
                            IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OrderDetailsPage()
                                ),
                              );
                            },),
                          ],
                        ),
                      ),
                    )
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({Key? key}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Text("Text"),
    );
  }
}