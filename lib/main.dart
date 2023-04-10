import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile/Admin/adminPanel.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:project_mobile/Customer/customerPanel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<User?> user;
  var sharedPreferences;
  var isManager;

  Future<void> readySharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    isManager = sharedPreferences.getBool('isManager')!;
    setState(() {});
  }

  Widget navigateUserType() {
    if (isManager == true) {
      return AdminHome();
    } else if (isManager == false) {
      return CustomerHome();
    } else {
      return LoginPage();
    }
  }

  void initState() {
    super.initState();
    //zaten giriş yapılıp yapılmadığı kontrolü
    user = FirebaseAuth.instance.authStateChanges().listen((user) {});
    if (FirebaseAuth.instance.currentUser != null) {
      LoginPage.userID = FirebaseAuth.instance.currentUser!.uid;

      //user tipine göre yönlendirme hazırlığı
      readySharedPreferences();
    }
  }

  @override
  void dispose() {
    user.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.blue,
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      //login durumuna göre sayfaya yönlendirme
      home: FirebaseAuth.instance.currentUser == null
          ? LoginPage()
          : navigateUserType(),
    );
  }
}
