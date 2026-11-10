import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_sense/screens/map_screen.dart';
import 'package:road_sense/services/location_service.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';

void main() {
  setUp(() {
    AppState.instance.stopSpeedSimulation();
  });

  tearDown(() {
    AppState.instance.stopSpeedSimulation();
  });

  group('Realtime Phone Location & OpenStreetMap Tracking Tests', () {
    test('1. UserLocation computes speed conversions, formatting, and distance correctly', () {
      final loc1 = UserLocation(
        latitude: 25.7685,
        longitude: 88.9080,
        speed: 10.0, // 10 m/s = 36 km/h
        heading: 180.0,
        accuracy: 4.2,
        timestamp: DateTime.now(),
        isLiveGps: true,
      );

      expect(loc1.speedInKmh, closeTo(36.0, 0.01));
      expect(loc1.speedInMph, closeTo(22.3694, 0.01));
      expect(loc1.formattedCoordinates, contains('25.7685° N'));
      expect(loc1.formattedCoordinates, contains('88.9080° E'));

      // Test distanceTo with a point ~1 km away
      final distance = loc1.distanceTo(25.7775, 88.9080);
      expect(distance, greaterThan(900));
      expect(distance, lessThan(1100));

      final defaultLoc = UserLocation.defaultSaidpur();
      expect(defaultLoc.latitude, closeTo(25.7685, 0.001));
      expect(defaultLoc.longitude, closeTo(88.9080, 0.001));
      expect(defaultLoc.isLiveGps, isFalse);
    });

    test('2. OsmAddress parses JSON and extracts short street names accurately', () {
      final jsonPayload = {
        'place_id': 987654,
        'lat': '25.7685',
        'lon': '88.9080',
        'display_name': 'Airport Road, Saidpur Cantonment, Saidpur, Rangpur, 5310, Bangladesh',
        'address': {
          'road': 'Airport Road',
          'suburb': 'Saidpur Cantonment',
          'town': 'Saidpur',
          'state': 'Rangpur Division',
          'country': 'Bangladesh',
          'postcode': '5310',
        }
      };

      final osmAddress = OsmAddress.fromJson(jsonPayload, 25.7685, 88.9080);
      expect(osmAddress.road, 'Airport Road');
      expect(osmAddress.city, 'Saidpur');
      expect(osmAddress.shortStreetName, 'Airport Road, Saidpur');
      expect(osmAddress.latitude, 25.7685);
      expect(osmAddress.longitude, 88.9080);
    });

    test('3. AppState handles real-time phone location updates and breadcrumb trail', () {
      final state = AppState.instance;

      // Initial state
      expect(state.isLocationTrackingEnabled, isTrue);
      expect(state.currentLocation, isNotNull);

      // Simulate a phone location update
      final newLoc = UserLocation(
        latitude: 25.7690,
        longitude: 88.9095,
        speed: 12.5,
        heading: 45.0,
        accuracy: 3.5,
        timestamp: DateTime.now(),
        isLiveGps: true,
      );

      state.updateCurrentLocation(newLoc);

      expect(state.currentLocation!.latitude, 25.7690);
      expect(state.currentLocation!.longitude, 88.9095);
      expect(state.currentLocation!.isLiveGps, isTrue);
      expect(state.locationBreadcrumbs.isNotEmpty, isTrue);
      expect(state.locationBreadcrumbs.last.latitude, 25.7690);

      // Toggle tracking
      state.toggleLocationTracking(false);
      expect(state.isLocationTrackingEnabled, isFalse);
      state.toggleLocationTracking(true);
      expect(state.isLocationTrackingEnabled, isTrue);
    });

    testWidgets('4. MapScreen renders OpenStreetMap layer, live telemetry, and Locate Me control', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MapScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Screen Header
      expect(find.text('Defect GIS & Road Map'), findsOneWidget);
      expect(find.textContaining('Bangladesh Public Works'), findsOneWidget);

      // Verify Live Tracking indicator banner with speed and location
      expect(find.textContaining('LIVE TRACKING:'), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsWidgets);

      // Verify Zoom and Center controls
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget); // Locate Me
      expect(find.byIcon(Icons.add_rounded), findsOneWidget); // Zoom In
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget); // Zoom Out
      expect(find.byIcon(Icons.public_rounded), findsWidgets); // OSM Layer Toggle

      // Tap Locate Me button
      await tester.tap(find.byIcon(Icons.my_location_rounded), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify OpenStreetMap attribution is visible
      expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    });
  });
}
