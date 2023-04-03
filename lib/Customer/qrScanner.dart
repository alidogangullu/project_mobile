import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';

class QRScanner extends StatelessWidget {
  QRScanner({Key? key}) : super(key: key);

  final MobileScannerController qrScannerController = MobileScannerController();
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Builder(
        builder: (context) {
          return MobileScanner(
            onDetect: (capture) {
              if(capture.barcodes.first.rawValue!.contains("2a43d") && !scanned){
                //"2a43d" url'de var, birden fazla navigator işlemi olmaması için kontrolde kullanılabilir. daha sonra değiştirilebilinir.

                scanned = true;

                //alakalı olmayan qr kodların silinmesi
                for (var element in capture.barcodes) {
                  if(!element.rawValue!.contains("2a43d"))
                  {
                    capture.barcodes.remove(element);
                  }
                }

                //okunan ilk uygun formatlı değere sahip qr koddan parametrelerin alınması
                String? url = capture.barcodes.first.rawValue;
                Uri uri = Uri.parse(url!);
                String id = uri.queryParameters['id']!;
                String tableNo = uri.queryParameters['tableNo']!;

                //parametreleri kullanarak yönlendirme
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuScreen(
                      id: id,
                      tableNo: tableNo,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}