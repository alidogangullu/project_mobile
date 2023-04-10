import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:project_mobile/Authentication/loginPage.dart';

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
        stream: FirebaseFirestore.instance
            .collection('/users/$customerId/completedOrders')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              final order = snapshot.data!.docs[index];
              final items = order.get('items') as List<dynamic>;
              final restaurantRef =
                  order.get('restaurantRef') as DocumentReference;
              return FutureBuilder<DocumentSnapshot>(
                future: restaurantRef.get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  final restaurantName = snapshot.data!.get('name') as String;
                  final timestamp = order["timestamp"];
                  final dateTime = timestamp.toDate().toLocal();
                  final formattedDate =
                      "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()} ${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}";

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
                              final itemRef =
                                  items[index]['itemRef'] as DocumentReference;
                              return FutureBuilder<DocumentSnapshot>(
                                future: itemRef.get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  if (!snapshot.hasData) {
                                    return const SizedBox();
                                  }
                                  final itemName =
                                      snapshot.data!.get('name') as String;
                                  return Text('- $itemName');
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
                          const Text(
                              "250\$"), //test için eklendi databaseden çekilecek
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OrderDetailsPage(
                                          orderRef: order.reference,
                                        )),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ));
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
  final DocumentReference orderRef;

  const OrderDetailsPage({Key? key, required this.orderRef}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final Map<DocumentReference, TextEditingController> _commentControllers = {};
  final Map<DocumentReference, double> _itemRating = {};
  final Map<DocumentReference, bool> _showCommentSection = {};
  final Map<DocumentReference, bool> _feedbackChanged = {};

  Future<void> _loadPreviousComment(DocumentReference itemRef,
      TextEditingController commentController, double itemRating, bool isChanged) async {
    final previousFeedbackSnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('userId', isEqualTo: LoginPage.userID)
        .where('itemRef', isEqualTo: itemRef)
        .limit(1)
        .get();
    if (previousFeedbackSnapshot.size > 0) {
      // If the user has a previous comment, set the initial value of the comment text field to the previous comment text
      final previousFeedback = previousFeedbackSnapshot.docs[0];
      final previousCommentText = previousFeedback.get('text');
      final previousRating = previousFeedback.get('rating');

      if (commentController.text.isEmpty && !isChanged) {
        setState(() {
          commentController.text = previousCommentText;
        });
      }

      _itemRating[itemRef] = previousRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Feedback'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: widget.orderRef.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderData = snapshot.data!;
          final items = orderData.get('items') as List<dynamic>;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final itemData = items[index];
              final itemRef = itemData['itemRef'] as DocumentReference;
              final commentController =
                  _commentControllers[itemRef] ?? TextEditingController();
              _commentControllers[itemRef] = commentController;

              final showCommentSection =
                  _showCommentSection[itemRef] ?? false;
              _showCommentSection[itemRef] = showCommentSection;

              final bool isChanged =
                  _feedbackChanged[itemRef] ?? false;

              final double itemRating =
                  _itemRating[itemRef] ?? 3;

              _loadPreviousComment(itemRef, commentController, itemRating, isChanged);


              return FutureBuilder<DocumentSnapshot>(
                future: itemRef.get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  final itemData = snapshot.data!;
                  final itemName = itemData.get('name') as String;
                  //final itemPrice = itemData.get('price') as int;
                  //final imageUrl = itemData.get('imageUrl') as String;

                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(itemName),
                          leading: const Image(
                              image: NetworkImage(
                                  "https://cdn-icons-png.flaticon.com/512/2771/2771401.png")),
                          subtitle: Text('${10} \$'),
                          trailing: IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () {
                              setState(() {
                                _showCommentSection[itemRef] =
                                    !_showCommentSection[itemRef]!;
                              });
                            },
                          ),
                        ),
                        RatingBar.builder(
                          glowColor: Colors.amber,
                          glowRadius: 0.5,
                          initialRating: itemRating,
                          minRating: 0,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _showCommentSection[itemRef] = true;
                              _feedbackChanged[itemRef] = true;
                              _itemRating[itemRef] = rating;
                            });
                          },
                        ),
                        if (showCommentSection)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (commentController.text.isNotEmpty && !isChanged)
                                  const Text(
                                    'You previously left this comment:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                TextField(
                                  onChanged: (value){
                                      setState(() {
                                      _feedbackChanged[itemRef] = true;
                                    });
                                  },
                                  controller: commentController,
                                  decoration: const InputDecoration(
                                      hintText: 'Type your comment here'),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        setState(() {
                                          _showCommentSection[itemRef] = false;
                                        });
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Save',style: TextStyle(
                                        color: isChanged ? Colors.green : Colors.blue,
                                      ),),
                                      onPressed: () async {
                                        final commentText = commentController.text.trim();
                                        final commentQuerySnapshot = await FirebaseFirestore.instance
                                            .collection('comments')
                                            .where('userId', isEqualTo: LoginPage.userID)
                                            .where('itemRef', isEqualTo: itemRef)
                                            .limit(1)
                                            .get();
                                        if (commentQuerySnapshot.size > 0) {
                                          // Update the existing comment
                                          final commentRef = commentQuerySnapshot.docs[0].reference;
                                          await commentRef.set({
                                            'rating': itemRating,
                                            'text': commentText,
                                            'timestamp': FieldValue.serverTimestamp(),
                                          }, SetOptions(merge: true));
                                        } else {
                                          // Save a new comment
                                          final commentRef = FirebaseFirestore.instance.collection('comments').doc();
                                          await commentRef.set({
                                            'rating': itemRating,
                                            'text': commentText,
                                            'timestamp': FieldValue.serverTimestamp(),
                                            'itemRef': itemRef,
                                            'userId': LoginPage.userID,
                                          });
                                        }
                                        setState(() {
                                          _showCommentSection[itemRef] = false;
                                          _feedbackChanged[itemRef] = false;
                                          _itemRating[itemRef] = itemRating;
                                        });
                                      },

                                    ),
                                  ],
                                ),
                              ],
                            ),
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
    );
  }
}
