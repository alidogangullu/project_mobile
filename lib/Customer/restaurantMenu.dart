import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:project_mobile/Customer/customerHome.dart';
import 'package:project_mobile/Customer/order.dart';
import '../customWidgets.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.id, required this.tableNo});

  final String id;
  final String tableNo;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> users = [];

 

  Future<void> listenUnauthorizedUsers() async {
   
    await FirebaseFirestore.instance
        .collection("Restaurants/${widget.id}/Tables")
        .doc(widget.tableNo)
        .get()
        .then((document) async {
      users = document.data()!['users'];

      bool onlyWaiter = users.length == 1 && users.contains("waiter");

      if (users.isEmpty) {
        await FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/Tables")
            .doc(widget.tableNo)
            .update({
          'newNotification': true,
          'notifications': FieldValue.arrayUnion(
              ["A new customer has been seated at Table."]),
        });
      }

      bool isAdmin = users.isEmpty ||
          users.contains("${LoginPage.userID}-admin") ||
          onlyWaiter; // First accessed user is admin

      if (isAdmin) {
        String userId = '${LoginPage.userID}${isAdmin ? '-admin' : ''}';
        await FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/Tables")
            .doc(widget.tableNo)
            .update({
          'users': FieldValue.arrayUnion([userId]),
        });
      } else if (users.contains(LoginPage.userID)) {
      } else {
        await FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/Tables")
            .doc(widget.tableNo)
            .update({
          'unAuthorizedUsers': FieldValue.arrayUnion([LoginPage.userID]),
        });
      }

      if (users.contains("${LoginPage.userID}-admin")) {
        // Listen for changes to the users array
        FirebaseFirestore.instance
            .collection("Restaurants/${widget.id}/Tables")
            .doc(widget.tableNo)
            .snapshots()
            .listen((documentSnapshot) {
          List<dynamic> unAuthorizedUsers =
              documentSnapshot.data()!['unAuthorizedUsers'];
          if (unAuthorizedUsers.isNotEmpty) {
            // New user joined, display popup dialog to admin
            for (var user in unAuthorizedUsers) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('New User Joined'),
                    content: Text('Allow user $user to access menu?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Allow user to access menu
                          Navigator.of(context).pop();
                          FirebaseFirestore.instance
                              .collection("Restaurants/${widget.id}/Tables")
                              .doc(widget.tableNo)
                              .update({
                            'users': FieldValue.arrayUnion([user]),
                            'unAuthorizedUsers': FieldValue.arrayRemove([user]),
                          });
                        },
                        child: const Text('Allow'),
                      ),
                    ],
                  );
                },
              );
            }
          }
          setState(() {}); //when new user access,
          users = documentSnapshot.data()!['users'];
        });
      }
    });
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  String selected = "";
  String _searchQuery = '';
  final searchController = TextEditingController();

  Future<List<QueryDocumentSnapshot>> getItemsForAllCategories(
      List<QueryDocumentSnapshot> categories) async {
    List<QueryDocumentSnapshot> allDocuments = [];
    for (var doc in categories) {
      final items = await FirebaseFirestore.instance
          .collection('Restaurants/${widget.id}/MenuCategory/${doc.id}/list')
          .get();
      allDocuments.addAll(items.docs);
    }
    return allDocuments;
  }

  @override
  void initState() {
    super.initState();
    listenUnauthorizedUsers();
  }

  void sendWaiterRequest() async {
    await FirebaseFirestore.instance
        .collection("Restaurants/${widget.id}/Tables")
        .doc(widget.tableNo)
        .update({
      'newNotification': true,
      'notifications':
          FieldValue.arrayUnion(["A waiter request has been sent."]),
    });
    const snackBar = SnackBar(
      content: Text('A waiter request has been sent.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Send newNotification value to Firebase
          sendWaiterRequest();
        },
        child: const Icon(Icons.notifications),
      ),
      appBar: AppBar(
        actions: [
          ShoppingCartButton(
              userID: LoginPage.userID,
              tableNo: widget.tableNo,
              restaurantID: widget.id),
        ],
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const CustomerHome()));
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: RestaurantNameText(
          id: widget.id,
        ),
      ),
      body: Column(
        children: [
          textInputField(context, "Search Item", searchController, false,
              iconData: Icons.search, onChanged: _onSearchQueryChanged),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 5, 0, 0),
            child: SizedBox(
              height: 30,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("Restaurants/${widget.id}/MenuCategory")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading categories...');
                  }
                  final categories =
                      snapshot.data!.docs.map((doc) => doc.id).toList();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () => setState(() => selected == category
                            ? selected = ''
                            : selected = category),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected == category
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: selected == category
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("Restaurants/${widget.id}/MenuCategory")
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categories = snapshot.data!.docs;
                  return FutureBuilder(
                    future: getItemsForAllCategories(categories),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<QueryDocumentSnapshot>>
                            itemsSnapshot) {
                      if (itemsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = itemsSnapshot.data!;
                      final visibleItems = selected.isEmpty
                          ? items
                          : items
                              .where((item) => item.reference.path.startsWith(
                                  'Restaurants/${widget.id}/MenuCategory/$selected'))
                              .toList();
                      final filteredItems = visibleItems.where((item) {
                        final name = item['name'].toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();
                      return ItemsGrid(
                        documents: filteredItems,
                        collection: "Restaurants/${widget.id}/MenuCategory",
                        id: widget.id,
                        selected: selected,
                        tableNo: widget.tableNo,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemsGrid extends StatefulWidget {
  final List<QueryDocumentSnapshot> documents;
  final String selected;
  final String collection;
  final String id;
  final bool justBrowsing;
  final String? tableNo; // Make tableNo nullable

  const ItemsGrid({
    Key? key,
    required this.documents,
    required this.selected,
    required this.collection,
    required this.id,
    this.tableNo, // Do not require tableNo
    this.justBrowsing = false, // Default to false if not provided
  }) : super(key: key);

  @override
  ItemsGridState createState() => ItemsGridState();
}

class ItemsGridState extends State<ItemsGrid> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.70,
      children: widget.documents.map((document) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              isScrollControlled: true,
              enableDrag: true,
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              builder: (BuildContext context) {
                int selectedQuantity = 1;

                double seconds =
                    double.parse(document['estimatedTime'].toString());
                int minutes = (seconds ~/ 60).toInt();
                double remainingSeconds = seconds % 60;
                String formattedSeconds = remainingSeconds.toStringAsFixed(0);

                return DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.74,
                    minChildSize: 0.4,
                    maxChildSize: 1,
                    builder: (BuildContext context, myscrollController) {
                      return Column(
                        children: [
                          SingleChildScrollView(
                            controller: myscrollController,
                            child: StatefulBuilder(
                              builder: (BuildContext context, setState) {
                                return Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 1.5,
                                        child: Image.network(
                                          document["image_url"],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      20, 20, 15, 10),
                                              child: Text(
                                                document['name'],
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      20, 0, 15, 15),
                                              child: Row(
                                                children: [
                                                  Row(
                                                    children: List.generate(5,
                                                        (index) {
                                                      if (index <
                                                          document["rating"]) {
                                                        return const Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                        );
                                                      } else {
                                                        return const Icon(
                                                          Icons.star_border,
                                                          color: Colors.amber,
                                                        );
                                                      }
                                                    }),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    document["rating"]
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        widget.justBrowsing
                                            ? const SizedBox()
                                            : Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      if (selectedQuantity !=
                                                          1) {
                                                        setState(() {
                                                          selectedQuantity--;
                                                        });
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.remove),
                                                  ),
                                                  Text(selectedQuantity
                                                      .toString()),
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedQuantity++;
                                                      });
                                                    },
                                                    icon: const Icon(Icons.add),
                                                  ),
                                                ],
                                              ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 0, 15, 15),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${document['content']}',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 0, 15, 15),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${document['price']} \$',
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                          if (document['orderCount'] > 5)
                                            Text(
                                              "$minutes min $formattedSeconds sec service time",
                                              style:
                                                  const TextStyle(fontSize: 15),
                                            ),
                                        ],
                                      ),
                                    ),
                                    widget.justBrowsing
                                        ? const SizedBox()
                                        : menuButton("Add to Order List",
                                            () async {
                                            final usersSnapshot =
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        "Restaurants/${widget.id}/Tables")
                                                    .doc(widget.tableNo)
                                                    .get();
                                            final List<dynamic> users =
                                                usersSnapshot.data()!['users'];
                                            if (users.contains(
                                                    LoginPage.userID) ||
                                                users.contains(
                                                    "${LoginPage.userID}-admin")) {
                                              final querySnapshot =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          "Restaurants/${widget.id}/Tables")
                                                      .doc(widget.tableNo)
                                                      .collection("Orders")
                                                      .where("itemRef",
                                                          isEqualTo: document
                                                              .reference)
                                                      .get();
                                              if (querySnapshot.size > 0) {
                                                // Item already exists in order, update its quantity
                                                final orderDoc =
                                                    querySnapshot.docs.first;
                                                final quantity = orderDoc[
                                                        "quantity_notSubmitted_notServiced"] +
                                                    selectedQuantity;
                                                orderDoc.reference.update({
                                                  "quantity_notSubmitted_notServiced":
                                                      quantity
                                                });
                                              } else {
                                                // Item doesn't exist in order, add it with quantity 1
                                                FirebaseFirestore.instance
                                                    .collection(
                                                        "Restaurants/${widget.id}/Tables")
                                                    .doc(widget.tableNo)
                                                    .collection("Orders")
                                                    .doc()
                                                    .set({
                                                  "itemRef": document.reference,
                                                  "quantity_notSubmitted_notServiced":
                                                      selectedQuantity,
                                                  "quantity_Submitted_notServiced":
                                                      0,
                                                  "quantity_Submitted_Serviced":
                                                      0,
                                                  "orderedTime": 0,
                                                });
                                              }
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                    "${document['name']} added to order list, now you can confirm your order!"),
                                              ));
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "You are not authorized to add items to the order list."),
                                                ),
                                              );
                                            }
                                            Navigator.of(context).pop();
                                          }),
                                  ],
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('comments')
                                  .where('itemRef',
                                      isEqualTo: document.reference)
                                  .orderBy('timestamp', descending: true)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return const Text('Something went wrong');
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if(snapshot.data!.size==0){
                                  return const Center(child: Text('There is no comment.'));
                                }

                                return ListView(
                                  shrinkWrap:
                                      true, // uses minimum space of the parent
                                  children: snapshot.data!.docs
                                      .map((DocumentSnapshot commentDoc) {
                                    final timestamp = commentDoc["timestamp"];
                                    final dateTime =
                                        timestamp.toDate().toLocal();
                                    final formattedDate =
                                        "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString()} ${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}";
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 16.0),
                                      padding: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: FutureBuilder<
                                                    DocumentSnapshot>(
                                                  future: FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(commentDoc['userId'])
                                                      .get(),
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot<
                                                              DocumentSnapshot>
                                                          snapshot) {
                                                    if (snapshot.hasError) {
                                                      return const Text('');
                                                    }

                                                    if (!snapshot.hasData ||
                                                        snapshot.data?.data() ==
                                                            null) {
                                                      return const Text(
                                                          'Deleted User');
                                                    }

                                                    final userData = snapshot
                                                            .data!
                                                            .data()!
                                                        as Map<String, dynamic>;

                                                    final imageUrl = userData[
                                                            'profileImageUrl'] ??
                                                        '';
                                                    final name =
                                                        userData['name'] ?? '';

                                                    return Row(
                                                      children: [
                                                        CircleAvatar(
                                                            radius: 20,
                                                            backgroundImage: imageUrl !=
                                                                    ""
                                                                ? NetworkImage(
                                                                    imageUrl)
                                                                : const NetworkImage(
                                                                    'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png')),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          name,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20.0,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Icon(
                                                Icons.star,
                                                color: Colors.amber[700],
                                              ),
                                              const SizedBox(width: 4.0),
                                              Text(
                                                commentDoc['rating'].toString(),
                                                style: const TextStyle(
                                                    fontSize: 18.0),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12.0),
                                          Text(
                                            '${commentDoc['text']}',
                                            style:
                                                const TextStyle(fontSize: 18.0),
                                          ),
                                          const SizedBox(height: 12.0),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    });
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: Image.network(
                      document["image_url"],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      document['name'],
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document["rating"].toString(),
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    child: Text(
                      "\$ ${document['price']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ShoppingCartButton extends StatelessWidget {
  const ShoppingCartButton({
    super.key,
    required this.restaurantID,
    required this.tableNo,
    required this.userID,
  });

  final String restaurantID;
  final String tableNo;
  final String userID;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: FirebaseFirestore.instance
          .collection("Restaurants/$restaurantID/Tables")
          .doc(tableNo)
          .snapshots()
          .map<List<dynamic>>((snapshot) => snapshot.data()!['users']),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final isAdmin = users.contains("$userID-admin");
        final currentUserIsAuthorized = users.contains(userID) || isAdmin;
        return IconButton(
          onPressed: currentUserIsAuthorized
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrdersPage(
                        ordersRef: FirebaseFirestore.instance
                            .collection("Restaurants/$restaurantID/Tables")
                            .doc(tableNo)
                            .collection("Orders"),
                        tableRef: FirebaseFirestore.instance
                            .collection("Restaurants/$restaurantID/Tables")
                            .doc(tableNo),
                        table: tableNo,
                        restaurantPath: "Restaurants/$restaurantID",
                      ),
                    ),
                  );
                }
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Unauthorized User'),
                      content: const Text(
                          'You are not authorized to access orders.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
          icon: const Icon(Icons.shopping_cart),
        );
      },
    );
  }
}

class RestaurantNameText extends StatelessWidget {
  const RestaurantNameText({Key? key, required this.id}) : super(key: key);
  final String id;

  //restorant id'sinden restorant ismini Text Widget olarak döndürme

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection("Restaurants").doc(id).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data!['name'],
            style: const TextStyle(
              color: Colors.black,
            ),
          );
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        return const Text("Loading...");
      },
    );
  }
}

//restaurant menu for just browsing

class MenuBrowseScreen extends StatefulWidget {
  final String id;

  const MenuBrowseScreen({super.key, required this.id});

  @override
  State<MenuBrowseScreen> createState() => _MenuBrowseScreenState();
}

class _MenuBrowseScreenState extends State<MenuBrowseScreen> {
  String selected = "";
  String _searchQuery = '';
  final searchController = TextEditingController();

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Future<List<QueryDocumentSnapshot>> getItemsForAllCategories(
      List<QueryDocumentSnapshot> categories) async {
    List<QueryDocumentSnapshot> allDocuments = [];
    for (var doc in categories) {
      final items = await FirebaseFirestore.instance
          .collection('Restaurants/${widget.id}/MenuCategory/${doc.id}/list')
          .get();
      allDocuments.addAll(items.docs);
    }
    return allDocuments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerHome()));
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: RestaurantNameText(
          id: widget.id,
        ),
      ),
      body: Column(
        children: [
          textInputField(context, "Search Item", searchController, false,
              iconData: Icons.search, onChanged: _onSearchQueryChanged),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 5, 0, 0),
            child: SizedBox(
              height: 30,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("Restaurants/${widget.id}/MenuCategory")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading categories...');
                  }
                  final categories =
                      snapshot.data!.docs.map((doc) => doc.id).toList();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () => setState(() => selected == category
                            ? selected = ''
                            : selected = category),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected == category
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: selected == category
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("Restaurants/${widget.id}/MenuCategory")
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categories = snapshot.data!.docs;
                  return FutureBuilder(
                    future: getItemsForAllCategories(categories),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<QueryDocumentSnapshot>>
                            itemsSnapshot) {
                      if (itemsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = itemsSnapshot.data!;
                      final visibleItems = selected.isEmpty
                          ? items
                          : items
                              .where((item) => item.reference.path.startsWith(
                                  'Restaurants/${widget.id}/MenuCategory/$selected'))
                              .toList();
                      final filteredItems = visibleItems.where((item) {
                        final name = item['name'].toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();
                      return ItemsGrid(
                        documents: filteredItems,
                        collection: "Restaurants/${widget.id}/MenuCategory",
                        id: widget.id,
                        selected: selected,
                        justBrowsing: true,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
