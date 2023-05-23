import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
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
        title: const Text(
          "Create QR Code",
          style: TextStyle(color: Colors.black),
        ),
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
                        final qrCodeData =
                            "https://restaurantapp-2a43d.web.app/?id=$selectedRestaurantID&tableNo=${document['number']}";
                        //restorant masalarının qr kodlarını listeleme
                        return ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: QrImageView(
                                        version: QrVersions.auto,
                                        data: qrCodeData),
                                  ),
                                  Text(
                                    "Table ${document['number']}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 25,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await _shareQRCode(
                                            qrCodeData, document['number']);
                                      },
                                      child: const Text('Export QR Code'),
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
                    int numberOfTables = int.parse(tableNumberController.text);
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
                          'notifications': FieldValue.arrayUnion([]),
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

Future<void> _shareQRCode(String qrCodeData, int tableNumber) async {
  try {
    final qrImageBytes = await QrPainter(
      data: qrCodeData,
      version: QrVersions.auto,
      gapless: false,
      color: Colors.black,
      emptyColor: Colors.white,
    ).toImageData(300.0);

    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    final qrImagePath = '$tempPath/qr_code_table_$tableNumber.png';

    final qrImageFile = File(qrImagePath);
    await qrImageFile.writeAsBytes(qrImageBytes!.buffer.asUint8List());

    await Share.shareFiles([qrImagePath],
        subject: 'Share QR Code',
        text: 'Here is the QR code for Table $tableNumber.',
        mimeTypes: ['image/png']);
  } catch (e) {
    //print('Failed to share QR code: $e');
  }
}
