import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_mobile/Admin/menuEdit.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QR_HomePage extends StatelessWidget {
  QR_HomePage({Key? key, required this.selectedRestaurant}) : super(key: key);

  final tableNumberController = new TextEditingController();
  final String selectedRestaurant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create QR Code"),
        actions: const [Icon(Icons.picture_as_pdf)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("/Restaurants/$selectedRestaurant/Tables")
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
                      return Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: QrImage(
                                  version: QrVersions.auto,
                                  data:
                                      "https://restaurantapp-2a43d.web.app/?para1=$selectedRestaurant&para2=${document['number']}"),
                            ),
                            Text(
                              "Table ${document['number']}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  flex: 25,
                  child: inputField(Icon(Icons.table_restaurant),
                      "Number of tables", tableNumberController, true),
                ),
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                    child: MenuButton('', Icon(Icons.done), () {
                      int numberOfTables =
                          int.parse(tableNumberController.text);
                      final ref = FirebaseFirestore.instance.collection(
                          "/Restaurants/$selectedRestaurant/Tables");
                      for (int i = numberOfTables; i > 0; i--) {
                        ref.doc("$i").set({
                          "number": i,
                          "isActive": true,
                        });
                      }
                      tableNumberController.clear();
                    }),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
