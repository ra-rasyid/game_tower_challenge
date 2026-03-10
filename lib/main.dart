// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
// 1. Import file firebase_options yang baru saja digenerate
import 'firebase_options.dart'; 
import 'features/game/presentation/pages/match_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Tambahkan parameter options agar Firebase mengenali API Key & Project ID
  // terutama saat dijalankan di platform Web/Chrome
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tower Challenge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true), 
      home: const MatchPage(),
    );
  }
}