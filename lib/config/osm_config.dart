/// OpenStreetMap OAuth 2.0 & API Configuration for RoadSense PW
/// Municipal road quality monitoring and Public Works hazard reporting.
class OsmConfig {
  /// OpenStreetMap Registered OAuth 2.0 Client ID
  static const String clientId = 'g4UCcaXCCkbD5u52tLD0CdCZ_QkmrNHk6hqaldCRe2U';

  /// OpenStreetMap Registered OAuth 2.0 Client Secret
  static const String clientSecret = 'DFk-DYU6tFax_U_ad002WGHgOVs6p1rbygFLvyohE1U';

  /// OpenStreetMap OAuth 2.0 Authorization URL
  static const String authUrl = 'https://www.openstreetmap.org/oauth2/authorize';

  /// OpenStreetMap OAuth 2.0 Token Endpoint
  static const String tokenUrl = 'https://www.openstreetmap.org/oauth2/token';

  /// OpenStreetMap v0.6 API Base URL
  static const String apiBase = 'https://api.openstreetmap.org/api/0.6';

  /// Nominatim Reverse Geocoding Base URL
  static const String nominatimBase = 'https://nominatim.openstreetmap.org';

  /// Standard OpenStreetMap Tile URL template
  static const String tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Default OAuth Scopes for RoadSense PW Public Works reporting
  static const List<String> scopes = [
    'read_prefs',
    'write_api',
    'write_notes',
  ];

  /// App redirect URI for OAuth callback
  static const String redirectUri = 'http://localhost:8080/api/osm/callback';
  static const String outOfBandUri = 'urn:ietf:wg:oauth:2.0:oob';

  /// Saidpur Regional Bounding Box for municipal inspection [minLon, minLat, maxLon, maxLat]
  static const double defaultMinLon = 88.8800;
  static const double defaultMinLat = 25.7500;
  static const double defaultMaxLon = 88.9300;
  static const double defaultMaxLat = 25.8000;

  /// Masks client secret for secure UI display
  static String get maskedSecret {
    if (clientSecret.length <= 10) return '••••••••';
    return '${clientSecret.substring(0, 8)}...${clientSecret.substring(clientSecret.length - 6)}';
  }
}
