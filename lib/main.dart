import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:yala_tamrin_admin/PopularGround/helper.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart' as web;
import 'package:yala_tamrin_admin/login/login.dart';
import 'package:yala_tamrin_admin/splash/AdminSplashScreen%20.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // أضف هذا السطر إذا كنت تستخدم Flutter Web
   if (kIsWeb) {
    web.setUrlStrategy(web.PathUrlStrategy());
  }
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBOEhNRn3-HuikYSa9HCPeD7K_OZoIxoFA",
      authDomain: "yala-tamrin.firebaseapp.com",
      projectId: "yala-tamrin",
      storageBucket: "yala-tamrin.firebasestorage.app",
      messagingSenderId: "486100306649",
      appId: "1:486100306649:web:f1aff7b61c89dd45c60cc8",
      measurementId: "G-71ZGCSCQR7",
    ),
  );
    Get.put(());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'يلا تمرين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AdminSplashScreen(),
    );
  }
}

