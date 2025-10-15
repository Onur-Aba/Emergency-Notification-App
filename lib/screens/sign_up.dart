// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebaseconfig.dart'; // auth ve db burada tanımlı
import '../services/countries.dart'; // countries.json'u dart'a çevirip buraya koyabilirsin
import 'login.dart'; // LoginScreen burada tanımlı olmalı

// Eğer countries değişkeni tanımlı değilse, aşağıdaki gibi örnek bir liste ekleyin:
// final List<Map<String, dynamic>> countries = [
//   {"code": "TR", "name": "Türkiye", "dial_code": "+90"},
//   {"code": "US", "name": "United States", "dial_code": "+1"},
//   // Diğer ülkeler...
// ];

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  // Dropdown
  String? _selectedCountry;
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _countries = countries; // countries.dart’tan geliyor

  // Şifre göster/gizle
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Hata & mesaj state
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final countryData =
          _countries.firstWhere((c) => c["code"] == _selectedCountry);

      // 1️⃣ Telefon kontrolü
      final phoneSnap = await db
          .collection("users")
          .where("phoneNumber", isEqualTo: _phoneNumber.text)
          .get();
      if (phoneSnap.docs.isNotEmpty) {
        setState(() => _errorMessage = "Bu telefon numarası ile zaten bir hesap var.");
        return;
      }

      // 2️⃣ E-posta kontrolü
      final emailSnap = await db
          .collection("users")
          .where("email", isEqualTo: _email.text)
          .get();
      if (emailSnap.docs.isNotEmpty) {
        setState(() => _errorMessage = "Bu e-posta adresi ile zaten bir hesap var.");
        return;
      }

      // ✅ Firebase Authentication
      await auth.createUserWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );

      // ✅ Firestore’a kaydet
      final sanitizedEmail = _email.text.replaceAll(RegExp(r'[.-]'), '');
      final userDocId = "${_phoneNumber.text}-$sanitizedEmail";

      await db.collection("users").doc(userDocId).set({
        "firstName": _firstName.text,
        "lastName": _lastName.text,
        "email": _email.text,
        "countryCode": countryData["dial_code"],
        "phoneNumber": _phoneNumber.text,
        "role": "normal",
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        _successMessage = "Kayıt başarılı! Giriş sayfasına yönlendiriliyorsunuz.";
        _errorMessage = null;
      });

      Timer(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, "/login");
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = "Kayıt sırasında hata oluştu: ${e.message}");
    } catch (e) {
      setState(() => _errorMessage = "Beklenmedik hata: $e");
    }
  }

  String? _validateField(String field, String value) {
    if (value.isEmpty) return "$field alanı boş bırakılamaz";
    if (field == "İsim" && value.length < 2) {
      return "İsmi doğru yazdığınızdan emin misiniz?";
    }
    if (field == "Soyisim" && value.length < 2) {
      return "Soyismi doğru yazdığınızdan emin misiniz?";
    }
    if (field == "E-posta" && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
      return "Geçerli bir e-posta adresi girin";
    }
    if (field == "Telefon" && value.length != 10) {
      return "Telefon numarası 10 haneli olmalı";
    }
    if (field == "Şifre" && value.length < 6) {
      return "Şifre en az 6 karakter olmalı";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b0c10),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Kayıt Ol",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Uygulama içi mesaj
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 15),

                // Form alanları
                TextFormField(
                  controller: _firstName,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("İsim"),
                  validator: (v) => _validateField("İsim", v ?? ""),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lastName,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Soyisim"),
                  validator: (v) => _validateField("Soyisim", v ?? ""),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("E-posta"),
                  validator: (v) => _validateField("E-posta", v ?? ""),
                ),
                const SizedBox(height: 10),

                // Dropdown (ülke kodu)
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  items: _countries
                      .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                            value: c["code"] as String,
                            child: Text(
                              "${c["name"]} (${c["dial_code"]})",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCountry = val),
                  dropdownColor: const Color(0xFF1a1e25),
                  decoration: _inputDecoration("Ülke Kodu Seç"),
                  validator: (v) =>
                      v == null ? "Ülke kodu seçmelisiniz" : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneNumber,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("5xxxxxxxxx"),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (v) => _validateField("Telefon", v ?? ""),
                ),
                const SizedBox(height: 10),

                // Şifre
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Şifre").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) => _validateField("Şifre", v ?? ""),
                ),
                const SizedBox(height: 10),

                // Şifre tekrar
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: !_showConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Şifre (Tekrar)").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Şifre tekrar alanı boş bırakılamaz";
                    }
                    if (v != _password.text) {
                      return "Şifreler eşleşmiyor";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleSignUp,
                  child: const Text(
                    "Kayıt Ol",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),

                const SizedBox(height: 15),

GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const LoginScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 200),
                      ),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Hesabın var mı? ",
                      style: TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: "Giriş yap",
                          style: TextStyle(
                              color: Color(0xFF2563eb),
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1a1e25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2a2f38)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2a2f38)),
      ),
    );
  }
}
