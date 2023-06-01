import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:project_mobile/Customer/customerHome.dart';
import 'package:project_mobile/customWidgets.dart';
import 'package:slide_action/slide_action.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage(
      {Key? key,
      required this.ordersRef,
      required this.tableRef,
      required this.restaurantPath,
      required this.table})
      : super(key: key);

  final DocumentReference tableRef;
  final CollectionReference ordersRef;
  final String restaurantPath;
  final String table;
  @override
  State<OrdersPage> createState() => _OrdersState();
}

class _OrdersState extends State<OrdersPage> with TickerProviderStateMixin {
  late TabController _tabController;

  Future<bool> checkAuthorizedUser() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection("${widget.restaurantPath}/Tables")
        .doc(widget.table)
        .get();
    final List<dynamic> users = usersSnapshot.data()!['users'];
    if (users.contains(LoginPage.userID) ||
        users.contains("${LoginPage.userID}-admin")) {
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          customSnackBar("You are not authorized to this action."));

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHome()),
          (route) => false);
      return false;
    }
  }

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
    if (await checkAuthorizedUser()) {
      final ordersSnapshot = await widget.ordersRef.get();
      final orders = ordersSnapshot.docs
          .where((doc) => doc['quantity_notSubmitted_notServiced'] > 0)
          .toList();

      for (final order in orders) {
        final toSubmitQuantity = order['quantity_notSubmitted_notServiced'];
        final submittedQuantity = order['quantity_Submitted_notServiced'];
        int newQuantity = 0;
        if (submittedQuantity != null) {
          newQuantity = toSubmitQuantity + submittedQuantity;

          if (order['orderedTime'] == 0) {
            await widget.ordersRef.doc(order.id).update({
              "orderedTime": DateTime.now(),
            });
          }
        }

        await widget.ordersRef.doc(order.id).update({
          'quantity_notSubmitted_notServiced': 0,
          'quantity_Submitted_notServiced': newQuantity,
        });

        await widget.tableRef.update({
          'newNotification': true,
          'notifications': FieldValue.arrayUnion([
            "New order: ${toSubmitQuantity}x ${order['itemRef'].toString().split("/").last.split(")").first}"
          ]),
        });
      }

      setState(() {
        _tabController.animateTo(1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Orders",
          style: TextStyle(color: Colors.black),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              text: "Unconfirmed",
            ),
            Tab(
              text: "Confirmed",
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          unConfirmedOrdersTab(),
          confirmedOrdersTab(),
        ],
      ),
    );
  }

  Column unConfirmedOrdersTab() {
    void deleteAnItem(var order, var orderID) async {
      if (await checkAuthorizedUser()) {
        if (order['quantity_notSubmitted_notServiced'] != 1) {
          order['quantity_notSubmitted_notServiced']--;
          // Update the quantity in Firestore
          await widget.ordersRef.doc(orderID).update({
            'quantity_notSubmitted_notServiced':
                order['quantity_notSubmitted_notServiced']
          });
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(customSnackBar(
              "Last item! Use delete button to delete this item from order list."));
        }
      }
    }

    void deleteAllItems(var order, var orderID) async {
      if (await checkAuthorizedUser()) {
        await widget.ordersRef.doc(orderID).update({
          'quantity_notSubmitted_notServiced': 0,
        });
        setState(() {});
      }
    }

    void addItem(var order, var orderID) async {
      if (await checkAuthorizedUser()) {
        order['quantity_notSubmitted_notServiced']++;
        // Update the quantity in Firestore
        await widget.ordersRef.doc(orderID).update({
          'quantity_notSubmitted_notServiced':
              order['quantity_notSubmitted_notServiced']
        });
        setState(() {});
      }
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.ordersRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No orders"));
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
                      final price = snapshot.data!.get('price');
                      final content = snapshot.data!.get('content') as String;
                      return Card(
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(name),
                                subtitle: Text(content),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                deleteAnItem(order, orderID);
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
                              onPressed: () {
                                addItem(order, orderID);
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
                              onPressed: () {
                                deleteAllItems(order, orderID);
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
            stretchThumb: true,
            trackBuilder: (context, currentState) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('Slide to confirm order'),
                ),
              );
            },
            thumbBuilder: (context, currentState) {
              return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: currentState.isPerformingAction
                      ? const Center(
                          child: CircularProgressIndicator(
                          color: Colors.white,
                        ))
                      : const Icon(Icons.chevron_right, color: Colors.white));
            },
            action: confirmOrders,
          ),
          //Text('Slidingg')
          /*
          SlideAction(
            onSubmit: () {
              confirmOrders();
            },
            text: "Slide to confirm order",
            textStyle: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          */
        ),
      ],
    );
  }

  StreamBuilder<QuerySnapshot> confirmedOrdersTab() {
    Map<String, dynamic>? paymentIntent;

    return StreamBuilder<QuerySnapshot>(
      stream: widget.ordersRef.snapshots(),
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

          final quantity = order['quantity_Submitted_notServiced'] +
              order['quantity_Submitted_Serviced'];

          reference.get().then((DocumentSnapshot documentSnapshot) {
            final price = documentSnapshot["price"];
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
                      final price = snapshot.data!.get('price');
                      int quantity = order['quantity_Submitted_notServiced'] +
                          order['quantity_Submitted_Serviced'];
                      final content = snapshot.data!.get('content') as String;
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text(content),
                          trailing: Text(
                            "$price\$ x$quantity",
                          ),
                          leading: order['quantity_Submitted_notServiced'] > 0
                              ? const Icon(
                                  Icons.timer_outlined,
                                  color: Colors.orangeAccent,
                                )
                              : const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
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
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    if (await checkAuthorizedUser()) {
                      var submittedOrdersLength = submittedOrders.length;
                      // ignore: use_build_context_synchronously
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        builder: (BuildContext context) {
                          String option = "";
                          return DraggableScrollableSheet(
                              expand: false,
                              initialChildSize: 0.6,
                              minChildSize: 0.4,
                              maxChildSize: 1,
                              builder:
                                  (BuildContext context, myscrollController) {
                                return SingleChildScrollView(
                                  controller: myscrollController,
                                  child: StatefulBuilder(builder:
                                      (BuildContext context,
                                          StateSetter setState) {
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 24, 24, 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Summary',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 200,
                                            child: ListView.builder(
                                              itemCount: submittedOrdersLength,
                                              itemBuilder: (context, index) {
                                                final order =
                                                    submittedOrders[index];
                                                return FutureBuilder<
                                                    DocumentSnapshot>(
                                                  future: (order['itemRef']
                                                          as DocumentReference)
                                                      .get(),
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    }
                                                    final name = snapshot.data!
                                                        .get('name') as String;
                                                    final price = snapshot.data!
                                                        .get('price');
                                                    final quantity = order[
                                                            'quantity_Submitted_notServiced'] +
                                                        order[
                                                            'quantity_Submitted_Serviced'];
                                                    return ListTile(
                                                      title: Text(name),
                                                      subtitle:
                                                          Text('x $quantity'),
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
                                              paymentOption('card', totalAmount,
                                                  () {
                                                setState(() {
                                                  option = "card";
                                                });
                                              }),
                                              const SizedBox(width: 8),
                                              paymentOption(
                                                  'paypal', totalAmount, () {
                                                setState(() {
                                                  option = "paypal";
                                                });
                                              }),
                                            ],
                                          ),
                                          if (option == "")
                                            Text("Select any payment method!"),
                                          if (option == "card") Text("card"),
                                          if (option == "paypal")
                                            Text("paypal"),
                                        ],
                                      ),
                                    );
                                  }),
                                );
                              });
                        },
                      );
                    }
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

  Future<void> resetTable(totalPrice) async {
    if (await checkAuthorizedUser()) {
      // TODO: Implement payment functionality, now its just for testing.

      final usersRef = FirebaseFirestore.instance.collection('users');
      final restaurantRef = widget.tableRef.parent.parent;

      // Get the list of user IDs from the table.
      final tableSnapshot = await widget.tableRef.get();
      final userIds = List<String>.from(tableSnapshot.get('users'));

      for (final userID in userIds) {
        // Get a reference to the orders collection for this table.
        final tableOrdersRef = widget.tableRef.collection('Orders');

        // Loop through the orders for this table and transfer them to the user's orders collection.
        final tableOrdersSnapshot = await tableOrdersRef.get();

        String completedOrderId = LoginPage.userID + DateTime.now().toString();

        //split "-" because of -admin
        String userId = userID.split("-").first;

        if (!userId.contains("web") && !userId.contains("waiter")) {
          //registered userid add to completed orders then delete order
          await usersRef
              .doc(userId)
              .collection('completedOrders')
              .doc(completedOrderId)
              .set({
            'restaurantRef': restaurantRef,
            'timestamp': Timestamp.now(),
            'items': [],
            'totalPrice': totalPrice,
          });

          for (final orderSnapshot in tableOrdersSnapshot.docs) {
            final orderData = orderSnapshot.data();
            final submittedServiced =
                orderData['quantity_Submitted_Serviced'] as int;
            final submittedNotServiced =
                orderData['quantity_Submitted_notServiced'] as int;
            if (submittedServiced > 0 || submittedNotServiced > 0) {
              await usersRef
                  .doc(userId)
                  .collection('completedOrders')
                  .doc(completedOrderId)
                  .update({
                'items': FieldValue.arrayUnion([orderData])
              });
            }
            await tableOrdersRef
                .doc(orderSnapshot.id)
                .delete(); // Delete from table orders
          }
        } else {
          //unregistered userid just delete order
          for (final orderSnapshot in tableOrdersSnapshot.docs) {
            await tableOrdersRef
                .doc(orderSnapshot.id)
                .delete(); // Delete from table orders
          }
        }
      }

      //reset table users after transferring order data
      await widget.tableRef.update({
        'users': [],
        'newNotification': false,
        'notifications': [],
      });

      // Get the current date for stats
      final currentDate = DateTime.now();
      final currentDay = currentDate.day.toString().padLeft(2, '0');
      final currentMonth = currentDate.month.toString().padLeft(2, '0');
      final currentYear = currentDate.year.toString();

      // Add the total price of the order to the total sales for the current day.
      await restaurantRef!.set({
        'totalSales': {
          currentYear: {
            currentMonth: {
              currentDay: FieldValue.increment(totalPrice),
            },
          },
        },
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
      );
    }
  }

  Expanded paymentOption(
      String option, double totalPrice, void Function() pay) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          pay();
          resetTable(totalPrice);
        },
        child: Text("Pay with $option"),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 150,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            menuButton('Back to HomeScreen', () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerHome()),
                  (route) => false);
            })
          ],
        ),
      ),
    );
  }
}
