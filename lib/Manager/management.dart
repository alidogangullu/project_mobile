import 'dart:io';
import 'dart:typed_data';
import 'package:android_flutter_wifi/android_flutter_wifi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:project_mobile/Manager/restaurantProfile.dart';
import '../customWidgets.dart';

class ManagerPanel extends StatefulWidget {
  const ManagerPanel({Key? key}) : super(key: key);

  @override
  State<ManagerPanel> createState() => _ManagerPanelState();
}

class _ManagerPanelState extends State<ManagerPanel> {
  String _searchQuery = '';
  TextEditingController searchRestaurantController = TextEditingController();

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Restaurants",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRestaurant(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          textInputField(
              context, "Search Restaurant", searchRestaurantController, false,
              iconData: Icons.search, onChanged: _onSearchQueryChanged),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Restaurants")
                    .where('managers', arrayContains: LoginPage.userID)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final name = doc["name"].toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();
                  return GridView.count(
                    crossAxisCount: 1,
                    childAspectRatio: 1.075,
                    //manager olunan restorantların listelenmesi
                    children: filteredDocs
                        .map(
                          (doc) => GestureDetector(
                            onTap: () {
                              /* old navigation
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditRestaurant(
                                    collection:
                                    "Restaurants/${doc.id}/MenuCategory",
                                    restaurantName: doc["name"],
                                    restaurantID: doc.id,
                                  ),
                                ),
                              );
                              */
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RestaurantProfile(
                                          restaurantAddress: doc['address'],
                                          restaurantID: doc.id,
                                          restaurantName: doc['name'],
                                          restaurantFollowersCount:
                                              doc['followerCount'],
                                          restaurantPostsCount:
                                              doc['postCount'],
                                          restaurantImageUrl: doc['image_url'],
                                        )),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 2,
                                      child: CachedNetworkImage(
                                        imageUrl: doc["image_url"],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Text(
                                        doc["name"],
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 0, 15, 15),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            doc["rating"].toString(),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 0, 15, 15),
                                      child: Text(
                                        doc['address'],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
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

class AddRestaurant extends StatefulWidget {
  const AddRestaurant({Key? key}) : super(key: key);

  @override
  State<AddRestaurant> createState() => _AddRestaurantState();
}

class _AddRestaurantState extends State<AddRestaurant> {
  final restaurantNameController = TextEditingController();
  List<TextEditingController> managerPhoneControllers = [
    TextEditingController()
  ];

  String address = "null";
  double latitude = 0;
  double longitude = 0;

  final picker = ImagePicker();
  File? _imageFile;

  Future<Uint8List?> compressFile(File file) async {
    var result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 25,
    );
    return result;
  }

  Future<String?> uploadImageToFirebaseStorage(File imageFile) async {
    Uint8List? imageBytes = await compressFile(imageFile);

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref =
        storage.ref().child("RestaurantProfileImages/${restaurantNameController.text.replaceAll(" ", "")}"
            "-${DateTime.now().millisecondsSinceEpoch}");

    TaskSnapshot snapshot = await ref.putData(imageBytes!);
    return snapshot.ref.getDownloadURL();
  }

  Future<String?> getUserIdFromPhoneNumber(String phoneNumber) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phoneNumber)
        .get();

    if (snapshot.size > 0) {
      DocumentSnapshot document = snapshot.docs[0];
      return document.id;
    } else {
      return null;
    }
  }

  String? dropdownValue;
  List<String?> ssidList = [];
  Future<void> initPlatformState() async {
    List<WifiNetwork> wifiList = await AndroidFlutterWifi.getWifiScanResult();
    setState(() {
      ssidList.add("");
      ssidList = wifiList.map((wifi) => wifi.ssid).toList();
    });
  }

  @override
  void initState() {
    initPlatformState();
    super.initState();
  }

  bool get canAddRestaurant {
    return restaurantNameController.text.isNotEmpty &&
        address != "null" &&
        _imageFile != null;
  }

  bool loading = false;
  bool showInformation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Add New Restaurant",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Restaurant Name',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          textInputField(
              context, 'Restaurant Name', restaurantNameController, false),
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Restaurant Wi-Fi',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {
                    setState(() {
                      showInformation = !showInformation;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      underline: const SizedBox(),
                      isExpanded: true,
                      iconEnabledColor: Theme.of(context).primaryColor,
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue;
                          showInformation = false;
                        });
                      },
                      items: ssidList
                          .asMap()
                          .entries
                          .map<DropdownMenuItem<String>>((entry) {
                        var index = entry.key;
                        var value = entry.value;
                        return DropdownMenuItem<String>(
                          value: '$index-$value',
                          child: Text(value!),
                        );
                      }).toList(),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ),
                  if (showInformation)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'This dropdown allows you to select the Wi-Fi network for the restaurant. '
                        'Providing this information is optional but recommended for security reasons, '
                        'you can select a blank if you do not want.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 10),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Restaurant Location',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          //google map api: AIzaSyALegH2yH-If8_Gkshob13fKzdHjQ4oxuc
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: Container(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.95,  // adjust the width as needed
                              height: MediaQuery.of(context).size.height * 0.95,  // adjust the height as needed
                              child: OpenStreetMapSearchAndPick(
                                  center: LatLong(38.423733, 27.142826),
                                  buttonColor: Colors.blue,
                                  buttonText: 'Set Restaurant Location',
                                  onPicked: (pickedData) {
                                    setState(() {
                                      address = pickedData.address;
                                    });
                                    latitude = pickedData.latLong.latitude;
                                    longitude = pickedData.latLong.longitude;
                                    Navigator.pop(context);
                                  }
                              ),
                            ),
                          );
                        }
                    );
                },
                child: Text(
                  address != "null"
                      ? address
                      : 'Select restaurant on Map',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 10),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Restaurant Image',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: Container(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        _imageFile = File(pickedFile.path);
                        if (_imageFile != null) {
                          setState(() {});
                        }
                      }
                    },
                    child: const Text('Take Picture'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        _imageFile = File(pickedFile.path);
                        if (_imageFile != null) {
                          setState(() {});
                        }
                      }
                    },
                    child: const Text('Select from Gallery'),
                  ),
                  _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          width: 100,
                          height: 100,
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 10),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Restaurant Managers',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: managerPhoneControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InternationalPhoneNumberInput(
                        initialValue: PhoneNumber(isoCode: 'TR'),
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                        ),
                        textAlign: TextAlign.center,
                        searchBoxDecoration: InputDecoration(
                          hintText: "Country",
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon: const Icon(Icons.add_outlined),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        inputDecoration: InputDecoration(
                          hintText: 'Manager ${index + 1} Phone Number',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                managerPhoneControllers.removeAt(index);
                              });
                            },
                          ),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onInputChanged: (PhoneNumber number) {
                          managerPhoneControllers[index].text =
                              number.phoneNumber ?? '';
                          if (number.phoneNumber!.length >= 10 &&
                              index == managerPhoneControllers.length - 1) {
                            setState(() {
                              managerPhoneControllers
                                  .add(TextEditingController());
                            });
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(15),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (canAddRestaurant) {
                          setState(() {
                            loading = true;
                          });

                          List<String> userIds = [];
                          for (var phoneController in managerPhoneControllers) {
                            String phone = phoneController.text;
                            if (phone.isNotEmpty) {
                              String? userId =
                                  await getUserIdFromPhoneNumber(phone);
                              if (userId != null) {
                                userIds.add(userId);
                              }
                            }
                          }
                          userIds.add(LoginPage.userID);

                          String? imageUrl =
                              await uploadImageToFirebaseStorage(_imageFile!);

                          final geo = GeoFlutterFire();
                          GeoFirePoint restaurantLocation = geo.point(latitude: latitude, longitude: longitude);

                          /* old way before nearby restaurants
                          await FirebaseFirestore.instance
                              .collection("Restaurants")
                              .doc()
                              .set({
                            "name": restaurantNameController.text,
                            "image_url": imageUrl,
                            "managers": FieldValue.arrayUnion(userIds),
                            "rating": 0.0,
                            "address": address,
                            "location": [latitude, longitude],
                            "followerCount": 0,
                            "postCount": 0,
                            if (dropdownValue == null) "restaurantWiFi": "",
                            "restaurantWiFi": dropdownValue,
                          });
                           */

                          FirebaseFirestore.instance
                              .collection('Restaurants')
                              .add({
                            "name": restaurantNameController.text,
                            "position": restaurantLocation.data,
                            "image_url": imageUrl,
                            "managers": FieldValue.arrayUnion(userIds),
                            "rating": 0.0,
                            "address": address,
                            "followerCount": 0,
                            "postCount": 0,
                            if (dropdownValue == null) "restaurantWiFi": "",
                            "restaurantWiFi": dropdownValue!.split('-').last,
                          });

                          //exit
                          restaurantNameController.clear();
                          setState(() {
                            managerPhoneControllers.clear();
                            managerPhoneControllers
                                .add(TextEditingController());
                          });

                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              customSnackBar("Please fill in all required fields.")
                          );
                        }
                      },
                      child: const Text(
                        "Add Restaurant",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
