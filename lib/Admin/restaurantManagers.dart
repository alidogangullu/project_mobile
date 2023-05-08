import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class EditRestaurantManagers extends StatefulWidget {
  final String restaurantId;

  const EditRestaurantManagers({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  State<EditRestaurantManagers> createState() => _EditRestaurantManagersState();
}

class _EditRestaurantManagersState extends State<EditRestaurantManagers> {
  List<TextEditingController> managerPhoneControllers = [];

  bool loading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchManagers();
  }

  Future<void> fetchManagers() async {
    DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
        .doc("Restaurants/${widget.restaurantId}")
        .get();
    List<String> userIds = List<String>.from(restaurantSnapshot['managers']);
    List<String> phoneNumbers = [];

    for (String userId in userIds) {
      String? phoneNumber = await getPhoneNumberFromUserId(userId);
      if (phoneNumber != null) {
        phoneNumbers.add(phoneNumber);
      }
    }

    managerPhoneControllers = phoneNumbers
        .map((phone) => TextEditingController(text: phone))
        .toList();

    setState(() {
      loading = false;
    });
  }

  Future<String?> getPhoneNumberFromUserId(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot['phone'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Edit Restaurant Managers",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 20, 15, 15),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Manager Phone Numbers',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
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
                              initialValue: PhoneNumber(
                                isoCode: 'TR',
                                phoneNumber:
                                    managerPhoneControllers[index].text,
                              ),
                              selectorConfig: const SelectorConfig(
                                selectorType:
                                    PhoneInputSelectorType.BOTTOM_SHEET,
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
                                suffixIcon: index == 0
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          setState(() {
                                            managerPhoneControllers
                                                .removeAt(index);
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
                                    index ==
                                        managerPhoneControllers.length - 1) {
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
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isSaving = true;
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
                        await FirebaseFirestore.instance
                            .doc("Restaurants/${widget.restaurantId}")
                            .update({"managers": userIds});
                        setState(() {
                          isSaving = false;
                        });
                        Navigator.pop(context);
                      },
                      child: isSaving
                          ? const CircularProgressIndicator()
                          : const Text(
                              "Save Changes",
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