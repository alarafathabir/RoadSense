import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const int kPort = 8080;

/// OpenStreetMap Client ID & Client Secret
const String kOsmClientId = 'g4UCcaXCCkbD5u52tLD0CdCZ_QkmrNHk6hqaldCRe2U';
const String kOsmClientSecret = 'DFk-DYU6tFax_U_ad002WGHgOVs6p1rbygFLvyohE1U';
const String kOsmAuthUrl = 'https://www.openstreetmap.org/oauth2/authorize';
const String kOsmTokenUrl = 'https://www.openstreetmap.org/oauth2/token';
const String kOsmApiBase = 'https://api.openstreetmap.org/api/0.6';

/// Gemini API Configuration
final String kGeminiApiKey =
    Platform.environment['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY';
const String kGeminiVisionModel = 'gemini-2.5-flash';
const String kGeminiModel = 'gemini-3.5-flash-lite';

void main() async {
  final uploadsDir = Directory('backend/uploads');
  if (!await uploadsDir.exists()) {
    await uploadsDir.create(recursive: true);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, kPort);
  stdout.writeln('[RoadSense Backend] Server listening on http://localhost:$kPort');
  stdout.writeln('[RoadSense Backend] Uploads directory: ${uploadsDir.absolute.path}');
  stdout.writeln('[RoadSense Backend] OpenStreetMap Client ID: $kOsmClientId');
  stdout.writeln('[RoadSense Backend] OpenStreetMap Integration: Ready');
  stdout.writeln('[RoadSense Backend] Gemini API Model: $kGeminiModel');
  stdout.writeln('[RoadSense Backend] Gemini Road Condition Evaluator: Ready');

  await for (HttpRequest request in server) {
    _handleRequest(request, uploadsDir);
  }
}

void _setCorsHeaders(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, DELETE');
  response.headers.set('Access-Control-Allow-Headers', '*');
  response.headers.set('Access-Control-Max-Age', '86400');
}

Future<void> _handleRequest(HttpRequest request, Directory uploadsDir) async {
  final response = request.response;
  _setCorsHeaders(response);

  final path = request.uri.path;
  final method = request.method;

  if (method == 'OPTIONS') {
    response.statusCode = HttpStatus.ok;
    await response.close();
    return;
  }

  try {
    // 1. Health check
    if (path == '/api/health') {
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({
        'status': 'healthy',
        'service': 'RoadSense Public Works Backend',
        'osmIntegration': 'Active',
        'geminiIntegration': 'Active',
        'timestamp': DateTime.now().toIso8601String(),
      }));
      await response.close();
      return;
    }

    // 1.1 Gemini Config & Status
    if (path == '/api/gemini/config' && method == 'GET') {
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({
        'success': true,
        'model': kGeminiModel,
        'apiKeyMasked': kGeminiApiKey.length > 14
            ? '${kGeminiApiKey.substring(0, 8)}...${kGeminiApiKey.substring(kGeminiApiKey.length - 6)}'
            : '••••••••',
        'status': 'Active',
        'capability': 'Multimodal Road Condition Evaluation (Alright / Not Alright)',
      }));
      await response.close();
      return;
    }

    // 1.2 Gemini Evaluate Road Image
    if (path == '/api/gemini/evaluate' && method == 'POST') {
      final content = await utf8.decoder.bind(request).join();
      final data = jsonDecode(content);
      final base64Image = (data['base64'] ?? data['imageBase64'] ?? '') as String;

      final client = HttpClient();
      try {
        final geminiUri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$kGeminiModel:generateContent?key=$kGeminiApiKey',
        );
        final req = await client.postUrl(geminiUri);
        req.headers.contentType = ContentType.json;

        final geminiBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Analyze this road photograph and evaluate whether the road condition is alright or not alright. Respond in JSON with isRoadAlright (boolean), verdict (string), severity (string), defectType (string), and summary (string).'
                },
                {
                  'inline_data': {
                    'mime_type': data['mimeType'] ?? 'image/jpeg',
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

        req.write(geminiBody);
        final res = await req.close();
        final resBody = await res.transform(utf8.decoder).join();

        response.statusCode = res.statusCode;
        response.headers.contentType = ContentType.json;
        response.write(resBody);
      } catch (e) {
        response.statusCode = HttpStatus.internalServerError;
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({'error': e.toString()}));
      } finally {
        client.close();
      }
      await response.close();
      return;
    }

    // 1.3 Gemini Strict Pothole Verification (gemini-2.5-flash)
    if (path == '/api/gemini/verify' && method == 'POST') {
      final content = await utf8.decoder.bind(request).join();
      final data = jsonDecode(content);
      final base64Image = (data['base64'] ?? data['imageBase64'] ?? '') as String;

      if (kGeminiApiKey.isEmpty || kGeminiApiKey == 'YOUR_GEMINI_API_KEY') {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({
          'pothole_detected': false,
          'confidence': 0.0,
          'reason': 'Gemini API key is not configured on backend server.',
        }));
        await response.close();
        return;
      }

      final client = HttpClient();
      try {
        final geminiUri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$kGeminiVisionModel:generateContent?key=$kGeminiApiKey',
        );
        final req = await client.postUrl(geminiUri);
        req.headers.contentType = ContentType.json;

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

        final geminiBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
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

        req.write(geminiBody);
        final geminiRes = await req.close();
        final resBody = await utf8.decoder.bind(geminiRes).join();

        response.headers.contentType = ContentType.json;
        if (geminiRes.statusCode == 200) {
          final resData = jsonDecode(resBody);
          final candidates = resData['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final text = candidates[0]['content']?['parts']?[0]?['text'] ?? '{}';
            response.write(text);
          } else {
            response.write(jsonEncode({
              'pothole_detected': false,
              'confidence': 0.0,
              'reason': 'No candidate returned by Gemini Vision.',
            }));
          }
        } else {
          response.statusCode = geminiRes.statusCode;
          response.write(jsonEncode({
            'pothole_detected': false,
            'confidence': 0.0,
            'reason': 'Gemini Vision returned status ${geminiRes.statusCode}',
          }));
        }
      } catch (e) {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({
          'pothole_detected': false,
          'confidence': 0.0,
          'reason': 'Server verification error: $e',
        }));
      } finally {
        client.close();
      }
      await response.close();
      return;
    }

    // 2. OpenStreetMap Configuration & Status
    if (path == '/api/osm/config' && method == 'GET') {
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({
        'success': true,
        'clientId': kOsmClientId,
        'clientSecretMasked': '${kOsmClientSecret.substring(0, 8)}...${kOsmClientSecret.substring(kOsmClientSecret.length - 6)}',
        'authUrl': kOsmAuthUrl,
        'tokenUrl': kOsmTokenUrl,
        'apiBase': kOsmApiBase,
        'scopes': ['read_prefs', 'write_api', 'write_notes'],
        'redirectUri': 'http://localhost:$kPort/api/osm/callback',
        'isConfigured': true,
        'connectedRegion': 'Saidpur, Rangpur, Bangladesh (88.88, 25.75 to 88.93, 25.80)',
      }));
      await response.close();
      return;
    }

    // 3. OpenStreetMap Test Connection
    if (path == '/api/osm/test' && method == 'GET') {
      final client = HttpClient();
      final stopwatch = Stopwatch()..start();
      try {
        final req = await client.getUrl(Uri.parse('$kOsmApiBase/capabilities'));
        req.headers.set('User-Agent', 'RoadSense-PW-Backend/1.0');
        final res = await req.close();
        stopwatch.stop();

        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({
          'success': res.statusCode == 200,
          'statusCode': res.statusCode,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': res.statusCode == 200
              ? 'OpenStreetMap API v0.6 is reachable and responsive.'
              : 'OpenStreetMap responded with status ${res.statusCode}',
          'clientId': kOsmClientId,
        }));
      } catch (e) {
        stopwatch.stop();
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({
          'success': false,
          'error': e.toString(),
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': 'Failed to reach OpenStreetMap server.',
        }));
      } finally {
        client.close();
      }
      await response.close();
      return;
    }

    // 4. OpenStreetMap Notes Proxy
    if (path == '/api/osm/notes' && method == 'GET') {
      final minLon = request.uri.queryParameters['minLon'] ?? '88.88';
      final minLat = request.uri.queryParameters['minLat'] ?? '25.75';
      final maxLon = request.uri.queryParameters['maxLon'] ?? '88.93';
      final maxLat = request.uri.queryParameters['maxLat'] ?? '25.80';

      final client = HttpClient();
      try {
        final osmUri = Uri.parse('$kOsmApiBase/notes.json?bbox=$minLon,$minLat,$maxLon,$maxLat');
        final req = await client.getUrl(osmUri);
        req.headers.set('User-Agent', 'RoadSense-PW-Backend/1.0');
        final res = await req.close();
        final body = await res.transform(utf8.decoder).join();

        response.statusCode = res.statusCode;
        response.headers.contentType = ContentType.json;
        response.write(body);
      } catch (e) {
        response.statusCode = HttpStatus.internalServerError;
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({'error': e.toString()}));
      } finally {
        client.close();
      }
      await response.close();
      return;
    }

    // 5. OpenStreetMap Publish Defect as Note
    if (path == '/api/osm/publish-note' && method == 'POST') {
      final content = await utf8.decoder.bind(request).join();
      final data = jsonDecode(content);

      final lat = data['latitude'] ?? data['lat'];
      final lon = data['longitude'] ?? data['lon'];
      final text = data['text'] ?? '[RoadSense PW Defect Report]';

      final client = HttpClient();
      try {
        final osmUri = Uri.parse('$kOsmApiBase/notes.json');
        final req = await client.postUrl(osmUri);
        req.headers.set('User-Agent', 'RoadSense-PW-Backend/1.0');
        req.headers.contentType = ContentType('application', 'x-www-form-urlencoded');

        final postBody = 'lat=${Uri.encodeComponent('$lat')}&lon=${Uri.encodeComponent('$lon')}&text=${Uri.encodeComponent('$text')}';
        req.write(postBody);
        final res = await req.close();
        final resBody = await res.transform(utf8.decoder).join();

        response.statusCode = res.statusCode;
        response.headers.contentType = ContentType.json;
        response.write(resBody);
      } catch (e) {
        response.statusCode = HttpStatus.internalServerError;
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({'error': e.toString()}));
      } finally {
        client.close();
      }
      await response.close();
      return;
    }

    // 6. OAuth 2.0 Callback Landing Page
    if (path == '/api/osm/callback' && method == 'GET') {
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];

      response.headers.contentType = ContentType.html;
      if (code != null) {
        response.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>RoadSense - OpenStreetMap Connected</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #063340; color: #fff; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #09495C; border: 1px solid #16A34A; border-radius: 16px; padding: 32px; max-width: 480px; text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.4); }
    h1 { color: #4ade80; margin-top: 0; }
    .code-box { background: #04242e; border: 1px dashed #38bdf8; padding: 12px; border-radius: 8px; word-break: break-all; font-family: monospace; color: #7dd3fc; margin: 16px 0; }
  </style>
</head>
<body>
  <div class="card">
    <h1>✓ OpenStreetMap Authorized</h1>
    <p>RoadSense PW has received the OAuth 2.0 authorization code from OpenStreetMap.</p>
    <div class="code-box">$code</div>
    <p style="font-size: 13px; color: #94a3b8;">You may now return to the RoadSense app.</p>
  </div>
</body>
</html>
        ''');
      } else {
        response.write('''
<!DOCTYPE html>
<html>
<head><title>RoadSense - OSM Auth</title></head>
<body style="font-family: sans-serif; background: #0f172a; color: #fff; text-align: center; padding: 40px;">
  <h2>OpenStreetMap OAuth: ${error ?? 'No code received'}</h2>
</body>
</html>
        ''');
      }
      await response.close();
      return;
    }

    // 7. Get current avatar metadata
    if (path == '/api/avatar' && method == 'GET') {
      final metaFile = File('backend/avatar_metadata.json');
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        response.headers.contentType = ContentType.json;
        response.write(content);
      } else {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({
          'hasCustomAvatar': false,
          'url': null,
        }));
      }
      await response.close();
      return;
    }

    // 8. Upload avatar
    if (path == '/api/upload-avatar' && method == 'POST') {
      List<int> bytes = [];
      await for (var chunk in request) {
        bytes.addAll(chunk);
      }

      if (bytes.isEmpty) {
        response.statusCode = HttpStatus.badRequest;
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({'error': 'No image data received'}));
        await response.close();
        return;
      }

      Uint8List imageBytes;
      String extension = 'png';

      try {
        final stringContent = utf8.decode(bytes);
        final parsedJson = jsonDecode(stringContent);
        if (parsedJson is Map && parsedJson.containsKey('base64')) {
          imageBytes = base64Decode(parsedJson['base64'] as String);
          if (parsedJson.containsKey('extension')) {
            extension = parsedJson['extension'] as String;
          }
        } else {
          imageBytes = Uint8List.fromList(bytes);
        }
      } catch (_) {
        imageBytes = Uint8List.fromList(bytes);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'avatar_$timestamp.$extension';
      final currentFileName = 'current_avatar.$extension';

      final uniqueFile = File('${uploadsDir.path}/$uniqueFileName');
      await uniqueFile.writeAsBytes(imageBytes);

      final currentFile = File('${uploadsDir.path}/$currentFileName');
      await currentFile.writeAsBytes(imageBytes);

      final publicUrl = 'http://localhost:$kPort/uploads/$currentFileName?t=$timestamp';

      final meta = {
        'hasCustomAvatar': true,
        'url': publicUrl,
        'filename': currentFileName,
        'sizeBytes': imageBytes.length,
        'uploadedAt': DateTime.now().toIso8601String(),
      };
      await File('backend/avatar_metadata.json').writeAsString(jsonEncode(meta));

      stdout.writeln('[RoadSense Backend] Saved avatar (${imageBytes.length} bytes) -> ${currentFile.path}');

      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({
        'success': true,
        'url': publicUrl,
        'size': imageBytes.length,
        'filename': currentFileName,
      }));
      await response.close();
      return;
    }

    // 9. Serve uploaded images
    if (path.startsWith('/uploads/')) {
      final fileName = path.substring('/uploads/'.length);
      final file = File('${uploadsDir.path}/$fileName');

      if (await file.exists()) {
        if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          response.headers.contentType = ContentType('image', 'jpeg');
        } else if (fileName.endsWith('.png')) {
          response.headers.contentType = ContentType('image', 'png');
        } else if (fileName.endsWith('.webp')) {
          response.headers.contentType = ContentType('image', 'webp');
        } else {
          response.headers.contentType = ContentType.binary;
        }

        await file.openRead().pipe(response);
        return;
      } else {
        response.statusCode = HttpStatus.notFound;
        response.write('Not Found');
        await response.close();
        return;
      }
    }

    // Default 404
    response.statusCode = HttpStatus.notFound;
    response.write('Not Found');
    await response.close();
  } catch (e, stack) {
    stderr.writeln('[RoadSense Backend Error] $e\n$stack');
    response.statusCode = HttpStatus.internalServerError;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({'error': e.toString()}));
    await response.close();
  }
}
