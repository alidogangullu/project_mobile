import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Stats extends StatelessWidget {
  Stats({Key? key}) : super(key: key);
  final FirebaseAuth auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: const Text('Stats', style: TextStyle(color: Colors.black)),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: getCompletedOrders(auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<QueryDocumentSnapshot> completedOrders = snapshot.data!;
            double totalAmount = 0;
            List<DataRow> rows = [];
            for (int i = 0; i < completedOrders.length; i++) {
              QueryDocumentSnapshot document = completedOrders[i];
              final totalPrice = document['totalPrice'];
              totalAmount += totalPrice;

              DataRow row = DataRow(
                cells: [
                  DataCell(Text('#${i + 1}')),
                  DataCell(Text(totalPrice.toString())),
                ],
              );
              rows.add(row);
            }
            DataRow totalRow = DataRow(
              cells: [
                const DataCell(
                  Text(
                    'Total Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    totalAmount.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
            rows.add(totalRow);
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Scrollable(
                  viewportBuilder:
                      (BuildContext context, ViewportOffset offset) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: DataTable(
                            columns: const <DataColumn>[
                              DataColumn(
                                label: Text('Order'),
                              ),
                              DataColumn(
                                label: Text('Price paid'),
                              ),
                            ],
                            rows: rows,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

Future<List<QueryDocumentSnapshot>> getCompletedOrders(String userId) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('completedOrders')
      .get();

  return querySnapshot.docs;
}
