import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebaseconfig.dart';
import 'sign_up.dart';
import 'home.dart';
import '../official/center_home.dart';
import '../official/employee_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool useEmail = false;
  String email = "";
  String phoneNumber = "";
  String password = "";
  bool showPassword = false;

  List<Map<String, dynamic>> countries = [];
  String? selectedCountry;

  Map<String, String> errors = {};

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final String response =
        await rootBundle.loadString('assets/countries.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      countries = data
          .map((c) => {
                "label": "${c["name"]} (${c["dial_code"]})",
                "value": c["code"],
                "dial_code": c["dial_code"],
              })
          .toList();
    });
  }

  bool validateForm() {
    Map<String, String> newErrors = {};

    if (useEmail) {
      if (email.isEmpty) {
        newErrors["email"] = "E-posta alanı boş bırakılamaz";
      } else if (!RegExp(r"\S+@\S+\.\S+").hasMatch(email)) {
        newErrors["email"] = "Geçerli bir e-posta adresi girin";
      }
    } else {
      if (selectedCountry == null) {
        newErrors["country"] = "Ülke kodu seçmelisiniz";
      }
      if (phoneNumber.isEmpty) {
        newErrors["phoneNumber"] = "Telefon numarası gerekli";
      } else if (phoneNumber.length != 10) {
        newErrors["phoneNumber"] = "Telefon numarası 10 haneli olmalı";
      }
    }

    if (password.isEmpty) {
      newErrors["password"] = "Şifre alanı boş bırakılamaz";
    } else if (password.length < 6) {
      newErrors["password"] = "Şifre en az 6 karakter olmalı";
    }

    setState(() {
      errors = newErrors;
    });
    return newErrors.isEmpty;
  }

  Future<void> handleLogin() async {
    if (!validateForm()) return;

    try {
      UserCredential userCredential;

      if (useEmail) {
        // 🔹 Email ile login
        userCredential = await auth.signInWithEmailAndPassword(
            email: email, password: password);

        // Firestore'da email'e göre kullanıcıyı bul
        final query = await db
            .collection("users")
            .where("email", isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          setState(() {
            errors = {"general": "Kullanıcı bulunamadı."};
          });
          return;
        }

        final userData = query.docs.first.data();
        await _redirectBasedOnRole(userData["role"]);

      } else {
        // 🔹 Telefon ile login
        final countryData =
            countries.firstWhere((c) => c["value"] == selectedCountry);
        final fullPhone = phoneNumber; // sadece 10 hane (5xxxxxxxxx)
        final query = await db
            .collection("users")
            .where("phoneNumber", isEqualTo: fullPhone)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          setState(() {
            errors = {"general": "Telefon numarası ile kullanıcı bulunamadı."};
          });
          return;
        }

        final userData = query.docs.first.data();
        final userEmail = userData["email"];

        if (userEmail == null) {
          setState(() {
            errors = {"general": "Kullanıcıya ait e-posta bulunamadı."};
          });
          return;
        }

        // FirebaseAuth login
        userCredential = await auth.signInWithEmailAndPassword(
            email: userEmail, password: password);

        await _redirectBasedOnRole(userData["role"]);
      }
    } on FirebaseAuthException {
      setState(() {
        errors = {"general": "Giriş başarısız! Bilgilerinizi kontrol edin."};
      });
    } catch (e) {
      setState(() {
        errors = {"general": "Bir hata oluştu: $e"};
      });
    }
  }

  Future<void> _redirectBasedOnRole(String? role) async {
    Widget targetPage;

    if (role == "center") {
      targetPage = const CenterHomeScreen();
    } else if (role == "employee") {
      targetPage = const EmployeeHomeScreen();
    } else {
      targetPage = const HomeScreen();
    }

    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b0c10),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Giriş Yap",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Email veya Telefon
                if (useEmail) ...[
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "E-posta",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1a1e25),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => setState(() => email = val),
                  ),
                  if (errors["email"] != null)
                    Text(errors["email"]!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                ] else ...[
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      hint: const Text("Ülke Kodu Seç",
                          style: TextStyle(color: Colors.grey)),
                      items: countries
                          .map((c) => DropdownMenuItem<String>(
                                value: c["value"],
                                child: Text(
                                  c["label"],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ))
                          .toList(),
                      value: selectedCountry,
                      onChanged: (val) =>
                          setState(() => selectedCountry = val),
                      buttonStyleData: ButtonStyleData(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1e25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2a2f38)),
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1e25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (errors["country"] != null)
                    Text(errors["country"]!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "5xxxxxxxxx",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1a1e25),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: (val) {
                      String cleaned = val.replaceFirst(RegExp(r"^0+"), "");
                      if (RegExp(r"^\d{0,10}$").hasMatch(cleaned)) {
                        setState(() => phoneNumber = cleaned);
                      }
                    },
                  ),
                  if (errors["phoneNumber"] != null)
                    Text(errors["phoneNumber"]!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                ],

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1e25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2a2f38)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Şifre",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          obscureText: !showPassword,
                          onChanged: (val) =>
                              setState(() => password = val),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => showPassword = !showPassword),
                      )
                    ],
                  ),
                ),
                if (errors["password"] != null)
                  Text(errors["password"]!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),

                if (errors["general"] != null)
                  Text(errors["general"]!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Center(
                    child: Text("Giriş Yap",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () => setState(() => useEmail = !useEmail),
                  child: Text(
                    useEmail ? "Telefon ile oturum aç" : "Mail ile oturum aç",
                    style: const TextStyle(color: Color(0xFF2563eb)),
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const SignUpScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        transitionDuration:
                            const Duration(milliseconds: 200),
                      ),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Hesabın yok mu? ",
                      style: TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: "Üye ol",
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
}
