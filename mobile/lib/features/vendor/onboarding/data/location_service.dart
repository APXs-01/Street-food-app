import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../core/brand.dart';
import '../../../../core/localization/l10n.dart';

enum LocationProblem { servicesOff, denied, deniedForever, unavailable }

class LocationException implements Exception {
  const LocationException(this.problem);

  final LocationProblem problem;

  /// Safe to show as it is.
  String get message => switch (problem) {
        LocationProblem.servicesOff => l10n.locationServicesOff,
        LocationProblem.denied => l10n.locationDenied,
        LocationProblem.deniedForever => l10n.locationDeniedForever(kBrandName),
        LocationProblem.unavailable => l10n.locationUnavailable,
      };

  /// Whether the person can fix it in the phone's settings.
  bool get canOpenSettings => problem == LocationProblem.servicesOff || problem == LocationProblem.deniedForever;

  @override
  String toString() => 'LocationException($problem)';
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Where the phone is. An interface so a test can stand in for the GPS.
abstract interface class LocationService {
  /// Asks for permission if needed. Throws [LocationException] with the reason
  /// when it cannot give a position.
  Future<GeoPoint> currentPosition();

  Future<void> openSettings(LocationProblem problem);
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationProblem.servicesOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationProblem.deniedForever);
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      throw const LocationException(LocationProblem.denied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      return GeoPoint(position.latitude, position.longitude);
    } on TimeoutException {
      throw const LocationException(LocationProblem.unavailable);
    } on LocationServiceDisabledException {
      throw const LocationException(LocationProblem.servicesOff);
    } on PermissionDeniedException {
      throw const LocationException(LocationProblem.denied);
    }
  }

  @override
  Future<void> openSettings(LocationProblem problem) async {
    if (problem == LocationProblem.servicesOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
