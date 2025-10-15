import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CenterHomeScreen extends StatefulWidget {
  const CenterHomeScreen({Key? key}) : super(key: key);

  @override
  State<CenterHomeScreen> createState() => _CenterHomeScreenState();
}

class _CenterHomeScreenState extends State<CenterHomeScreen> {
  GoogleMapController? _mapController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  BitmapDescriptor? ambulanceIcon;
  BitmapDescriptor? firefighterIcon;
  BitmapDescriptor? policeIcon;
  BitmapDescriptor? emergencyIcon;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  StreamSubscription? _emergenciesSub;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  @override
  void dispose() {
    _emergenciesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomMarkers() async {
    const iconSize = Size(64, 64);

    ambulanceIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: iconSize),
      "assets/icons/ambulance.png",
    );
    firefighterIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: iconSize),
      "assets/icons/firefighter.png",
    );
    policeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: iconSize),
      "assets/icons/police.png",
    );
    emergencyIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: iconSize),
      "assets/icons/emergency.png",
    );

    setState(() {});
    _listenToEmergencies();
  }

  void _listenToEmergencies() {
    _emergenciesSub =
        _db.collection("emergencies").snapshots().listen((snapshot) {
      Set<Marker> updatedMarkers = {};
      Set<Circle> updatedCircles = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey("location")) {
          final loc = data["location"];
          double? lat;
          double? lng;
          double? accuracy;
          int? updatedAt;

          // Support both Map and GeoPoint for location
          if (loc is Map) {
            if (loc["lat"] != null && loc["lng"] != null) {
              lat = (loc["lat"] as num).toDouble();
              lng = (loc["lng"] as num).toDouble();
            }
            if (loc["accuracy"] != null) {
              accuracy = (loc["accuracy"] as num).toDouble();
            }
            if (loc["updatedAt"] != null) {
              updatedAt = (loc["updatedAt"] as num).toInt();
            }
          } else if (loc is GeoPoint) {
            lat = loc.latitude;
            lng = loc.longitude;
          }

          if (lat != null && lng != null) {
            final type = (data["service"] ?? data["type"] ?? "emergency")
                .toString()
                .toLowerCase();

            BitmapDescriptor? icon;
            if (type.contains("ambulans") || type.contains("ambulance")) {
              icon = ambulanceIcon;
            } else if (type.contains("itfaiye") ||
                type.contains("firefighter")) {
              icon = firefighterIcon;
            } else if (type.contains("polis") || type.contains("police")) {
              icon = policeIcon;
            } else {
              icon = emergencyIcon;
            }

            // InfoWindow açıklaması
            String snippet = "";
            if (accuracy != null) {
              snippet += "Hata payı: ±${accuracy.toStringAsFixed(1)} m";
            }
            if (updatedAt != null) {
              final dt = DateTime.fromMillisecondsSinceEpoch(updatedAt);
              snippet +=
                  (snippet.isNotEmpty ? "\n" : "") + "Son güncelleme: ${dt.hour}:${dt.minute.toString().padLeft(2, "0")}";
            }

            // Marker ekle
            updatedMarkers.add(
              Marker(
                markerId: MarkerId("emergency_${doc.id}"),
                position: LatLng(lat, lng),
                icon: icon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueYellow),
                infoWindow: InfoWindow(
                  title:
                      "Acil Durum: ${type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : "?"}",
                  snippet: snippet.isNotEmpty ? snippet : null,
                ),
              ),
            );

            // Accuracy circle ekle (varsa)
            if (accuracy != null && accuracy > 0) {
              updatedCircles.add(
                Circle(
                  circleId: CircleId("circle_${doc.id}"),
                  center: LatLng(lat, lng),
                  radius: accuracy, // metre
                  fillColor: Colors.blue.withOpacity(0.15),
                  strokeColor: Colors.blueAccent,
                  strokeWidth: 1,
                ),
              );
            }
          }
        }
      }

      setState(() {
        _markers = updatedMarkers;
        _circles = updatedCircles;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kontrol Merkezi")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(41.015137, 28.979530), // İstanbul default
          zoom: 11,
        ),
        markers: _markers,
        circles: _circles,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}
