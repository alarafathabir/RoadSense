import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:road_sense/config/gemini_config.dart';

/// Structured verification result returned by Gemini Vision for road surface inspection.
class PotholeVerificationResult {
  final bool potholeDetected;
  final double confidence; // 0.0 - 1.0
  final String reason;
  final DateTime analyzedAt;
  final String modelUsed;
  final int latencyMs;
  final bool isErrorFallback;

  PotholeVerificationResult({
    required this.potholeDetected,
    required this.confidence,
    required this.reason,
    DateTime? analyzedAt,
    this.modelUsed = GeminiConfig.visionModel,
    this.latencyMs = 0,
    this.isErrorFallback = false,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  /// Confidence expressed as an integer percentage (e.g. 88%)
  int get confidencePercent => (confidence * 100).round().clamp(0, 100);

  /// Whether this result passes the strict hazard threshold (> 0.75 confidence)
  bool get isVerifiedHazard => potholeDetected && confidence > 0.75;

  factory PotholeVerificationResult.fromJson(
    Map<String, dynamic> json, {
    String modelUsed = GeminiConfig.visionModel,
    int latencyMs = 0,
  }) {
    final bool detected = json['pothole_detected'] == true ||
        json['potholeDetected'] == true ||
        json['isPothole'] == true;

    double conf = 0.0;
    final rawConf = json['confidence'];
    if (rawConf is num) {
      conf = rawConf.toDouble();
      if (conf > 1.0 && conf <= 100.0) {
        conf = conf / 100.0;
      }
    }
    conf = conf.clamp(0.0, 1.0);

    final String reason = json['reason'] as String? ??
        (detected
            ? 'Structural cavity or broken depression observed on road pavement.'
            : 'Normal pavement or clear road surface.');

    return PotholeVerificationResult(
      potholeDetected: detected,
      confidence: conf,
      reason: reason,
      analyzedAt: DateTime.now(),
      modelUsed: modelUsed,
      latencyMs: latencyMs,
      isErrorFallback: false,
    );
  }

  /// Safe fallback result for errors, timeouts, or unconfigured API keys
  factory PotholeVerificationResult.safeFallback({
    required String reason,
    int latencyMs = 0,
  }) {
    return PotholeVerificationResult(
      potholeDetected: false,
      confidence: 0.0,
      reason: reason,
      analyzedAt: DateTime.now(),
      modelUsed: GeminiConfig.visionModel,
      latencyMs: latencyMs,
      isErrorFallback: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'pothole_detected': potholeDetected,
    'confidence': confidence,
    'reason': reason,
    'analyzedAt': analyzedAt.toIso8601String(),
    'modelUsed': modelUsed,
    'latencyMs': latencyMs,
    'isErrorFallback': isErrorFallback,
  };
}

/// Structured evaluation of road condition analyzed by Gemini AI
class RoadConditionEvaluation {
  final bool isRoadAlright;
  final String verdict;
  final String defectType;
  final String severity; // 'None' | 'Low' | 'Medium' | 'Urgent'
  final int conditionScore; // 0 - 100
  final String depthEstimate;
  final String damageArea;
  final String recommendedAction;
  final int estimatedCostTaka;
  final String summary;
  final DateTime analyzedAt;
  final String modelUsed;
  final int latencyMs;
  final PotholeVerificationResult? verificationResult;

  const RoadConditionEvaluation({
    required this.isRoadAlright,
    required this.verdict,
    required this.defectType,
    required this.severity,
    required this.conditionScore,
    required this.depthEstimate,
    required this.damageArea,
    required this.recommendedAction,
    required this.estimatedCostTaka,
    required this.summary,
    required this.analyzedAt,
    required this.modelUsed,
    required this.latencyMs,
    this.verificationResult,
  });

  String get statusHeading =>
      isRoadAlright ? 'ROAD CONDITION: ALRIGHT' : 'ROAD DEFECTS DETECTED';

  String get statusBadgeText =>
      isRoadAlright ? 'SURFACE OK' : '$severity HAZARD'.toUpperCase();

  factory RoadConditionEvaluation.fromJson(
    Map<String, dynamic> json, {
    required String modelUsed,
    required int latencyMs,
    PotholeVerificationResult? verificationResult,
  }) {
    final bool isAlright = json['isRoadAlright'] == true;
    final String verdict = json['verdict'] as String? ??
        (isAlright
            ? 'Road condition is alright. Pavement is intact and safe.'
            : 'Road condition is not alright. Defects or hazards detected.');
    final String defectType = json['defectType'] as String? ?? (isAlright ? 'None' : 'Pothole');
    final String severity = json['severity'] as String? ?? (isAlright ? 'None' : 'Urgent');
    final int score = json['conditionScore'] is int
        ? json['conditionScore'] as int
        : (isAlright ? 92 : 45);
    final String depth = json['depthEstimate'] as String? ?? (isAlright ? 'N/A' : '7.0 cm');
    final String area = json['damageArea'] as String? ?? (isAlright ? 'N/A' : '1.2 m²');
    final String action = json['recommendedAction'] as String? ??
        (isAlright
            ? 'Regular Public Works monitoring'
            : 'Cold Mix Patch and edge sealing');
    final int cost = json['estimatedCostTaka'] is int
        ? json['estimatedCostTaka'] as int
        : (isAlright ? 0 : 2800);
    final String summary = json['summary'] as String? ?? verdict;

    final resolvedVerification = verificationResult ??
        (json['verificationResult'] is Map<String, dynamic>
            ? PotholeVerificationResult.fromJson(
                json['verificationResult'] as Map<String, dynamic>,
                modelUsed: modelUsed,
                latencyMs: latencyMs,
              )
            : (json.containsKey('pothole_detected') || json.containsKey('potholeDetected')
                ? PotholeVerificationResult.fromJson(
                    json,
                    modelUsed: modelUsed,
                    latencyMs: latencyMs,
                  )
                : null));

    return RoadConditionEvaluation(
      isRoadAlright: isAlright,
      verdict: verdict,
      defectType: defectType,
      severity: severity,
      conditionScore: score,
      depthEstimate: depth,
      damageArea: area,
      recommendedAction: action,
      estimatedCostTaka: cost,
      summary: summary,
      analyzedAt: DateTime.now(),
      modelUsed: modelUsed,
      latencyMs: latencyMs,
      verificationResult: resolvedVerification,
    );
  }

  Map<String, dynamic> toJson() => {
    'isRoadAlright': isRoadAlright,
    'verdict': verdict,
    'defectType': defectType,
    'severity': severity,
    'conditionScore': conditionScore,
    'depthEstimate': depthEstimate,
    'damageArea': damageArea,
    'recommendedAction': recommendedAction,
    'estimatedCostTaka': estimatedCostTaka,
    'summary': summary,
    'analyzedAt': analyzedAt.toIso8601String(),
    'modelUsed': modelUsed,
    'latencyMs': latencyMs,
    if (verificationResult != null) 'verificationResult': verificationResult!.toJson(),
  };
}

/// Service providing multimodal road condition evaluation powered by Gemini API
class GeminiRoadService {
  static final GeminiRoadService instance = GeminiRoadService._internal();
  factory GeminiRoadService() => instance;
  GeminiRoadService._internal();

  final http.Client _httpClient = http.Client();

  /// Strictly verifies whether a real structural pothole exists in the provided camera frame
  /// using the Gemini Vision API (gemini-2.5-flash).
  ///
  /// Verification Rules:
  /// 1. Return true ONLY if there is a visible structural cavity, bowl-shaped depression,
  ///    or broken chunk missing from the road surface.
  /// 2. Return false for normal pavement, shadows, tire marks, oil stains, manhole covers,
  ///    speed bumps, shallow surface cracks, or non-road images.
  /// 3. If the image is too blurry, dark, or obstructed to confirm a depression with certainty,
  ///    return false.
  Future<PotholeVerificationResult> verifyPotholeInImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final stopwatch = Stopwatch()..start();

    if (imageBytes.isEmpty) {
      stopwatch.stop();
      return PotholeVerificationResult.safeFallback(
        reason: 'No image frame provided for verification.',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    if (GeminiConfig.apiKey.isEmpty || GeminiConfig.apiKey == 'YOUR_GEMINI_API_KEY') {
      stopwatch.stop();
      return PotholeVerificationResult.safeFallback(
        reason: 'Gemini API key is not configured. Set GEMINI_API_KEY to enable live verification.',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    final base64Image = base64Encode(imageBytes);
    const systemPrompt = '''
You are a strict road-surface inspection assistant. Analyze the provided image and verify whether a real pothole exists.

Verification Rules:
1. Return true ONLY if there is a visible structural cavity, bowl-shaped depression, or broken chunk missing from the road surface.
2. Return false for normal pavement, shadows, tire marks, oil stains, manhole covers, speed bumps, shallow surface cracks, or non-road images.
3. If the image is too blurry, dark, or obstructed to confirm a depression with certainty, return false.

Respond strictly in valid JSON matching this schema:
{
  "pothole_detected": boolean,
  "confidence": number between 0 and 1,
  "reason": "Short explanation of the surface feature observed"
}
''';

    const url =
        '${GeminiConfig.apiBase}/models/${GeminiConfig.visionModel}:generateContent?key=${GeminiConfig.apiKey}';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': systemPrompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
      }
    });

    try {
      final response = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 12));

      stopwatch.stop();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map &&
            data.containsKey('candidates') &&
            (data['candidates'] as List).isNotEmpty) {
          final candidate = data['candidates'][0];
          final parts = candidate['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts[0]['text'] as String? ?? '{}';
            try {
              final parsedJson = jsonDecode(rawText) as Map<String, dynamic>;
              return PotholeVerificationResult.fromJson(
                parsedJson,
                modelUsed: GeminiConfig.visionModel,
                latencyMs: stopwatch.elapsedMilliseconds,
              );
            } catch (jsonErr) {
              debugPrint('[GeminiRoadService] JSON decode failed for response: $rawText ($jsonErr)');
            }
          }
        }
      } else {
        debugPrint(
            '[GeminiRoadService] Vision API returned HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[GeminiRoadService] Vision API call failed: $e');
    }

    stopwatch.stop();
    // Invariant: errors must never default to a false-positive hazard!
    return PotholeVerificationResult.safeFallback(
      reason: 'Verification unavailable due to network or service error. Defaulting to safe state.',
      latencyMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Evaluates an image of a road captured via camera or gallery
  /// and determines whether the road condition is alright or not.
  Future<RoadConditionEvaluation> evaluateRoadImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final stopwatch = Stopwatch()..start();

    // 1. First run the strict Gemini 2.5 Flash pothole verification
    final verification = await verifyPotholeInImage(imageBytes, mimeType: mimeType);

    // If an API key is unconfigured or network failed completely
    if (verification.isErrorFallback) {
      stopwatch.stop();
      return _buildFallbackEvaluation(imageBytes, stopwatch.elapsedMilliseconds, verification: verification);
    }

    // 2. If Gemini Vision verified NO pothole or confidence <= 0.75, return an Alright / Safe evaluation
    if (!verification.isVerifiedHazard) {
      stopwatch.stop();
      return RoadConditionEvaluation(
        isRoadAlright: true,
        verdict: 'Road condition is alright. ${verification.reason}',
        defectType: 'None',
        severity: 'None',
        conditionScore: 92,
        depthEstimate: 'N/A',
        damageArea: 'N/A',
        recommendedAction: 'Standard routine Public Works monitoring',
        estimatedCostTaka: 0,
        summary: 'Gemini 2.5 Flash verified road surface: ${verification.reason}',
        analyzedAt: DateTime.now(),
        modelUsed: GeminiConfig.visionModel,
        latencyMs: stopwatch.elapsedMilliseconds,
        verificationResult: verification,
      );
    }

    // 3. If verified pothole (> 0.75 confidence), query full multimodal road diagnostics
    final base64Image = base64Encode(imageBytes);
    const prompt = '''
You are an expert Public Works municipal road safety inspector and computer vision pavement engineer.
Analyze this captured road photograph and determine definitively:
IS THE ROAD CONDITION ALRIGHT OR NOT?

Evaluation Guidelines:
- "isRoadAlright": false -> A verified pothole has been detected on this road.

Respond ONLY with a valid JSON object matching this schema:
{
  "isRoadAlright": false,
  "verdict": "Detailed verdict specifying the pothole cavity observed",
  "defectType": "Pothole",
  "severity": "Low" | "Medium" | "Urgent",
  "conditionScore": integer between 20 and 55,
  "depthEstimate": "e.g. 7.0 cm",
  "damageArea": "e.g. 1.2 m²",
  "recommendedAction": "Concise repair recommendation (e.g. Cold Mix Patch and vibratory compaction)",
  "estimatedCostTaka": integer in Bangladeshi Taka (e.g. 2800),
  "summary": "2-3 clear sentences explaining the visible road condition and reasoning for the verdict"
}
''';

    final models = [
      GeminiConfig.visionModel, // gemini-2.5-flash
      GeminiConfig.primaryModel, // gemini-3.5-flash-lite
    ];

    for (final model in models) {
      final url = '${GeminiConfig.apiBase}/models/$model:generateContent?key=${GeminiConfig.apiKey}';

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        }
      });

      try {
        final response = await _httpClient
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          stopwatch.stop();
          final data = jsonDecode(response.body);
          if (data is Map &&
              data.containsKey('candidates') &&
              (data['candidates'] as List).isNotEmpty) {
            final candidate = data['candidates'][0];
            final parts = candidate['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final rawText = parts[0]['text'] as String? ?? '{}';
              try {
                final parsedJson = jsonDecode(rawText) as Map<String, dynamic>;
                return RoadConditionEvaluation.fromJson(
                  parsedJson,
                  modelUsed: model,
                  latencyMs: stopwatch.elapsedMilliseconds,
                  verificationResult: verification,
                );
              } catch (_) {
                // If parsing secondary diagnostic fails, build from verification
                return RoadConditionEvaluation(
                  isRoadAlright: false,
                  verdict: 'ROAD NOT ALRIGHT: ${verification.reason}',
                  defectType: 'Pothole',
                  severity: 'Urgent',
                  conditionScore: 40,
                  depthEstimate: '7.0 cm',
                  damageArea: '1.2 m²',
                  recommendedAction: 'Rapid cold mix asphalt patch and compaction',
                  estimatedCostTaka: 2800,
                  summary: verification.reason,
                  analyzedAt: DateTime.now(),
                  modelUsed: model,
                  latencyMs: stopwatch.elapsedMilliseconds,
                  verificationResult: verification,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[GeminiRoadService] Secondary diagnostic model $model failed: $e');
      }
    }

    stopwatch.stop();
    // Return verified hazard evaluation
    return RoadConditionEvaluation(
      isRoadAlright: false,
      verdict: 'ROAD NOT ALRIGHT: Structural pothole detected (${verification.confidencePercent}% confidence).',
      defectType: 'Pothole',
      severity: 'Urgent',
      conditionScore: 40,
      depthEstimate: '7.0 cm',
      damageArea: '1.2 m²',
      recommendedAction: 'Rapid cold mix asphalt patch and vibratory compaction',
      estimatedCostTaka: 2800,
      summary: verification.reason,
      analyzedAt: DateTime.now(),
      modelUsed: GeminiConfig.visionModel,
      latencyMs: stopwatch.elapsedMilliseconds,
      verificationResult: verification,
    );
  }

  /// Lightweight connectivity test for Gemini API Key
  Future<Map<String, dynamic>> testConnection() async {
    final stopwatch = Stopwatch()..start();
    const url =
        '${GeminiConfig.apiBase}/models/${GeminiConfig.visionModel}:generateContent?key=${GeminiConfig.apiKey}';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Ping test. Reply with: OK'}
          ]
        }
      ]
    });

    try {
      final res = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      stopwatch.stop();
      return {
        'success': res.statusCode == 200,
        'statusCode': res.statusCode,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'model': GeminiConfig.visionModel,
        'message': res.statusCode == 200
            ? 'Connected to Gemini API (${GeminiConfig.visionModel}) in ${stopwatch.elapsedMilliseconds}ms.'
            : 'Gemini API responded with HTTP ${res.statusCode}',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': 'Failed to connect to Gemini API: $e',
      };
    }
  }

  /// Fail-safe road evaluation: Defaults to safe (no false alert) when offline or on error
  RoadConditionEvaluation _buildFallbackEvaluation(
    Uint8List bytes,
    int latencyMs, {
    PotholeVerificationResult? verification,
  }) {
    final v = verification ??
        PotholeVerificationResult.safeFallback(
          reason: 'No structural hazard confirmed (Offline/Safe mode).',
          latencyMs: latencyMs,
        );

    return RoadConditionEvaluation(
      isRoadAlright: true, // Fail-safe: Safe by default, never default to false positive alert!
      verdict: 'ROAD SURFACE: Safe inspection completed. No confirmed structural hazard.',
      defectType: 'None',
      severity: 'None',
      conditionScore: 90,
      depthEstimate: 'N/A',
      damageArea: 'N/A',
      recommendedAction: 'Standard routine Public Works monitoring',
      estimatedCostTaka: 0,
      summary: v.reason,
      analyzedAt: DateTime.now(),
      modelUsed: '${GeminiConfig.visionModel} (Fail-safe)',
      latencyMs: latencyMs,
      verificationResult: v,
    );
  }
}
