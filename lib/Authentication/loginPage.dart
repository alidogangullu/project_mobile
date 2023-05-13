import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pinput/pinput.dart';
import 'package:project_mobile/Customer/customerPanel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Manager/managerPanel.dart';
import '../customWidgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static String userID = "";

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = FirebaseAuth.instance;
  late User user;
  bool isManager = false;

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

  void loginWithPhone() async {
    if (phoneNumberFormat) {
      setState(() {
        loading = true;
      });
      auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          /*
          await auth.signInWithCredential(credential).then((value) {
            //doğrulama kodundan sonra uygulamaya yönlendirme
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const AdminHome()));
          });
           */
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
        await auth.signInWithCredential(credential).then((value) async {
          LoginPage.userID = user.uid;

          //uygulamaya tekrar girişte doğru yönlendirmesi için isManager'ın lokal olarak saklanması
          SharedPreferences sharedPreferences =
              await SharedPreferences.getInstance();
          sharedPreferences.setBool(
              'isManager', isManager); //isManager'ı kaydetmek için

          //doğrulama kodundan sonra uygulamaya yönlendirme
          if (isManager == true) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const ManagerHome()));
          } else if (isManager == false) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const CustomerHome()));
          }
        });
      } else {
        setState(() {
          //kayıtlı değilse signUp ekranına yönlendirmek için boolean
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
    //ilk kayıt için bilgileri database'e yollama
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber,
      'name': nameController.text,
      'surname': surnameController.text,
    });
    LoginPage.userID = user.uid;

    //uygulamaya tekrar girişte doğru yönlendirmesi için isManager'ın lokal olarak saklanması
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(
        'isManager', isManager); //isManager'ı kaydetmek için

    print(isManager);
    print(sharedPreferences.getBool('isManager'));

    //ilk kayıttan sonra kullanıcı tipine göre uygulamaya yönlendirme
    if (isManager == true) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const ManagerHome()));
    } else if (isManager == false) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const CustomerHome()));
    }
  }

  Future<bool> getData({required String uid}) async {
    DocumentSnapshot ds = await firestore.collection("users").doc(uid).get();
    return ds.exists;
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 65,
      height: 55,
      textStyle: const TextStyle(fontSize: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    final focusedPinTheme = PinTheme(
      width: 65,
      height: 55,
      textStyle: const TextStyle(fontSize: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    final errorPinTheme = PinTheme(
      width: 65,
      height: 55,
      textStyle: const TextStyle(fontSize: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    final submittedPinTheme = PinTheme(
      width: 65,
      height: 55,
      textStyle: const TextStyle(fontSize: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(4),
      ),
    );

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
                      padding: const EdgeInsets.only(left: 15),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: InternationalPhoneNumberInput(
                            isEnabled: !phoneNumberFormat,
                            onInputValidated: (bool value) {
                              phoneNumberFormat = value;
                            },
                            selectorConfig: const SelectorConfig(
                              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                              trailingSpace: false,
                            ),
                            ignoreBlank: false,
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
                              hintText: "(5xx) xxx xxxx",
                              hintStyle: const TextStyle(
                                fontSize: 16,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            onInputChanged: (PhoneNumber number) {
                              phoneNumber = number.phoneNumber;
                            },
                            autoValidateMode: AutovalidateMode.disabled,
                            initialValue: PhoneNumber(isoCode: 'TR'),
                            formatInput: false,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                          ),
                        ),
                      ),
                    ),
                    showOTPbox
                        ? Padding(
                            padding: const EdgeInsets.all(15),
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
                    if (phoneNumberFormat & codeSent)
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          'Verification Code Sent',
                          style: TextStyle(color: Colors.green),
                        ),
                      )
                    else if (!phoneNumberFormat & buttonPressed)
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          'Check your phone number',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    else if (!verificated)
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          'Wrong verification code',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    loading
                        ? const Center(
                            child: Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(),
                          ))
                        : Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
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
                                  showOTPbox ? "Verify" : "Sign In Now",
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    if (showOTPbox == false && loading == false)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isManager = !isManager;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "You are signing in as a ",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                            children: [
                              TextSpan(
                                text: isManager ? "manager." : "customer.",
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
          showSignUp
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    textInputField(context, "Name", nameController, false),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Surname',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    textInputField(context, "Surname", surnameController, false),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            signUp(user);
                          },
                          child: const Text(
                            "Sign Up Now",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
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