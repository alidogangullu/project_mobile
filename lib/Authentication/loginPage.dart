import 'package:flutter/material.dart';
import 'package:project_mobile/Authentication/forgotPassword.dart';
import 'package:project_mobile/Authentication/sign_upPage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InputField(const Icon(Icons.person_outline), "E-Mail"),
          PasswordField(),
          LoginButton(),
          AuthText('Forgot Password?', ForgotPasswordPage()),
          AuthText('Not a member? Sign up now!', SignUpPage()),
        ],
      ),
    );
  }
}

Widget LoginButton() {
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          //primary: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: Size(150, 55)),
      onPressed: () => {},
      child: const Text(
        "Sign In",
        style: TextStyle(
          fontSize: 20,
        ),
      ),
    ),
  );
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
            minimumSize: Size(150, 55)),
        onPressed: () => {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignUpPage()),
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

Widget InputField(Icon prefixIcon, String hintText) {
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

class PasswordField extends StatefulWidget {
  const PasswordField({Key? key}) : super(key: key);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  late bool _passwordVisible;
  @override
  void initState() {
    _passwordVisible = false;
  }
  Widget build(BuildContext context) {
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
          obscureText: _passwordVisible,
          style: const TextStyle(
            fontSize: 17,
          ),
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
            hintText: "Password",
            hintStyle: const TextStyle(
              color: Colors.grey,
            ),
            fillColor: Colors.white,
            filled: true,
            prefixIcon: Icon(Icons.lock_outline),
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
}


class AuthText extends StatefulWidget {
  final String text;
  final Widget route;
  AuthText(this.text, this.route);

  @override
  State<AuthText> createState() => _AuthTextState();
}

class _AuthTextState extends State<AuthText> {
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => widget.route),
          );
        },
        child: Text(
          widget.text,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }
}
