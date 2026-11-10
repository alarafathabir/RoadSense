/// Gemini API Configuration for RoadSense PW Road Quality Assessment
class GeminiConfig {
  /// Google Gemini API Key configured via environment or fallback placeholder.
  /// Can be provided via `--dart-define=GEMINI_API_KEY=your_key`
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY',
  );

  /// Targeted Multimodal Vision Model for Road Surface Verification
  static const String visionModel = 'gemini-2.5-flash';

  /// Primary Multimodal Model (Gemini 3.5 Flash Lite for fast road condition assessment)
  static const String primaryModel = 'gemini-3.5-flash-lite';

  /// Advanced Multimodal Model (Gemini 3.8 Flash)
  static const String advancedModel = 'gemini-3.8-flash';

  /// Gemini REST API Base URL
  static const String apiBase = 'https://generativelanguage.googleapis.com/v1beta';

  /// Endpoint URL for generateContent with vision model (Gemini 2.5 Flash)
  static String get visionGenerateContentUrl =>
      '$apiBase/models/$visionModel:generateContent?key=$apiKey';

  /// Endpoint URL for generateContent with primary model
  static String get generateContentUrl =>
      '$apiBase/models/$primaryModel:generateContent?key=$apiKey';

  /// Advanced Model Endpoint URL
  static String get advancedGenerateContentUrl =>
      '$apiBase/models/$advancedModel:generateContent?key=$apiKey';

  /// Masks API key for secure UI presentation
  static String get maskedApiKey {
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') return '••••••••';
    if (apiKey.length <= 12) return '••••••••';
    return '${apiKey.substring(0, 8)}...${apiKey.substring(apiKey.length - 6)}';
  }
}
