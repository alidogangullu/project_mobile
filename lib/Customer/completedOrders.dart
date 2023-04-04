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
            return const SizedBox();
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
                    return const Center(child: CircularProgressIndicator(),);
                  }
                  final restaurantName = snapshot.data!.get('name') as String;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
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
                                return SizedBox();
                              }
                              final itemName = snapshot.data!.get('name') as String;
                              return Text(
                                '- $itemName',
                                style: TextStyle(fontSize: 16.0),
                              );
                            },
                          );
                        },
                      ),
                    ],
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
