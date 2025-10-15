import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHomeScreen> {
  GoogleMapController? _mapController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPos;
  LatLng? _emergencyPos;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _trackLocation();
    _listenEmergencyAssignments();
  }

  void _trackLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) async {
      final user = _auth.currentUser;
      if (user == null) return;

      _currentPos = LatLng(pos.latitude, pos.longitude);

      // Firebase'e konumu güncelle
      await _db.collection("users").doc(user.uid).update({
        "location": GeoPoint(pos.latitude, pos.longitude),
      });

      _updateMap();
    });
  }

  void _listenEmergencyAssignments() {
    final user = _auth.currentUser;
    if (user == null) return;

    _db.collection("users").doc(user.uid).snapshots().listen((doc) {
      final data = doc.data();
      if (data == null) return;

      if (data.containsKey("assignedEmergency")) {
        final emergencyId = data["assignedEmergency"];
        _db.collection("emergencies").doc(emergencyId).get().then((snapshot) {
          if (snapshot.exists) {
            final eData = snapshot.data()!;
            final geoPoint = eData["location"];
            setState(() {
              _emergencyPos = LatLng(geoPoint.latitude, geoPoint.longitude);
            });
            _updateMap();
          }
        });
      }
    });
  }

  void _updateMap() {
    Set<Marker> updatedMarkers = {};
    Set<Polyline> updatedPolylines = {};

    if (_currentPos != null) {
      updatedMarkers.add(Marker(
        markerId: const MarkerId("me"),
        position: _currentPos!,
        infoWindow: const InfoWindow(title: "Benim Konumum"),
      ));
    }

    if (_emergencyPos != null) {
      updatedMarkers.add(Marker(
        markerId: const MarkerId("emergency"),
        position: _emergencyPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: "Atanmış Acil Durum"),
      ));

      if (_currentPos != null) {
        updatedPolylines.add(Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.red,
          width: 4,
          points: [_currentPos!, _emergencyPos!],
        ));
      }
    }

    setState(() {
      _markers = updatedMarkers;
      _polylines = updatedPolylines;
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Çalışan Ekranı")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(39.9208, 32.8541),
          zoom: 12,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
