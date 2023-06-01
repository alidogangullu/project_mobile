import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:project_mobile/Authentication/loginPage.dart';

enum SortBy {
  priceAscending,
  priceDescending,
  timeAscending,
  timeDescending,
}

class OrderWithPrice {
  final QueryDocumentSnapshot order;
  final double totalPrice;

  OrderWithPrice({required this.order, required this.totalPrice});
}

class RecentOrdersScreen extends StatefulWidget {
  final String customerId;

  const RecentOrdersScreen({Key? key, required this.customerId})
      : super(key: key);

  @override
  State<RecentOrdersScreen> createState() => _RecentOrdersScreenState();
}

class _RecentOrdersScreenState extends State<RecentOrdersScreen> {
  SortBy _sortBy = SortBy.timeDescending;

  Future<List<OrderWithPrice>> _sortOrders(
    List<QueryDocumentSnapshot> orders,
    SortBy sortBy,
  ) async {
    List<OrderWithPrice> sortedOrdersWithPrice = [];

    for (var order in orders) {
      double totalPrice = order.get('totalPrice').toDouble();
      sortedOrdersWithPrice
          .add(OrderWithPrice(order: order, totalPrice: totalPrice));
    }

    switch (sortBy) {
      case SortBy.priceAscending:
        sortedOrdersWithPrice
            .sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      case SortBy.priceDescending:
        sortedOrdersWithPrice
            .sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      case SortBy.timeAscending:
        sortedOrdersWithPrice.sort((a, b) => a.order
            .get('timestamp')
            .toDate()
            .compareTo(b.order.get('timestamp').toDate()));
        break;
      case SortBy.timeDescending:
        sortedOrdersWithPrice.sort((a, b) => b.order
            .get('timestamp')
            .toDate()
            .compareTo(a.order.get('timestamp').toDate()));
        break;
    }

    return sortedOrdersWithPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Price (Low to High)'),
                        onTap: () {
                          setState(() {
                            _sortBy = SortBy.priceAscending;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Price (High to Low)'),
                        onTap: () {
                          setState(() {
                            _sortBy = SortBy.priceDescending;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Time (Oldest First)'),
                        onTap: () {
                          setState(() {
                            _sortBy = SortBy.timeAscending;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Time (Newest First)'),
                        onTap: () {
                          setState(() {
                            _sortBy = SortBy.timeDescending;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.sort, color: Colors.black),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Recent',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            height: 1.5,
          ),
        ),
      ),
      body: StreamBuilder<List<OrderWithPrice>>(
        stream: FirebaseFirestore.instance
            .collection('/users/${widget.customerId}/completedOrders')
            .snapshots()
            .asyncMap((snapshot) => _sortOrders(snapshot.docs, _sortBy)),
        builder: (BuildContext context,
            AsyncSnapshot<List<OrderWithPrice>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              final orderWithPrice = snapshot.data![index];
              final order = orderWithPrice.order;
              final totalPrice = orderWithPrice.totalPrice;
              final items = order.get('items') as List<dynamic>;
              final restaurantRef =
                  order.get('restaurantRef') as DocumentReference;
              return FutureBuilder<DocumentSnapshot>(
                future: restaurantRef.get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (!snapshot.hasData || snapshot.hasError) {
                    return const SizedBox();
                  }
                  final restaurantName = snapshot.data!.get('name') as String;
                  final restaurantImageUrl =
                      snapshot.data!.get('image_url') as String;
                  final timestamp = order["timestamp"];
                  final dateTime = timestamp.toDate().toLocal();
                  final formattedDate =
                      "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()} ${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}";
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: restaurantImageUrl,
                            width: 85,
                            height: 85,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          )),
                      title: Text(restaurantName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length > 2 ? 3 : items.length,
                              itemBuilder: (BuildContext context, int index) {
                                if (index == 2 && items.length > 2) {
                                  return const Text('...');
                                }
                                final itemRef = items[index]['itemRef']
                                    as DocumentReference;
                                return FutureBuilder<DocumentSnapshot>(
                                  future: itemRef.get(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<DocumentSnapshot>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox();
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.data!.exists) {
                                      return const Text('- Deleted Item');
                                    }
                                    final itemName =
                                        snapshot.data!.get('name') as String;
                                    return Text('- $itemName');
                                  },
                                );
                              },
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("${totalPrice.toStringAsFixed(2)}\$"),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsPage(
                                      orderRef: order.reference,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
      TextEditingController commentController, double itemRating) async {
    final previousFeedbackSnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('userId', isEqualTo: LoginPage.userID)
        .where('itemRef', isEqualTo: itemRef)
        .limit(1)
        .get();
    if (previousFeedbackSnapshot.size > 0) {
      final previousFeedback = previousFeedbackSnapshot.docs[0];
      final previousCommentText = previousFeedback.get('text');
      final previousRating = previousFeedback.get('rating');

      if(_feedbackChanged[itemRef] == true){

      }
      else {
        setState(() {
          if (commentController.text.isEmpty) {
            commentController.text = previousCommentText;
          }

          _itemRating[itemRef] = previousRating;
        });
      }
    }
  }

  Future<void> _updateItemRatingAndCount(
      DocumentReference itemRef, double newRating) async {
    final itemSnapshot = await itemRef.get();
    double currentAvgRating =
        double.parse(itemSnapshot['rating'].toString()) ?? 0.0;
    int currentRatingCount = itemSnapshot['ratingCount'] ?? 0;

    // Check if the user has previously rated
    final previousFeedbackSnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('userId', isEqualTo: LoginPage.userID)
        .where('itemRef', isEqualTo: itemRef)
        .limit(1)
        .get();
    bool hasPreviouslyRated = previousFeedbackSnapshot.size > 0;

    if (hasPreviouslyRated) {
      // User has previously rated, update the average rating
      final previousFeedback = previousFeedbackSnapshot.docs[0];
      double userOldRating = previousFeedback.get('rating').toDouble();
      double updatedAvgRating = (currentAvgRating * currentRatingCount) -
          userOldRating +
          newRating / currentRatingCount;

      await itemRef.update({
        'rating': updatedAvgRating,
      });
    } else {
      // User's first rating, set the average rating and increment rating count

      //items first rating
      if (currentRatingCount == 0) {
        currentRatingCount++;
        double updatedAvgRating = newRating / currentRatingCount;
        await itemRef.update({
          'rating': updatedAvgRating,
          'ratingCount': 1,
        });
      } else {
        double updatedAvgRating =
            (currentAvgRating * currentRatingCount + newRating) /
                (currentRatingCount + 1);
        await itemRef.update({
          'rating': updatedAvgRating,
          'ratingCount': currentRatingCount + 1,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Give Feedback',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            height: 1.5,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: widget.orderRef.get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.data!.exists) {
            return const SizedBox();
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

              final showCommentSection = _showCommentSection[itemRef] ?? false;
              _showCommentSection[itemRef] = showCommentSection;

              final double itemRating = _itemRating[itemRef] ?? 0;

              _loadPreviousComment(itemRef, commentController, itemRating);

              return FutureBuilder<DocumentSnapshot>(
                future: itemRef.get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.data!.exists) {
                    return const SizedBox();
                  }
                  final itemData = snapshot.data!;
                  final itemName = itemData.get('name') as String;
                  final itemPrice = itemData.get('price');
                  final imageUrl = itemData.get('image_url') as String;

                  return Card(
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              )),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(itemName),
                                subtitle: Text('$itemPrice\$'),
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
                                itemPadding:
                                    const EdgeInsets.fromLTRB(0, 0, 0, 5),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (commentController.text.isNotEmpty)
                                        const Text(
                                          'You previously left this comment:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      TextField(
                                        controller: commentController,
                                        decoration: const InputDecoration(
                                            hintText: 'Type your comment here'),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          TextButton(
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Color(0xFFC57B57),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _showCommentSection[itemRef] =
                                                    false;
                                              });
                                            },
                                          ),
                                          TextButton(
                                            child: const Text(
                                              'Save',
                                            ),
                                            onPressed: () async {
                                              // Update the item rating and count
                                              await _updateItemRatingAndCount(
                                                  itemRef, itemRating);

                                              final commentText =
                                                  commentController.text.trim();
                                              final commentQuerySnapshot =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('comments')
                                                      .where('userId',
                                                          isEqualTo:
                                                              LoginPage.userID)
                                                      .where('itemRef',
                                                          isEqualTo: itemRef)
                                                      .limit(1)
                                                      .get();
                                              if (commentQuerySnapshot.size >
                                                  0) {
                                                // Update the existing comment
                                                final commentRef =
                                                    commentQuerySnapshot
                                                        .docs[0].reference;
                                                await commentRef.set({
                                                  'rating': itemRating,
                                                  'text': commentText,
                                                  'timestamp': FieldValue
                                                      .serverTimestamp(),
                                                }, SetOptions(merge: true));
                                              } else {
                                                // Save a new comment
                                                final commentRef =
                                                    FirebaseFirestore.instance
                                                        .collection('comments')
                                                        .doc();
                                                await commentRef.set({
                                                  'rating': itemRating,
                                                  'text': commentText,
                                                  'timestamp': FieldValue
                                                      .serverTimestamp(),
                                                  'itemRef': itemRef,
                                                  'userId': LoginPage.userID,
                                                });
                                              }

                                              setState(() {
                                                _showCommentSection[itemRef] =
                                                    false;
                                                _feedbackChanged[itemRef] =
                                                    false;
                                                _itemRating[itemRef] =
                                                    itemRating;
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
