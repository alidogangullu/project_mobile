import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
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

    setState(() {
      _tabController.animateTo(1);
    });
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
                      final price = snapshot.data!.get('price') as double;
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
                              "${order['quantity_notSubmitted_notServiced'] * price}\$",
                              style: const TextStyle(fontSize: 16),
                            ),
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

  FutureBuilder<QuerySnapshot> submittedOrdersTab() {
    return FutureBuilder<QuerySnapshot>(
      future: widget.ordersRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No orders"));
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
          double price = 0;
          final quantity = order['quantity_Submitted_notServiced'] +
              order['quantity_Submitted_Serviced'];
          reference.get().then((DocumentSnapshot documentSnapshot) {
            price = documentSnapshot["price"];
            totalAmount += price * quantity;
          });
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

                  return FutureBuilder<DocumentSnapshot>(
                    future: reference.get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }
                      final name = snapshot.data!.get('name') as String;
                      final price = snapshot.data!.get('price') as double;
                      int quantity = order['quantity_Submitted_notServiced'] +
                          order['quantity_Submitted_Serviced'];
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: const Text('details'),
                          trailing: Text(
                            "$price\$ x$quantity",
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
                  onPressed: () async {
                    var submittedOrdersLength = submittedOrders.length;
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                    itemCount: submittedOrdersLength,
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
                                          final price = snapshot.data!
                                              .get('price') as double;
                                          final quantity = order[
                                          'quantity_Submitted_notServiced'] +
                                              order[
                                              'quantity_Submitted_Serviced'];
                                          return ListTile(
                                            title: Text(name),
                                            subtitle: Text('x $quantity'),
                                            trailing: Text(
                                                '${(price).toStringAsFixed(2)}\$'),
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
                          ),
                        );
                      },
                    );
                  },
                  child: const Text(
                    "Summary and Payment",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

        for (final userID in userIds) {

          // Get a reference to the orders collection for this table.
          final tableOrdersRef = widget.tableRef.collection('Orders');
          final restaurantRef = widget.tableRef.parent.parent;

          // Loop through the orders for this table and transfer them to the user's orders collection.
          final tableOrdersSnapshot = await tableOrdersRef.get();

          String completedOrderId = LoginPage.userID+DateTime.now().toString();

          //split "-" because of -admin
          String userId = userID.split("-").first;

          await usersRef.doc(userId.split("-").first)
              .collection('completedOrders')
              .doc(completedOrderId).set({
            'restaurantRef' : restaurantRef,
            'timestamp': Timestamp.now(),
            'items': []
          });

          for (final orderSnapshot in tableOrdersSnapshot.docs) {
            final orderData = orderSnapshot.data();
            final submittedServiced = orderData['quantity_Submitted_Serviced'] as int;
            final submittedNotServiced = orderData['quantity_Submitted_notServiced'] as int;
            if (submittedServiced > 0 || submittedNotServiced > 0) {
              await usersRef.doc(userId).collection('completedOrders').doc(completedOrderId).update({
                'items': FieldValue.arrayUnion([orderData])
              });
            }
            await tableOrdersRef.doc(orderSnapshot.id).delete(); // Delete from table orders
          }

          //reset table users after transfering order data
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
