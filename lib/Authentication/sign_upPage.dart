import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/loginPage.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _inputField(const Icon(Icons.person_outlined), "E-Mail", false),
          _inputField(const Icon(Icons.lock_outline), "Password", true),
          _inputField(const Icon(Icons.lock_outline), "Password Again", true),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SignUp(),
            ],
          ),
        ],
      ),
    );
  }
}

class SignUp extends StatelessWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 15, 15, 15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minimumSize: Size(150, 55)
        ),
        onPressed: () => {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          )
        },
        child: const Text(
          "Sign Up",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

Widget _inputField(Icon prefixIcon, String hintText, bool isPassword) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
    child: Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 25,
            offset: Offset(0, 5),
            spreadRadius: -25,
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        style: const TextStyle(
          fontSize: 17,
        ),
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
    ),
  );
}
