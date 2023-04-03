import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Customer/customerPanel.dart';
import 'package:slide_to_act/slide_to_act.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key, required this.ordersRef, required this.tableRef})
      : super(key: key);

  final DocumentReference tableRef;
  final CollectionReference ordersRef;
  @override
  State<OrdersPage> createState() => _OrdersState();
}

class _OrdersState extends State<OrdersPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Check if there are any orders that are not submitted and not serviced then navigate a tab
    widget.ordersRef
        .where('quantity_notSubmitted_notServiced', isNotEqualTo: 0)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        // If there are not new orders, navigate to the second tab
        _tabController.animateTo(1);
      }
    });
  }

  void confirmOrders() async {
    setState(() {
      _tabController.animateTo(1);
    });

    final ordersSnapshot = await widget.ordersRef.get();
    final orders = ordersSnapshot.docs
        .where((doc) => doc['quantity_notSubmitted_notServiced'] > 0)
        .toList();

    for (final order in orders) {
      final oldQuantity = order['quantity_notSubmitted_notServiced'];
      final submittedQuantity = order['quantity_Submitted_notServiced'];
      int newQuantity;
      if (submittedQuantity != null) {
        newQuantity = oldQuantity + submittedQuantity;
      } else {
        newQuantity = oldQuantity;
      }
      await widget.ordersRef.doc(order.id).update({
        'quantity_notSubmitted_notServiced': 0,
        'quantity_Submitted_notServiced': newQuantity,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Information"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.playlist_add),
              text: "Unconfirmed Orders",
            ),
            Tab(
              icon: Icon(Icons.playlist_add_check),
              text: "Confirmed Orders",
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          notSubmittedOrdersTab(),
          submittedOrdersTab(),
        ],
      ),
    );
  }

  Column notSubmittedOrdersTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.ordersRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = snapshot.data!.docs
                  .where((doc) =>
                      (doc.data() as Map<String, dynamic>)[
                          'quantity_notSubmitted_notServiced'] >
                      0)
                  .toList();
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data() as Map<String, dynamic>;
                  final reference = order['itemRef'] as DocumentReference;
                  final item = reference.get();
                  final orderID = orders[index].id;
                  return FutureBuilder<DocumentSnapshot>(
                    future: item,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }
                      final name = snapshot.data!.get('name') as String;
                      return Card(
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(name),
                                subtitle: const Text('Details'),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                if (order[
                                        'quantity_notSubmitted_notServiced'] !=
                                    1) {
                                  order['quantity_notSubmitted_notServiced']--;

                                  // Update the quantity in Firestore
                                  await widget.ordersRef.doc(orderID).update({
                                    'quantity_notSubmitted_notServiced': order[
                                        'quantity_notSubmitted_notServiced']
                                  });

                                  setState(() {});
                                } else {
                                  //print("last one, cannot delete");
                                }
                              },
                              icon: const Icon(
                                Icons.remove,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              '${order['quantity_notSubmitted_notServiced']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              onPressed: () async {
                                order['quantity_notSubmitted_notServiced']++;

                                // Update the quantity in Firestore
                                await widget.ordersRef.doc(orderID).update({
                                  'quantity_notSubmitted_notServiced':
                                      order['quantity_notSubmitted_notServiced']
                                });

                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              "${order['quantity_notSubmitted_notServiced'] * 10}\$",
                              style: const TextStyle(fontSize: 16),
                            ), //todo price information for menu items. '10' is test price.
                            IconButton(
                              onPressed: () async {
                                await widget.ordersRef.doc(orderID).delete();
                              },
                              icon: const Icon(Icons.delete),
                              padding: const EdgeInsets.only(right: 8),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SlideAction(
            onSubmit: () {
              confirmOrders();
            },
            text: "Slide to confirm order",
            textStyle: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Expanded submittedOrdersTab() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: widget.ordersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final submittedOrders = snapshot.data!.docs
              .where((doc) =>
                  doc['quantity_Submitted_notServiced'] > 0 ||
                  doc['quantity_Submitted_Serviced'] > 0)
              .toList();

          // Calculate the total amount for payment bottom sheet
          double totalAmount = 0;
          for (var order in submittedOrders) {
            final reference = order['itemRef'] as DocumentReference;
            final item = reference.get();
            const price = 10; //todo database integration
            final quantity = order['quantity_Submitted_notServiced'] +
                order['quantity_Submitted_Serviced'];
            totalAmount += price * quantity;
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: submittedOrders.length,
                  itemBuilder: (context, index) {
                    final order =
                        submittedOrders[index].data() as Map<String, dynamic>;
                    final reference = order['itemRef'] as DocumentReference;
                    final item = reference.get();
                    return FutureBuilder<DocumentSnapshot>(
                      future: item,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }
                        final name = snapshot.data!.get('name') as String;
                        int quantity = order['quantity_Submitted_notServiced'] +
                            order['quantity_Submitted_Serviced'];
                        return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: const Text('details'),
                            trailing: Text(
                              "10\$ x$quantity", // todo price information for menu items. 10 is test price.
                            ),
                            leading: order['quantity_Submitted_notServiced'] > 0
                                ? const Icon(Icons.timer_outlined)
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(52),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(52),
                          topRight: Radius.circular(52),
                        )),
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: MediaQuery.of(context).size.height * 0.8,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: submittedOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = submittedOrders[index];
                                      return FutureBuilder<DocumentSnapshot>(
                                        future: (order['itemRef']
                                                as DocumentReference)
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const SizedBox();
                                          }
                                          final name = snapshot.data!
                                              .get('name') as String;
                                          final quantity = order[
                                                  'quantity_Submitted_notServiced'] +
                                              order[
                                                  'quantity_Submitted_Serviced'];
                                          return ListTile(
                                            title: Text(name),
                                            subtitle: Text('x $quantity'),
                                            trailing: Text(
                                                '${(10.0).toStringAsFixed(2)}\$'),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${totalAmount.toStringAsFixed(2)}\$',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    paymentButton(),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      "Pay (${totalAmount.toStringAsFixed(2)}\$)",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ElevatedButton paymentButton() {
    return ElevatedButton(
      onPressed: () async {
        // TODO: Implement payment functionality, now its just for testing.

        final usersRef = FirebaseFirestore.instance.collection('users');

        // Get the list of user IDs from the table.
        final tableSnapshot = await widget.tableRef.get();
        final userIds = List<String>.from(tableSnapshot.get('users'));

        for (final userId in userIds) {
          // Get a reference to the user's orders collection.
          final userOrdersRef = usersRef.doc(userId).collection('orders');

          // Get a reference to the orders collection for this table.
          final tableOrdersRef = widget.tableRef.collection('Orders');

          // Loop through the orders for this table and transfer them to the user's orders collection.
          final tableOrdersSnapshot = await tableOrdersRef.get();

          for (final orderSnapshot in tableOrdersSnapshot.docs) {
            final orderData = orderSnapshot.data();
            final submittedServiced = orderData['quantity_Submitted_Serviced'] as int;
            final submittedNotServiced = orderData['quantity_Submitted_notServiced'] as int;
            if (submittedServiced > 0 || submittedNotServiced > 0) {
              await userOrdersRef.doc(orderSnapshot.id).set(orderData);
            }
            await tableOrdersRef.doc(orderSnapshot.id).delete(); // Delete from table orders
          }

          await widget.tableRef.update({'users': []});

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerHome()
            ),
          );
        }

      },
      child: const Text("Pay with ..."),
    );
  }
}
