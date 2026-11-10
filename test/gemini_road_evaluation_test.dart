import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_sense/config/gemini_config.dart';
import 'package:road_sense/screens/camera_screen.dart';
import 'package:road_sense/screens/profile_screen.dart';
import 'package:road_sense/services/gemini_road_service.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';

void main() {
  setUp(() {
    AppState.instance.stopSpeedSimulation();
  });

  tearDown(() {
    AppState.instance.stopSpeedSimulation();
  });

  group('Gemini API Road Condition Evaluation Suite', () {
    test('1. GeminiConfig contains user key and multimodal endpoints', () {
      expect(GeminiConfig.apiKey, isNotEmpty);
      expect(GeminiConfig.primaryModel, 'gemini-3.5-flash-lite');
      expect(GeminiConfig.advancedModel, 'gemini-3.8-flash');
      expect(GeminiConfig.generateContentUrl, contains('key=${GeminiConfig.apiKey}'));
      expect(GeminiConfig.maskedApiKey, isNotEmpty);
    });

    test('2. RoadConditionEvaluation correctly formats Alright vs Not Alright states', () {
      // Case A: Road is ALRIGHT
      final alrightJson = {
        'isRoadAlright': true,
        'verdict': 'Road condition is alright. Pavement is smooth and safe for driving.',
        'defectType': 'None',
        'severity': 'None',
        'conditionScore': 94,
        'depthEstimate': 'N/A',
        'damageArea': 'N/A',
        'recommendedAction': 'Standard Public Works maintenance',
        'estimatedCostTaka': 0,
        'summary': 'The road surface is smooth asphalt without potholes or cracking.',
      };

      final evalAlright = RoadConditionEvaluation.fromJson(
        alrightJson,
        modelUsed: GeminiConfig.primaryModel,
        latencyMs: 180,
      );

      expect(evalAlright.isRoadAlright, isTrue);
      expect(evalAlright.statusHeading, 'ROAD CONDITION: ALRIGHT');
      expect(evalAlright.statusBadgeText, 'SURFACE OK');
      expect(evalAlright.estimatedCostTaka, 0);

      // Case B: Road is NOT ALRIGHT
      final notAlrightJson = {
        'isRoadAlright': false,
        'verdict': 'Road condition is NOT alright. Severe pothole cavity detected.',
        'defectType': 'Pothole',
        'severity': 'Urgent',
        'conditionScore': 38,
        'depthEstimate': '7.5 cm',
        'damageArea': '1.4 m²',
        'recommendedAction': 'Emergency cold mix asphalt patch and compaction',
        'estimatedCostTaka': 3200,
        'summary': 'A dangerous 7.5 cm deep pothole is present in the main wheel track.',
      };

      final evalNotAlright = RoadConditionEvaluation.fromJson(
        notAlrightJson,
        modelUsed: GeminiConfig.primaryModel,
        latencyMs: 220,
      );

      expect(evalNotAlright.isRoadAlright, isFalse);
      expect(evalNotAlright.statusHeading, 'ROAD DEFECTS DETECTED');
      expect(evalNotAlright.statusBadgeText, 'URGENT HAZARD');
      expect(evalNotAlright.defectType, 'Pothole');
      expect(evalNotAlright.estimatedCostTaka, 3200);
    });

    test('3. AppState updates current evaluation and hazard flags', () {
      final state = AppState.instance;

      expect(state.geminiApiKey, GeminiConfig.apiKey);

      // Manually set an "alright" road evaluation
      final goodEval = RoadConditionEvaluation(
        isRoadAlright: true,
        verdict: 'Road is in safe condition',
        defectType: 'None',
        severity: 'None',
        conditionScore: 90,
        depthEstimate: 'N/A',
        damageArea: 'N/A',
        recommendedAction: 'No action needed',
        estimatedCostTaka: 0,
        summary: 'Road is clear',
        analyzedAt: DateTime.now(),
        modelUsed: 'gemini-3.5-flash-lite',
        latencyMs: 150,
      );

      state.setRoadEvaluation(goodEval);
      expect(state.currentRoadEvaluation, isNotNull);
      expect(state.currentRoadEvaluation!.isRoadAlright, isTrue);
      expect(state.hazardDetected, isFalse);

      // Manually set a "not alright" road evaluation
      final badEval = RoadConditionEvaluation(
        isRoadAlright: false,
        verdict: 'Dangerous Pothole Cavity',
        defectType: 'Pothole',
        severity: 'Urgent',
        conditionScore: 35,
        depthEstimate: '8 cm',
        damageArea: '1.2 m²',
        recommendedAction: 'Apply cold mix asphalt',
        estimatedCostTaka: 2800,
        summary: 'Cavity hazard on Saidpur Airport Road',
        analyzedAt: DateTime.now(),
        modelUsed: 'gemini-3.5-flash-lite',
        latencyMs: 190,
      );

      state.setRoadEvaluation(badEval);
      expect(state.currentRoadEvaluation!.isRoadAlright, isFalse);
      expect(state.hazardDetected, isTrue);
    });

    testWidgets('4. Camera Screen displays Gemini Road Assessment Card with Alright verdict',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.setRoadEvaluation(
        RoadConditionEvaluation(
          isRoadAlright: true,
          verdict: 'Road condition is alright. Pavement is clear and safe.',
          defectType: 'None',
          severity: 'None',
          conditionScore: 92,
          depthEstimate: 'N/A',
          damageArea: 'N/A',
          recommendedAction: 'Routine monitoring',
          estimatedCostTaka: 0,
          summary: 'Smooth pavement surface with no visible hazards.',
          analyzedAt: DateTime.now(),
          modelUsed: 'gemini-3.5-flash-lite',
          latencyMs: 200,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CameraScreen(),
        ),
      );
      await tester.pump();

      // Ensure Gemini evaluation card is visible
      expect(find.text('Gemini Road Condition Assessment'), findsOneWidget);
      expect(find.text('ROAD CONDITION IS ALRIGHT ✓'), findsOneWidget);
      expect(find.text('Road condition is alright. Pavement is clear and safe.'), findsOneWidget);
      expect(find.text('Pavement Quality Score: 92/100 • 200ms'), findsOneWidget);
    });

    testWidgets('5. Camera Screen displays Gemini Road Assessment Card with NOT ALRIGHT verdict',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.setRoadEvaluation(
        RoadConditionEvaluation(
          isRoadAlright: false,
          verdict: 'Severe Pothole Cavity detected on roadway.',
          defectType: 'Pothole',
          severity: 'Urgent',
          conditionScore: 42,
          depthEstimate: '7.5 cm',
          damageArea: '1.2 m²',
          recommendedAction: 'Patch with asphalt cold mix',
          estimatedCostTaka: 2800,
          summary: 'Deep cavity visible in asphalt wearing course.',
          analyzedAt: DateTime.now(),
          modelUsed: 'gemini-3.5-flash-lite',
          latencyMs: 210,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CameraScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Gemini Road Condition Assessment'), findsOneWidget);
      expect(find.text('ROAD CONDITION: NOT ALRIGHT ⚠️'), findsOneWidget);
      expect(find.text('Severe Pothole Cavity detected on roadway.'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Re-evaluate'), findsOneWidget);
    });

    testWidgets('6. Profile Screen renders Gemini Road Condition Engine card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gemini Road Condition Engine'), findsOneWidget);
      expect(find.text('Multimodal AI • Condition: Alright or Not Alright'), findsOneWidget);
      expect(find.text('Google Gemini API Key'), findsOneWidget);
      expect(find.text('Test Gemini API Key'), findsOneWidget);
    });

    test('7. PotholeVerificationResult parses JSON schema and enforces 0.75 threshold', () {
      // Case A: High confidence pothole -> isVerifiedHazard is TRUE
      final verifiedHazard = PotholeVerificationResult.fromJson({
        'pothole_detected': true,
        'confidence': 0.88,
        'reason': 'Visible bowl-shaped depression with broken asphalt chunks.',
      });
      expect(verifiedHazard.potholeDetected, isTrue);
      expect(verifiedHazard.confidence, 0.88);
      expect(verifiedHazard.confidencePercent, 88);
      expect(verifiedHazard.isVerifiedHazard, isTrue);

      // Case B: Boundary at exactly 0.75 -> isVerifiedHazard is FALSE (must exceed 0.75)
      final boundary75 = PotholeVerificationResult.fromJson({
        'pothole_detected': true,
        'confidence': 0.75,
        'reason': 'Possible shallow indentation.',
      });
      expect(boundary75.isVerifiedHazard, isFalse);

      // Case C: Exceeds 0.75 -> isVerifiedHazard is TRUE
      final boundary76 = PotholeVerificationResult.fromJson({
        'pothole_detected': true,
        'confidence': 0.76,
        'reason': 'Confirmed road cavity.',
      });
      expect(boundary76.isVerifiedHazard, isTrue);

      // Case D: Pothole false -> isVerifiedHazard is FALSE even with 0.99 confidence
      final clearPavement = PotholeVerificationResult.fromJson({
        'pothole_detected': false,
        'confidence': 0.99,
        'reason': 'Normal smooth asphalt with painted lane markings.',
      });
      expect(clearPavement.potholeDetected, isFalse);
      expect(clearPavement.confidence, 0.99);
      expect(clearPavement.isVerifiedHazard, isFalse);

      // Case E: Percentage format (e.g. 95 instead of 0.95) is auto-normalized
      final normalizedPercent = PotholeVerificationResult.fromJson({
        'pothole_detected': true,
        'confidence': 92,
        'reason': 'Deep cavity on road shoulder.',
      });
      expect(normalizedPercent.confidence, closeTo(0.92, 0.001));
      expect(normalizedPercent.isVerifiedHazard, isTrue);
    });

    test('8. Fail-safe error handling prevents false-positive alerts', () async {
      final service = GeminiRoadService.instance;

      // Empty image bytes -> returns safe fallback without throwing
      final emptyResult = await service.verifyPotholeInImage(Uint8List(0));
      expect(emptyResult.potholeDetected, isFalse);
      expect(emptyResult.confidence, 0.0);
      expect(emptyResult.isVerifiedHazard, isFalse);
      expect(emptyResult.isErrorFallback, isTrue);

      // Safe fallback evaluation
      final fallback = PotholeVerificationResult.safeFallback(
        reason: 'Network connection timeout',
      );
      expect(fallback.potholeDetected, isFalse);
      expect(fallback.confidence, 0.0);
      expect(fallback.isVerifiedHazard, isFalse);
      expect(fallback.isErrorFallback, isTrue);
    });

    testWidgets('9. Camera Screen renders NO POTHOLE DETECTED reticle for safe surface',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.setRoadEvaluation(
        RoadConditionEvaluation(
          isRoadAlright: true,
          verdict: 'Road surface is clear and in good condition.',
          defectType: 'None',
          severity: 'None',
          conditionScore: 95,
          depthEstimate: 'N/A',
          damageArea: 'N/A',
          recommendedAction: 'Routine monitoring',
          estimatedCostTaka: 0,
          summary: 'Intact asphalt surface without hazards.',
          analyzedAt: DateTime.now(),
          modelUsed: GeminiConfig.visionModel,
          latencyMs: 150,
          verificationResult: PotholeVerificationResult(
            potholeDetected: false,
            confidence: 0.96,
            reason: 'Normal smooth asphalt surface.',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CameraScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('NO POTHOLE DETECTED'), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
      expect(find.text('Normal smooth asphalt surface.'), findsOneWidget);
    });

    testWidgets('10. Camera Screen renders Pothole Detected reticle for verified hazard',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.setRoadEvaluation(
        RoadConditionEvaluation(
          isRoadAlright: false,
          verdict: 'Severe Pothole Cavity detected on roadway.',
          defectType: 'Pothole',
          severity: 'Urgent',
          conditionScore: 35,
          depthEstimate: '8 cm',
          damageArea: '1.2 m²',
          recommendedAction: 'Rapid cold mix asphalt patch',
          estimatedCostTaka: 2800,
          summary: 'Dangerous structural depression.',
          analyzedAt: DateTime.now(),
          modelUsed: GeminiConfig.visionModel,
          latencyMs: 180,
          verificationResult: PotholeVerificationResult(
            potholeDetected: true,
            confidence: 0.91,
            reason: 'Dangerous 8 cm deep cavity.',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CameraScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Pothole Detected (91% Conf)'), findsOneWidget);
      expect(find.text('POTHOLE DETECTED'), findsOneWidget);
      expect(find.text('Alert'), findsOneWidget);
    });
  });
}
