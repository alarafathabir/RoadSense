import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:road_sense/config/osm_config.dart';

/// Represents a community or municipal note in OpenStreetMap.
class OsmNote {
  final int id;
  final double latitude;
  final double longitude;
  final String status; // 'open' | 'closed'
  final String dateCreated;
  final String text;
  final int commentCount;
  final String url;
  final bool isRoadSenseDefect;

  const OsmNote({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.dateCreated,
    required this.text,
    this.commentCount = 1,
    required this.url,
    this.isRoadSenseDefect = false,
  });

  factory OsmNote.fromJson(Map<String, dynamic> json) {
    int id = 0;
    double lat = 0.0;
    double lon = 0.0;
    String status = 'open';
    String dateCreated = '';
    String text = '';
    String url = '';
    int commentsCount = 0;

    // Support GeoJSON feature structure from OSM API 0.6 notes.json
    if (json.containsKey('properties')) {
      final props = json['properties'] as Map<String, dynamic>? ?? {};
      id = props['id'] is int ? props['id'] as int : int.tryParse('${props['id']}') ?? 0;
      status = props['status'] as String? ?? 'open';
      dateCreated = props['date_created'] as String? ?? '';
      url = props['url'] as String? ?? 'https://api.openstreetmap.org/api/0.6/notes/$id';

      if (props['comments'] is List && (props['comments'] as List).isNotEmpty) {
        final comments = props['comments'] as List;
        commentsCount = comments.length;
        final firstComment = comments.first;
        if (firstComment is Map && firstComment.containsKey('text')) {
          text = firstComment['text'] as String? ?? '';
        }
      }
    } else {
      id = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;
      status = json['status'] as String? ?? 'open';
      dateCreated = json['date_created'] as String? ?? '';
      text = json['text'] as String? ?? '';
      url = json['url'] as String? ?? 'https://api.openstreetmap.org/api/0.6/notes/$id';
    }

    if (json.containsKey('geometry')) {
      final geom = json['geometry'] as Map<String, dynamic>? ?? {};
      if (geom['coordinates'] is List && (geom['coordinates'] as List).length >= 2) {
        final coords = geom['coordinates'] as List;
        lon = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    } else {
      lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
      lon = (json['lon'] as num?)?.toDouble() ?? 0.0;
    }

    final isRoadSense = text.contains('RoadSense') || text.contains('[BPW-');

    return OsmNote(
      id: id,
      latitude: lat,
      longitude: lon,
      status: status,
      dateCreated: dateCreated,
      text: text,
      commentCount: commentsCount > 0 ? commentsCount : 1,
      url: url,
      isRoadSenseDefect: isRoadSense,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'dateCreated': dateCreated,
    'text': text,
    'commentCount': commentCount,
    'url': url,
    'isRoadSenseDefect': isRoadSenseDefect,
  };
}

/// Result of testing OpenStreetMap connectivity and OAuth client credentials.
class OsmTestResult {
  final bool success;
  final String message;
  final int latencyMs;
  final bool apiAvailable;
  final bool oauthValidated;
  final String? responsePayload;

  const OsmTestResult({
    required this.success,
    required this.message,
    required this.latencyMs,
    required this.apiAvailable,
    required this.oauthValidated,
    this.responsePayload,
  });
}

/// Service providing OpenStreetMap OAuth 2.0 integration, API queries,
/// and note synchronization for RoadSense PW.
class OsmService {
  static final OsmService instance = OsmService._internal();
  factory OsmService() => instance;
  OsmService._internal();

  final http.Client _client = http.Client();

  /// Builds the OpenStreetMap OAuth 2.0 authorization URL.
  String getAuthorizationUrl({
    String? redirectUri,
    String? state,
  }) {
    final uri = Uri.parse(OsmConfig.authUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': OsmConfig.clientId,
        'redirect_uri': redirectUri ?? OsmConfig.redirectUri,
        'scope': OsmConfig.scopes.join(' '),
        if (state != null) 'state': state,
      },
    );
    return uri.toString();
  }

  /// Tests connectivity to OpenStreetMap API and validates the OAuth2 Client ID/Secret.
  Future<OsmTestResult> testConnection() async {
    final stopwatch = Stopwatch()..start();
    bool apiOk = false;
    bool oauthOk = false;
    String statusMsg = '';

    try {
      // 1. Verify API v0.6 reachability via capabilities check
      final capRes = await _client
          .get(
            Uri.parse('${OsmConfig.apiBase}/capabilities'),
            headers: {'User-Agent': 'RoadSense-PW/1.0 (Public Works Saidpur)'},
          )
          .timeout(const Duration(seconds: 5));

      apiOk = (capRes.statusCode == 200);

      // 2. Validate Client ID & Secret against OAuth2 token endpoint
      // We pass a dummy authorization_code to trigger validation.
      // If client_id/secret are valid, OSM responds with 'invalid_grant' (BadRequest).
      // If client_id/secret are invalid, OSM responds with 'invalid_client'.
      final oauthRes = await _client
          .post(
            Uri.parse(OsmConfig.tokenUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'client_id': OsmConfig.clientId,
              'client_secret': OsmConfig.clientSecret,
              'grant_type': 'authorization_code',
              'code': 'roadsense_preflight_check',
              'redirect_uri': OsmConfig.outOfBandUri,
            },
          )
          .timeout(const Duration(seconds: 5));

      final responseBody = oauthRes.body;
      if (responseBody.contains('invalid_grant')) {
        oauthOk = true;
      } else if (responseBody.contains('invalid_client')) {
        oauthOk = false;
        statusMsg = 'Client ID or Secret was rejected by OpenStreetMap.';
      } else {
        oauthOk = oauthRes.statusCode == 200 || oauthRes.statusCode == 400;
      }

      stopwatch.stop();

      if (apiOk && oauthOk) {
        return OsmTestResult(
          success: true,
          message: 'Connected to OpenStreetMap API v0.6. Client credentials verified successfully.',
          latencyMs: stopwatch.elapsedMilliseconds,
          apiAvailable: true,
          oauthValidated: true,
          responsePayload: responseBody,
        );
      } else if (apiOk && !oauthOk) {
        return OsmTestResult(
          success: false,
          message: statusMsg.isNotEmpty ? statusMsg : 'API reachable, but OAuth credentials failed verification.',
          latencyMs: stopwatch.elapsedMilliseconds,
          apiAvailable: true,
          oauthValidated: false,
          responsePayload: responseBody,
        );
      } else {
        return OsmTestResult(
          success: false,
          message: 'Unable to reach OpenStreetMap API v0.6.',
          latencyMs: stopwatch.elapsedMilliseconds,
          apiAvailable: false,
          oauthValidated: false,
          responsePayload: capRes.body,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return OsmTestResult(
        success: false,
        message: 'Network error communicating with OpenStreetMap: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
        apiAvailable: false,
        oauthValidated: false,
      );
    }
  }

  /// Fetches OpenStreetMap notes for the specified geographical bounding box.
  Future<List<OsmNote>> fetchNotes({
    double minLon = OsmConfig.defaultMinLon,
    double minLat = OsmConfig.defaultMinLat,
    double maxLon = OsmConfig.defaultMaxLon,
    double maxLat = OsmConfig.defaultMaxLat,
  }) async {
    try {
      final uri = Uri.parse(
        '${OsmConfig.apiBase}/notes.json?bbox=$minLon,$minLat,$maxLon,$maxLat',
      );

      final res = await _client
          .get(
            uri,
            headers: {'User-Agent': 'RoadSense-PW/1.0 (Public Works Saidpur)'},
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('features') && data['features'] is List) {
          final features = data['features'] as List;
          return features
              .map((f) => OsmNote.fromJson(f as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[OsmService] Error fetching notes: $e');
    }
    return [];
  }

  /// Creates a new road hazard or defect note on OpenStreetMap.
  Future<OsmNote?> createNote({
    required double latitude,
    required double longitude,
    required String text,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('${OsmConfig.apiBase}/notes.json');
      final headers = <String, String>{
        'User-Agent': 'RoadSense-PW/1.0 (Public Works Saidpur)',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final res = await _client
          .post(
            uri,
            headers: headers,
            body: {
              'lat': latitude.toStringAsFixed(6),
              'lon': longitude.toStringAsFixed(6),
              'text': text,
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          return OsmNote.fromJson(data);
        }
      } else {
        debugPrint('[OsmService] Create note returned ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[OsmService] Failed to create note on OSM: $e');
    }
    return null;
  }

  /// Closes an OpenStreetMap note when the municipal repair is completed.
  Future<bool> closeNote(
    int noteId, {
    required String comment,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('${OsmConfig.apiBase}/notes/$noteId/close.json');
      final headers = <String, String>{
        'User-Agent': 'RoadSense-PW/1.0 (Public Works Saidpur)',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final res = await _client
          .post(
            uri,
            headers: headers,
            body: {'text': comment},
          )
          .timeout(const Duration(seconds: 8));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[OsmService] Failed to close note $noteId: $e');
      return false;
    }
  }

  /// Reverse geocodes coordinates to road / address using OSM Nominatim.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        '${OsmConfig.nominatimBase}/reverse?format=json&lat=$latitude&lon=$longitude',
      );

      final res = await _client
          .get(
            uri,
            headers: {'User-Agent': 'RoadSense-PW/1.0 (Public Works Saidpur)'},
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data.containsKey('display_name')) {
          return data['display_name'] as String;
        }
      }
    } catch (e) {
      debugPrint('[OsmService] Reverse geocode error: $e');
    }
    return null;
  }
}
