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
      body: Text("")//todo completed orders
    );
  }
}
