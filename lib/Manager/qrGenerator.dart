import 'dart:io';
import 'package:archive/archive.dart';
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

  Future<void> _shareAllQRCodes(List<String> qrCodeDataList, List<int> tableNumberList) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;
      List<String> qrImagePaths = [];

      for (int i = 0; i < qrCodeDataList.length; i++) {
        final qrImageBytes = await QrPainter(
          data: qrCodeDataList[i],
          version: QrVersions.auto,
          gapless: false,
          color: Colors.black,
          emptyColor: Colors.white,
        ).toImageData(300.0);

        final qrImagePath = '$tempPath/qr_code_table_${tableNumberList[i]}.jpg';
        final qrImageFile = File(qrImagePath);
        await qrImageFile.writeAsBytes(qrImageBytes!.buffer.asUint8List());

        qrImagePaths.add(qrImagePath);
      }

      // Now, zip all images to a file.
      final zipEncoder = ZipEncoder();
      final zipFile = File("$tempPath/qr_codes.zip");

      var archive = Archive();

      for (var path in qrImagePaths) {
        final bytes = File(path).readAsBytesSync();
        archive.addFile(ArchiveFile("qr_code_table_${qrImagePaths.indexOf(path)+1}.jpg", bytes.length, bytes));
      }

      final zipData = zipEncoder.encode(archive);
      await zipFile.writeAsBytes(zipData!);

      // Finally, share the zip file.
      await Share.shareFiles([zipFile.path],
          subject: 'Share All QR Codes',
          text: 'Here are the QR codes for all tables.',
          mimeTypes: ['application/zip']);
    } catch (e) {
      //print('Failed to share QR code: $e');
    }
  }


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
        actions:[
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () async {
              List<String> qrCodeDataList = [];
              List<int> tableNumberList = [];

              final tables = await FirebaseFirestore.instance.collection("Restaurants/$selectedRestaurantID/Tables").orderBy("number", descending: false).get();
              for (var table in tables.docs) {
                final tableNumber = table['number'];
                final qrCodeData = "https://restaurantapp-2a43d.web.app/?id=$selectedRestaurantID&tableNo=$tableNumber";

                qrCodeDataList.add(qrCodeData);
                tableNumberList.add(tableNumber);
              }
              await _shareAllQRCodes(qrCodeDataList, tableNumberList);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
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
                                  child: QrImage(
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
          Row(
            children: [
              Expanded(
                flex: 20,
                child: textInputField(
                    context, "Number of tables", tableNumberController, true),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
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
