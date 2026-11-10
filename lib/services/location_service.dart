import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Represents a geographic coordinate and movement telemetry from the device's location sensor.
class UserLocation {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // meters per second
  final double heading; // degrees (0.0 - 360.0)
  final double accuracy; // meters
  final DateTime timestamp;
  final bool isLiveGps;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    this.accuracy = 5.0,
    required this.timestamp,
    this.isLiveGps = true,
  });

  /// Default fallback location in Saidpur, Rangpur, Bangladesh (Airport Road / BAUST)
  static UserLocation defaultSaidpur() => UserLocation(
        latitude: 25.7685,
        longitude: 88.9080,
        altitude: 40.0,
        speed: 0.0,
        heading: 90.0,
        accuracy: 4.5,
        timestamp: DateTime.now(),
        isLiveGps: false,
      );

  factory UserLocation.fromPosition(Position pos, {bool isLive = true}) {
    return UserLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      speed: math.max(0.0, pos.speed),
      heading: pos.heading,
      accuracy: pos.accuracy,
      timestamp: pos.timestamp,
      isLiveGps: isLive,
    );
  }

  /// Formatted coordinates string, e.g. "25.7685° N, 88.9080° E"
  String get formattedCoordinates {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lonDir';
  }

  /// Speed in km/h
  double get speedInKmh => speed * 3.6;

  /// Speed in mph
  double get speedInMph => speed * 2.23694;

  /// Distance in meters to another coordinate using the Haversine formula
  double distanceTo(double targetLat, double targetLon) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = (targetLat - latitude) * (math.pi / 180.0);
    final dLon = (targetLon - longitude) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude * (math.pi / 180.0)) *
            math.cos(targetLat * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? heading,
    double? accuracy,
    DateTime? timestamp,
    bool? isLiveGps,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isLiveGps: isLiveGps ?? this.isLiveGps,
    );
  }
}

/// Address details retrieved from OpenStreetMap Nominatim reverse geocoding API.
class OsmAddress {
  final String? road;
  final String? suburb;
  final String? neighbourhood;
  final String? city;
  final String? county;
  final String? state;
  final String? country;
  final String? postcode;
  final String displayName;
  final double latitude;
  final double longitude;

  const OsmAddress({
    this.road,
    this.suburb,
    this.neighbourhood,
    this.city,
    this.county,
    this.state,
    this.country,
    this.postcode,
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  /// Short human-readable street or area representation
  String get shortStreetName {
    if (road != null && road!.isNotEmpty) {
      if (city != null && city!.isNotEmpty) {
        return '$road, $city';
      }
      return road!;
    }
    if (suburb != null && suburb!.isNotEmpty) {
      return suburb!;
    }
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
    if (displayName.isNotEmpty) {
      final parts = displayName.split(',');
      if (parts.length >= 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }
      return parts[0].trim();
    }
    return 'Saidpur Paurashava, Rangpur';
  }

  factory OsmAddress.fromJson(Map<String, dynamic> json, double lat, double lon) {
    final addr = (json['address'] as Map<String, dynamic>?) ?? {};
    return OsmAddress(
      road: addr['road'] as String?,
      suburb: addr['suburb'] as String?,
      neighbourhood: addr['neighbourhood'] as String?,
      city: addr['city'] as String? ?? addr['town'] as String? ?? addr['village'] as String?,
      county: addr['county'] as String?,
      state: addr['state'] as String?,
      country: addr['country'] as String?,
      postcode: addr['postcode'] as String?,
      displayName: (json['display_name'] as String?) ?? 'OpenStreetMap Location',
      latitude: double.tryParse('${json['lat']}') ?? lat,
      longitude: double.tryParse('${json['lon']}') ?? lon,
    );
  }
}

/// Service that accesses device location sensors (GPS, Wi-Fi, Cell) and interacts with OpenStreetMap APIs.
class LocationService {
  static final LocationService instance = LocationService._internal();
  factory LocationService() => instance;
  LocationService._internal();

  final http.Client _httpClient = http.Client();

  // Cache for reverse geocoding to prevent flooding Nominatim API
  final Map<String, OsmAddress> _addressCache = {};
  DateTime _lastNominatimRequest = DateTime.fromMillisecondsSinceEpoch(0);

  /// Checks if location service is enabled and requests permission from the user.
  Future<bool> handlePermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions are permanently denied.');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[LocationService] Error checking permissions: $e');
      return false;
    }
  }

  /// Gets the current phone location using high accuracy GPS.
  Future<UserLocation> getCurrentLocation({bool fallbackToDefault = true}) async {
    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) {
        if (fallbackToDefault) return UserLocation.defaultSaidpur();
        throw Exception('Location permission not granted');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return UserLocation.fromPosition(pos, isLive: true);
    } catch (e) {
      debugPrint('[LocationService] Failed to acquire current GPS position: $e');
      if (fallbackToDefault) {
        return UserLocation.defaultSaidpur();
      }
      rethrow;
    }
  }

  /// Provides a stream of real-time location updates as the user moves.
  Stream<UserLocation> getRealtimeLocationStream() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Update every 3 meters
      );

      return Geolocator.getPositionStream(locationSettings: locationSettings)
          .map((pos) => UserLocation.fromPosition(pos, isLive: true))
          .handleError((e) {
        debugPrint('[LocationService] Position stream error: $e');
      });
    } catch (e) {
      debugPrint('[LocationService] Could not establish location stream: $e');
      return Stream.value(UserLocation.defaultSaidpur());
    }
  }

  /// Queries the OpenStreetMap Nominatim API to locate and reverse-geocode latitude and longitude.
  Future<OsmAddress?> reverseGeocodeOsm(double latitude, double longitude) async {
    final cacheKey = '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey];
    }

    // Rate-limit to satisfy OpenStreetMap Nominatim usage policy (max 1 req/sec)
    final now = DateTime.now();
    final elapsed = now.difference(_lastNominatimRequest);
    if (elapsed.inMilliseconds < 1100) {
      await Future.delayed(Duration(milliseconds: 1100 - elapsed.inMilliseconds));
    }
    _lastNominatimRequest = DateTime.now();

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2'
        '&lat=$latitude'
        '&lon=$longitude'
        '&accept-language=en'
        '&addressdetails=1'
        '&zoom=18',
      );

      final response = await _httpClient.get(
        uri,
        headers: {
          'User-Agent': 'RoadSense-PW-App/1.0 (Public Works Bangladesh; contact@roadsense.pw)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = OsmAddress.fromJson(data, latitude, longitude);
        _addressCache[cacheKey] = address;
        return address;
      }
    } catch (e) {
      debugPrint('[LocationService] OpenStreetMap reverse geocode error: $e');
    }

    // Default localized fallback
    return OsmAddress(
      road: 'Airport Road',
      city: 'Saidpur',
      state: 'Rangpur Division',
      country: 'Bangladesh',
      displayName: 'Airport Road near BAUST, Saidpur, Rangpur, Bangladesh',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
