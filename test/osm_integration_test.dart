import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_sense/config/osm_config.dart';
import 'package:road_sense/screens/profile_screen.dart';
import 'package:road_sense/services/osm_service.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';

void main() {
  setUp(() {
    AppState.instance.stopSpeedSimulation();
  });

  tearDown(() {
    AppState.instance.stopSpeedSimulation();
  });

  group('OpenStreetMap (OSM) OAuth 2.0 & Integration Suite', () {
    test('1. OsmConfig contains correct Client ID, Secret, and OAuth Endpoints', () {
      expect(OsmConfig.clientId, 'g4UCcaXCCkbD5u52tLD0CdCZ_QkmrNHk6hqaldCRe2U');
      expect(OsmConfig.clientSecret, 'DFk-DYU6tFax_U_ad002WGHgOVs6p1rbygFLvyohE1U');
      expect(OsmConfig.authUrl, 'https://www.openstreetmap.org/oauth2/authorize');
      expect(OsmConfig.tokenUrl, 'https://www.openstreetmap.org/oauth2/token');
      expect(OsmConfig.apiBase, 'https://api.openstreetmap.org/api/0.6');
      expect(OsmConfig.scopes, containsAll(['read_prefs', 'write_api', 'write_notes']));
      expect(OsmConfig.maskedSecret, contains('...'));
      expect(OsmConfig.maskedSecret.startsWith('DFk-DYU6'), isTrue);
      expect(OsmConfig.maskedSecret.endsWith('ohE1U'), isTrue);
    });

    test('2. OsmService builds proper authorization URL', () {
      final service = OsmService.instance;
      final authUrl = service.getAuthorizationUrl(state: 'roadsense_test_state');

      expect(authUrl, contains(OsmConfig.authUrl));
      expect(authUrl, contains('client_id=${OsmConfig.clientId}'));
      expect(authUrl, contains('response_type=code'));
      expect(authUrl, contains('read_prefs'));
      expect(authUrl, contains('write_notes'));
      expect(authUrl, contains('write_api'));
      expect(authUrl, contains('state=roadsense_test_state'));
    });

    test('3. OsmNote parses GeoJSON features accurately', () {
      final sampleGeoJson = {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [88.91778, 25.76088],
        },
        'properties': {
          'id': 4028971,
          'url': 'https://api.openstreetmap.org/api/0.6/notes/4028971.json',
          'status': 'open',
          'date_created': '2023-12-15 12:27:28 UTC',
          'comments': [
            {
              'date': '2023-12-15 12:27:28 UTC',
              'action': 'opened',
              'text': 'BAUST Campus Entrance Pothole',
            }
          ]
        }
      };

      final note = OsmNote.fromJson(sampleGeoJson);
      expect(note.id, 4028971);
      expect(note.longitude, 88.91778);
      expect(note.latitude, 25.76088);
      expect(note.status, 'open');
      expect(note.text, 'BAUST Campus Entrance Pothole');
      expect(note.commentCount, 1);
    });

    test('4. AppState manages OSM sync lifecycle', () async {
      final state = AppState.instance;

      expect(state.osmClientId, OsmConfig.clientId);
      expect(state.osmClientSecret, OsmConfig.clientSecret);
      expect(state.isOsmConnected, isTrue);

      // Toggle Auto-sync
      final initialAutoSync = state.isOsmAutoSync;
      state.toggleOsmAutoSync();
      expect(state.isOsmAutoSync, !initialAutoSync);
      state.toggleOsmAutoSync(true);
      expect(state.isOsmAutoSync, isTrue);

      // Sync a defect to OSM
      final noteId = await state.syncDefectToOsm(
        pinId: 'pin-test-99',
        title: 'Saidpur Rail Gate Pothole',
        severity: 'Urgent',
        location: 'Rail Gate #2, Saidpur',
        coordinates: '25.7780° N, 88.8950° E',
        dimensionDetail: '8cm depth cavity',
      );

      expect(noteId, isNotNull);
      expect(state.isDefectSynced('pin-test-99'), isTrue);
      expect(state.getOsmNoteId('pin-test-99'), noteId);

      // Verify note in regional notes
      expect(state.osmNotes.any((n) => n.id == noteId), isTrue);

      // Resolve note
      await state.resolveOsmNote(noteId!, resolutionNotes: 'Asphalt cold mix applied');
      final resolved = state.osmNotes.firstWhere((n) => n.id == noteId);
      expect(resolved.status, 'closed');
    });

    testWidgets('5. Profile Screen renders OpenStreetMap Integration Card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure OSM card elements render
      expect(find.text('OpenStreetMap (OSM)'), findsOneWidget);
      expect(find.text('Public Works Geo-Data & Hazard Sync'), findsOneWidget);
      expect(find.text('OAuth 2.0 Live'), findsOneWidget);
      expect(find.text('OAuth 2.0 Client ID'), findsOneWidget);
      expect(find.text('OAuth 2.0 Client Secret'), findsOneWidget);
      expect(find.text(OsmConfig.clientId), findsOneWidget);
      expect(find.text('read_prefs'), findsOneWidget);
      expect(find.text('write_api'), findsOneWidget);
      expect(find.text('write_notes'), findsOneWidget);
      expect(find.text('Auto-Sync Defects to OSM Notes'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
    });
  });
}
