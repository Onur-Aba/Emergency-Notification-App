import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart'; // Otomatik oluşturulan Firebase ayarları

// Firebase'i başlatan fonksiyon
Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// Firebase Auth örneği
final FirebaseAuth auth = FirebaseAuth.instance;

// Firestore örneği
final FirebaseFirestore db = FirebaseFirestore.instance;
