import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:project_mobile/Customer/restaurantMenu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_device/safe_device.dart';
import 'package:android_flutter_wifi/android_flutter_wifi.dart';

import 'customerHome.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override
  QRScannerState createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> {
  final MobileScannerController qrScannerController = MobileScannerController();
  bool scanned = false;
  double desiredLatitude = 0;
  double desiredLongitude = 0;
  String restaurantWifi = "";
  bool nearbyWiFi = false;

  final Location _location = Location();
  bool _locationEnabled = false;
  LocationData? _locationData;

  Future<void> checkLocationEnabled() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
    _locationEnabled = true;

    _location.onLocationChanged.listen((LocationData? locationData) {
      _locationData = locationData;
    });
  }

  Future<bool> checkWifi() async {
    List<WifiNetwork> wifiList = await AndroidFlutterWifi.getWifiScanResult();

    // Check if wifi is available
    bool restaurantWifiAvailable =
        wifiList.any((wifiNetwork) => wifiNetwork.ssid == restaurantWifi);

    return restaurantWifiAvailable;
  }

  bool isLocationEnabled() {
    return _locationEnabled;
  }

  LocationData? getLocationData() {
    return _locationData;
  }

  static bool isDesiredLocation(LocationData? locationData,
      double desiredLatitude, double desiredLongitude) {
    double maxDistanceMeters = 999999999999; //Erisilebilir mesafe

    if (locationData == null) {
      return false;
    }

    double distanceInMeters = Geolocator.distanceBetween(
      desiredLatitude,
      desiredLongitude,
      locationData.latitude!,
      locationData.longitude!,
    );
    return distanceInMeters <= maxDistanceMeters;
  }

  Future<void> _fetchSecurityData(String restaurantId) async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection("Restaurants")
        .doc(restaurantId) // replace with your restaurantId variable
        .get();
    if (documentSnapshot.exists) {
      desiredLatitude = documentSnapshot["location"][0];
      desiredLongitude = documentSnapshot["location"][1];
      restaurantWifi = documentSnapshot["restaurantWiFi"];

      if (restaurantWifi == "") {
        nearbyWiFi = true;
      } else {
        nearbyWiFi = await checkWifi();
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Could not retrieve location data!"),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    checkLocationEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerHome()));
          },
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "QR Scanner",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Builder(
        builder: (context) {
          return MobileScanner(
            onDetect: (capture) async {
              if (capture.barcodes.first.rawValue!.contains("2a43d") &&
                  !scanned) {
                //"2a43d" url'de var, birden fazla navigator işlemi olmaması için kontrolde kullanılabilir. daha sonra değiştirilebilinir.

                scanned = true;

                //alakalı olmayan qr kodların silinmesi
                for (var element in capture.barcodes) {
                  if (!element.rawValue!.contains("2a43d")) {
                    capture.barcodes.remove(element);
                  }
                }

                bool isSafeDevice = await SafeDevice.isSafeDevice;

                if (isSafeDevice) {
                  //okunan ilk uygun formatlı değere sahip qr koddan parametrelerin alınması
                  String? url = capture.barcodes.first.rawValue;
                  Uri uri = Uri.parse(url!);
                  String restaurantId = uri.queryParameters['id']!;
                  String tableNo = uri.queryParameters['tableNo']!;

                  await _fetchSecurityData(restaurantId);

                  if (nearbyWiFi) {
                    //parametreleri kullanarak yönlendirme ve security check
                    if (isLocationEnabled() &&
                        isDesiredLocation(getLocationData(), desiredLatitude,
                            desiredLongitude)) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuScreen(
                            id: restaurantId,
                            tableNo: tableNo,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "You have to be at the restaurant to access the menu!"),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Unable to verify your location. Please activate your WiFi to access the menu!"),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "You have to use real location and real device without unauthorized software modifications!"),
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}
