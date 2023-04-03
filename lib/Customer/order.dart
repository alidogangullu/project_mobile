import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key, required this.ordersRef}) : super(key: key);

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
    widget.ordersRef.where('quantity_notSubmitted_notServiced', isNotEqualTo: 0)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        // If there are not new orders, navigate to the second tab
        _tabController.animateTo(1);
      }
    });
  }

  void updateOrders() async {

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
            Tab(icon: Icon(Icons.playlist_add), text: "Unconfirmed Orders",),
            Tab(icon: Icon(Icons.playlist_add_check), text: "Confirmed Orders",)
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          notSubmittedOrders(),
          submittedOrders(),
        ],
      ),
    );
  }

  Expanded submittedOrders() {
    return Expanded(
          flex: 10,
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
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: submittedOrders.length,
                      itemBuilder: (context, index) {
                        final order = submittedOrders[index].data()
                        as Map<String, dynamic>;
                        final reference =
                        order['itemRef'] as DocumentReference;
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
                                subtitle: Text('Quantity: $quantity'),
                                trailing: Text(
                                    "99\$"), // todo price information for menu items
                                leading: order['quantity_Submitted_notServiced'] > 0
                                    ? const Icon(Icons.timer_outlined) : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),

        );
  }

  Column notSubmittedOrders() {
    return Column(
          children: [
            Expanded(
              flex: 10,
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
                      final order =
                          orders[index].data() as Map<String, dynamic>;
                      final reference = order['itemRef'] as DocumentReference;
                      final item = reference.get();
                      return FutureBuilder<DocumentSnapshot>(
                        future: item,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }
                          final name = snapshot.data!.get('name') as String;
                          return Card(
                            child: ListTile(
                              title: Text(name),
                              subtitle: Text(
                                  'Quantity: ${order['quantity_notSubmitted_notServiced']}'),
                              trailing: Text(
                                  "99\$"), //todo price information for menu items
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
              padding: const EdgeInsets.all(25),
              child: SlideAction(
                onSubmit: () {
                  updateOrders();
                },
                text: "Slide to order",
                textStyle: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        );
  }
}
