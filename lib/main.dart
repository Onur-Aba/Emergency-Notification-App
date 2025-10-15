import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // .env verilerini kullanan FirebaseOptions
import 'screens/login.dart';
import 'screens/sign_up.dart';
import 'screens/home.dart';
import 'official/center_home.dart';
import 'official/employee_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 .env dosyasını yükle
  await dotenv.load(fileName: ".env");

  // 🔹 Firebase’i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFF0b0c10),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/center_home': (context) => const CenterHomeScreen(),
        '/employee_home': (context) => const EmployeeHomeScreen(),
      },
    );
  }
}
