import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:project_mobile/Authentication/loginPage.dart';
import 'package:project_mobile/Customer/customerHome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Manager/managerHome.dart';
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
      return ManagerHome();
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
    const MaterialColor myColor = MaterialColor(
      0xFF008C8C,
      <int, Color>{
        50: Color(0xFFE0F2F2),
        100: Color(0xFFB3CCCC),
        200: Color(0xFF80B2B2),
        300: Color(0xFF4D9999),
        400: Color(0xFF267F7F),
        500: Color(0xFF008C8C),
        600: Color(0xFF007474),
        700: Color(0xFF006060),
        800: Color(0xFF004C4C),
        900: Color(0xFF003838),
      },
    );

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: myColor,
      ),

      //login durumuna göre sayfaya yönlendirme
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginPage()
          : navigateUserType(),
    );
  }
}
