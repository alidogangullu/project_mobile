import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pinput/pinput.dart';
import 'package:project_mobile/Admin/adminPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String _verificationId;
  final auth = FirebaseAuth.instance;
  final smsController = TextEditingController();
  String? phoneNumber;
  bool showOTPbox = false;
  bool loading = false;
  int? forceResendingToken;

  final defaultPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(20),
    ),
  );
  final focusedPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue),
      borderRadius: BorderRadius.circular(20),
    ),
  );
  final submittedPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.green),
      borderRadius: BorderRadius.circular(20),
    ),
  );
  final errorPinTheme = PinTheme(
    width: 65,
    height: 65,
    textStyle: TextStyle(fontSize: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.red),
      borderRadius: BorderRadius.circular(50),
    ),
  );

  void loginWithPhone() async {
    auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential).then((value) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => AdminHome()));
          print("You are logged in successfully");
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        print(e.message);
      },
      codeSent: (String verificationId, int? resendToken) {
        showOTPbox = true;
        _verificationId = verificationId;
        setState(() {});
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void verifyOTP() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: smsController.text);
    await auth.signInWithCredential(credential).then((value) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AdminHome()));
      print("You are logged in successfully");
      //Fluttertoast.showToast(
      //  msg: "You are logged in successfully",
      //toastLength: Toast.LENGTH_SHORT,
      //gravity: ToastGravity.CENTER,
      //timeInSecForIosWeb: 1,
      //backgroundColor: Colors.red,
      //textColor: Colors.white,
      //fontSize: 16.0
      //);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 30, 0),
            child: InternationalPhoneNumberInput(
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
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  child: Pinput(
                    length: 6,
                    closeKeyboardWhenCompleted: true,
                    errorPinTheme: errorPinTheme,
                    controller: smsController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    showCursor: false,
                    onSubmitted: (pin) async {
                      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: smsController.text);
                      await auth.signInWithCredential(credential).then((value){
                        print("You are logged in successfully");
                        Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (context) => AdminHome()));
                      });
                    },
                  ),
                )
              : const SizedBox(
                  height: 0,
                ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                //primary: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: Size(150, 55)),
            onPressed: () {
              if (showOTPbox) {
                verifyOTP();
              } else {
                loginWithPhone();
              }
            },
            child: Text(
              showOTPbox ? "Verify" : "Login",
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget InputField(
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
