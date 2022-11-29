import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pinput/pinput.dart';
import 'package:project_mobile/Admin/adminPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static String userID = "";

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = FirebaseAuth.instance;
  late User user;


  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool showSignUp = false;
  final nameController = TextEditingController();
  final surnameController = TextEditingController();

  String? phoneNumber;
  int? forceResendingToken;
  late String _verificationId;
  final smsController = TextEditingController();

  bool showOTPbox = false;
  bool loading = false;
  bool phoneNumberFormat = false;
  bool verificated = true;
  bool codeSent = false;
  bool buttonPressed = false;

  final defaultPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: const TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(25),
    ),
  );
  final focusedPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: const TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue),
      borderRadius: BorderRadius.circular(25),
    ),
  );
  final errorPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: const TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.red),
      borderRadius: BorderRadius.circular(25),
    ),
  );
  final submittedPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: const TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.green),
      borderRadius: BorderRadius.circular(25),
    ),
  );

  void loginWithPhone() async {
    if (phoneNumberFormat) {
      setState(() {
        loading = true;
      });
      auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential).then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => AdminHome()));
          });
        },
        verificationFailed: (FirebaseAuthException e) {},
        codeSent: (String verificationId, int? resendToken) {
          codeSent = true;
          showOTPbox = true;
          _verificationId = verificationId;
          setState(() {
            loading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    }
  }

  void verifyOTP() async {
    setState(() {
      loading = true;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: smsController.text);
      user = (await auth.signInWithCredential(credential)).user!;

      if (await getData(uid: user.uid)) {
        await auth.signInWithCredential(credential).then((value) {
          LoginPage.userID = user.uid;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => AdminHome()));
        });
      } else {
        setState(() {
          showSignUp = true;
        });
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        buttonPressed = false; //changed for if-else in column
        codeSent = false; //changed for if-else in column
        loading = false;
        verificated = false;
      });
    }
  }

  Future<void> signUp(User user) async {
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber,
      'name': nameController.text,
      'surname': surnameController.text,
    });
    LoginPage.userID = user.uid;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => AdminHome()));
  }

  Future<bool> getData({required String uid}) async {
    DocumentSnapshot ds = await firestore.collection("users").doc(uid).get();
    return ds.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          showSignUp
              ? const SizedBox(
                  height: 0,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 0, 30, 0),
                      child: InternationalPhoneNumberInput(
                        isEnabled: !phoneNumberFormat,
                        onInputValidated: (bool value) {
                          phoneNumberFormat = value;
                        },
                        textAlign: TextAlign.center,
                        searchBoxDecoration: const InputDecoration(
                          hintText: "Country",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          prefixIcon: Icon(Icons.add_outlined),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 75,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        inputDecoration: const InputDecoration(
                          hintText: "5xx xxx xxxx",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(50),
                            ),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        onInputChanged: (PhoneNumber number) {
                          phoneNumber = number.phoneNumber;
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          trailingSpace: false,
                        ),
                        ignoreBlank: false,
                        autoValidateMode: AutovalidateMode.disabled,
                        initialValue: PhoneNumber(isoCode: 'TR'),
                        formatInput: false,
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    showOTPbox
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                            child: Pinput(
                              length: 6,
                              closeKeyboardWhenCompleted: true,
                              forceErrorState: !verificated,
                              errorPinTheme: errorPinTheme,
                              submittedPinTheme: submittedPinTheme,
                              controller: smsController,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: focusedPinTheme,
                              showCursor: false,
                            ),
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (phoneNumberFormat & codeSent)
                      const Text(
                        'Verification Code Sent',
                        style: TextStyle(color: Colors.green),
                      )
                    else if (!phoneNumberFormat & buttonPressed)
                      const Text(
                        'Check your phone number',
                        style: TextStyle(color: Colors.red),
                      )
                    else if (!verificated)
                      const Text(
                        'Wrong verification code',
                        style: TextStyle(color: Colors.red),
                      ),
                    const SizedBox(
                      height: 20,
                    ),
                    loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                //primary: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                minimumSize: const Size(150, 55)),
                            onPressed: () {
                              if (showOTPbox) {
                                verifyOTP();
                              } else {
                                loginWithPhone();
                                setState(() {
                                  buttonPressed = true;
                                });
                              }
                            },
                            child: Text(
                              showOTPbox ? "Verify" : "Sign In",
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ],
                ),
          showSignUp
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    inputField(
                        const Icon(Icons.person_outlined), "Name", nameController),
                    const SizedBox(
                      height: 20,
                    ),
                    inputField(const Icon(Icons.person_outlined), "Surname",
                        surnameController),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size(150, 55)),
                      onPressed: () {
                        signUp(user);
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox(
                  height: 0,
                ),
        ],
      ),
    );
  }
}

Widget inputField(
    Icon prefixIcon, String hintText, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        fillColor: Colors.white,
        filled: true,
        prefixIcon: prefixIcon,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 75,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(50),
          ),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(50),
          ),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    ),
  );
}
