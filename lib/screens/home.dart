import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? countdownTimer;
  int remainingSeconds = 600; // 10 dakika
  StreamSubscription<Position>? locationSubscription;
  String? selectedService;
  void Function(void Function())? _dialogSetState; // dialog içi state

  @override
  void dispose() {
    countdownTimer?.cancel();
    locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startEmergencyFlow(String service) async {
    setState(() {
      selectedService = service;
      remainingSeconds = 600;
    });

    // Kullanıcı telefon numarası
    final user = FirebaseAuth.instance.currentUser;
    final phoneNumber = user?.phoneNumber ?? "unknown";

    // Cihaz bilgisi
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceModel = "unknown";
    String osVersion = "unknown";

    if (Theme.of(context).platform == TargetPlatform.android) {
      final info = await deviceInfoPlugin.androidInfo;
      deviceModel = info.model ?? "unknown";
      osVersion = "Android ${info.version.release}";
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final info = await deviceInfoPlugin.iosInfo;
      deviceModel = info.utsname.machine ?? "unknown";
      osVersion = "iOS ${info.systemVersion}";
    }

    // App versiyonu
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;

    // Timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Firestore kaydı
    final docRef = FirebaseFirestore.instance
        .collection("emergencies")
        .doc("$phoneNumber-$timestamp");

    await docRef.set({
      "phoneNumber": phoneNumber,
      "service": service,
      "deviceModel": deviceModel,
      "osVersion": osVersion,
      "appVersion": appVersion,
      "timestamp": timestamp,
    });

    // Konum izinleri
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    // Konum akışı başlat
    locationSubscription?.cancel();
    locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // her küçük hareketi yakala
      ),
    ).listen((pos) async {
      await docRef.update({
        "location": {
          "lat": pos.latitude,
          "lng": pos.longitude,
          "accuracy": pos.accuracy, // metre cinsinden doğruluk
          "updatedAt": DateTime.now().millisecondsSinceEpoch,
        }
      });
    });

    // Sayaç başlat
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
        // Dialog içi de güncellensin
        if (_dialogSetState != null) {
          _dialogSetState!(() {});
        }
      } else {
        countdownTimer?.cancel();
        locationSubscription?.cancel();
      }
    });

    // Popup aç
    _showCountdownPopup();
  }

  void _showServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Acil Servis Seçin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("🚒 İtfaiye"),
              onTap: () {
                Navigator.pop(context);
                _startEmergencyFlow("itfaiye");
              },
            ),
            ListTile(
              title: const Text("🚑 Ambulans"),
              onTap: () {
                Navigator.pop(context);
                _startEmergencyFlow("ambulans");
              },
            ),
            ListTile(
              title: const Text("🚓 Polis"),
              onTap: () {
                Navigator.pop(context);
                _startEmergencyFlow("polis");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCountdownPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          _dialogSetState = setStateDialog; // kaydet
          return AlertDialog(
            title: const Text("Ekranı kapatmayın"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Seçilen servis: $selectedService"),
                const SizedBox(height: 16),
                Text(
                  "Kalan süre: ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  countdownTimer?.cancel();
                  locationSubscription?.cancel();
                  Navigator.pop(context);
                },
                child: const Text("Durdur"),
              )
            ],
          );
        },
      ),
    ).then((_) {
      _dialogSetState = null; // kapatıldığında sıfırla
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Acil Yardım"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _showServiceDialog,
          child: const Text("Acil Servis Çağır"),
        ),
      ),
    );
  }
}
