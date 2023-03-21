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
            icon: Icon(Icons.sort),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users/$customerId/orders')
            //.orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final List<dynamic> items = order['items'];

              return Card(
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(order['restaurantName']),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ordered Items:'),
                      for (var item in items)
                        Text(' - ' + item), //todo adet bilgisi vb.
                      const SizedBox(height: 4),
                      Text('Total: ${order['total']}'),
                      const SizedBox(height: 8),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      //todo navigate to order detail screen
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
