import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Admin/menuEdit.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../customWidgets.dart';

class QRHomePage extends StatelessWidget {
  QRHomePage({Key? key, required this.selectedRestaurantID}) : super(key: key);

  final tableNumberController = TextEditingController();
  final String selectedRestaurantID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Create QR Code", style: TextStyle(color: Colors.black),),
        actions: const [
          //todo pdf vb. yöntemler ile qr kodunu dışarı verdirtme
          Icon(Icons.picture_as_pdf),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Restaurants/$selectedRestaurantID/Tables")
                    .orderBy("number", descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    return GridView(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      primary: false,
                      shrinkWrap: true,
                      children: snapshot.data!.docs.map((document) {
                        //restorant masalarının qr kodlarını listeleme
                        return ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: QrImage(
                                      version: QrVersions.auto,
                                      data:
                                          //qr kodun içeriği
                                          "https://restaurantapp-2a43d.web.app/?id=$selectedRestaurantID&tableNo=${document['number']}"),
                                ),
                                Text(
                                  "Table ${document['number']}",
                                  style: const TextStyle(fontSize: 18,),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 20,
                child: textInputField(
                    context, "Number of tables", tableNumberController, true),
              ),
              Expanded(
                flex: 10,
                child: menuButton(
                  'Save',
                  () async {
                    int numberOfTables =
                        int.parse(tableNumberController.text);
                    final ref = FirebaseFirestore.instance.collection(
                        "/Restaurants/$selectedRestaurantID/Tables");

                    var snapshots = await ref.get();

                    for (int i = numberOfTables; i > 0; i--) {
                      if (!snapshots.docs.contains("$i")) {
                        ref.doc("$i").set({
                          "number": i,
                          "newNotification": false,
                          'users': FieldValue.arrayUnion([]),
                          'unAuthorizedUsers': FieldValue.arrayUnion([]),
                        });
                      }
                    }
                    if (snapshots.docs.length > numberOfTables) {
                      for (int i = snapshots.docs.length;
                          i > numberOfTables;
                          i--) {
                        ref.doc("$i").delete();
                      }
                    }
                    tableNumberController.clear();
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
