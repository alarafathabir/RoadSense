import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:road_sense/config/gemini_config.dart';
import 'package:road_sense/config/osm_config.dart';
import 'package:road_sense/services/gemini_road_service.dart';
import 'package:road_sense/services/location_service.dart';
import 'package:road_sense/services/osm_service.dart';

/// Represents a municipal road defect or hazard detected by RoadSense PW.
class RoadIssue {
  final String id;
  final String title;
  final String severity; // 'Urgent' | 'Medium' | 'Low'
  final String dimensionDetail; // '7cm deep', '4.2m long'
  final String location;
  final String coordinates;
  final String timestamp;
  final bool isPothole;

  const RoadIssue({
    required this.id,
    required this.title,
    required this.severity,
    required this.dimensionDetail,
    required this.location,
    required this.coordinates,
    required this.timestamp,
    required this.isPothole,
  });

  RoadIssue copyWith({
    String? id,
    String? title,
    String? severity,
    String? dimensionDetail,
    String? location,
    String? coordinates,
    String? timestamp,
    bool? isPothole,
  }) {
    return RoadIssue(
      id: id ?? this.id,
      title: title ?? this.title,
      severity: severity ?? this.severity,
      dimensionDetail: dimensionDetail ?? this.dimensionDetail,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      timestamp: timestamp ?? this.timestamp,
      isPothole: isPothole ?? this.isPothole,
    );
  }
}

/// Represents a municipal work order or repair dispatch item.
class RepairTask {
  final String id;
  String title;
  String location;
  String priority; // 'URGENT' | 'SCHEDULED' | 'ROUTINE'
  bool isDone;
  String assignedCrew;
  String scheduledDate;
  String notes;

  RepairTask({
    required this.id,
    required this.title,
    required this.location,
    required this.priority,
    this.isDone = false,
    this.assignedCrew = 'Unassigned',
    this.scheduledDate = 'Today',
    this.notes = '',
  });

  RepairTask copyWith({
    String? id,
    String? title,
    String? location,
    String? priority,
    bool? isDone,
    String? assignedCrew,
    String? scheduledDate,
    String? notes,
  }) {
    return RepairTask(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      assignedCrew: assignedCrew ?? this.assignedCrew,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      notes: notes ?? this.notes,
    );
  }
}

/// Global Application State for RoadSense PW (Bangladesh Public Works - Saidpur Division)
/// Provides a reactive ChangeNotifier singleton accessible via [AppState.instance].
class AppState extends ChangeNotifier {
  // Singleton instance
  static final AppState instance = AppState._internal();
  factory AppState() => instance;

  Timer? _speedTimer;

  AppState._internal() {
    _initDefaultIssues();
    _initDefaultTasks();
    _startSpeedSimulation();
    checkBackendSync();
    fetchRegionalOsmNotes();
    startLocationTracking();
  }

  // ---------------------------------------------------------
  // 1. Live Scan & Telemetry
  // ---------------------------------------------------------
  bool _isScanning = true;
  bool _isCameraFeedEnabled = true;
  bool _isAiDetectionEnabled = true;
  Uint8List? _customCameraPhotoBytes;
  String _cameraSource = 'windshield'; // 'windshield' or 'live'
  int _vehicleSpeed = 35;
  String _gpsStatus = 'GPS OK';
  bool _hazardDetected = true;
  bool _soundAlertForPotholes = true;
  DateTime _lastBeepTime = DateTime.now();

  bool get isScanning => _isScanning;
  bool get isCameraFeedEnabled => _isCameraFeedEnabled;
  bool get isAiDetectionEnabled => _isAiDetectionEnabled;
  Uint8List? get customCameraPhotoBytes => _customCameraPhotoBytes;
  String get cameraSource => _cameraSource;
  int get vehicleSpeed => _vehicleSpeed;
  String get gpsStatus => _gpsStatus;
  bool get hazardDetected => _hazardDetected;
  bool get soundAlertForPotholes => _soundAlertForPotholes;
  DateTime get lastBeepTime => _lastBeepTime;

  void toggleScanning([bool? value]) {
    _isScanning = value ?? !_isScanning;
    if (!_isScanning) {
      _vehicleSpeed = 0;
    } else {
      _vehicleSpeed = 35;
    }
    notifyListeners();
  }

  void toggleCameraFeed([bool? value]) {
    _isCameraFeedEnabled = value ?? !_isCameraFeedEnabled;
    notifyListeners();
  }

  void toggleAiDetection([bool? value]) {
    _isAiDetectionEnabled = value ?? !_isAiDetectionEnabled;
    notifyListeners();
  }

  void setCustomCameraPhoto(Uint8List? bytes) {
    _customCameraPhotoBytes = bytes;
    if (bytes != null) {
      _cameraSource = 'live';
      _isCameraFeedEnabled = true;
      evaluateCurrentPhotoWithGemini(bytes);
    } else {
      _currentRoadEvaluation = null;
    }
    notifyListeners();
  }

  void setCameraSource(String source) {
    _cameraSource = source;
    notifyListeners();
  }

  void toggleSoundAlert(bool val) {
    _soundAlertForPotholes = val;
    notifyListeners();
  }

  void setHazardDetected(bool detected) {
    _hazardDetected = detected;
    notifyListeners();
  }

  void setVehicleSpeed(int speed) {
    _vehicleSpeed = speed;
    notifyListeners();
  }

  void setGpsStatus(String status) {
    _gpsStatus = status;
    notifyListeners();
  }

  /// Plays a simulated sound and haptic alert for pothole/hazard detection.
  void audioBeep() {
    _lastBeepTime = DateTime.now();
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Graceful fallback on web or unsupported runtimes
    }
    notifyListeners();
  }

  void _startSpeedSimulation() {
    _speedTimer?.cancel();
    const speeds = [35, 36, 37, 35, 34, 33, 36, 38, 35, 34];
    int index = 0;
    _speedTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isScanning) {
        index = (index + 1) % speeds.length;
        _vehicleSpeed = speeds[index];
        notifyListeners();
      }
    });
  }

  void stopSpeedSimulation() {
    _speedTimer?.cancel();
    _speedTimer = null;
  }

  void startSpeedSimulation() {
    _startSpeedSimulation();
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------
  // 2. Today's Summary & Telemetry
  // ---------------------------------------------------------
  double _roadsCheckedKm = 142.0;
  int _roadHealthPct = 78;
  int _potholesFound = 14;
  int _urgentFixes = 3;

  double get roadsCheckedKm => _roadsCheckedKm;
  int get roadHealthPct => _roadHealthPct;
  int get potholesFound => _potholesFound;
  int get urgentFixes => _urgentFixes;

  void updateTelemetry({
    double? roadsCheckedKm,
    int? roadHealthPct,
    int? potholesFound,
    int? urgentFixes,
  }) {
    if (roadsCheckedKm != null) _roadsCheckedKm = roadsCheckedKm;
    if (roadHealthPct != null) _roadHealthPct = roadHealthPct;
    if (potholesFound != null) _potholesFound = potholesFound;
    if (urgentFixes != null) _urgentFixes = urgentFixes;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // 3. Budget & Crews
  // ---------------------------------------------------------
  int _monthlyBudgetSpent = 42500;
  int _monthlyBudgetTotal = 60000;
  int _activeCrews = 7;

  int get monthlyBudgetSpent => _monthlyBudgetSpent;
  int get monthlyBudgetTotal => _monthlyBudgetTotal;
  int get activeCrews => _activeCrews;
  int get monthlyBudgetRemaining => _monthlyBudgetTotal - _monthlyBudgetSpent;
  double get budgetSpentRatio =>
      _monthlyBudgetTotal > 0 ? (_monthlyBudgetSpent / _monthlyBudgetTotal) : 0.0;

  // ---------------------------------------------------------
  // Budget Analytics: Component Breakdown & Proactive Savings
  // ---------------------------------------------------------
  // Material / Resource Breakdown:
  // Asphalt/Bitumen mix: 48%, Labor & Crew wages: 32%, Heavy Equipment: 20%
  int get asphaltCost => (_monthlyBudgetSpent * 0.48).round();
  int get laborCost => (_monthlyBudgetSpent * 0.32).round();
  int get equipmentCost => (_monthlyBudgetSpent * 0.20).round();

  double get asphaltPct => 48.0;
  double get laborPct => 32.0;
  double get equipmentPct => 20.0;

  // Proactive Savings Engine:
  // Timely patch repairs cost ~1/3.8 of delayed reactive reconstruction after road base collapse
  double get reactiveCostMultiplier => 3.8;
  int get estimatedReactiveCost => (_monthlyBudgetSpent * reactiveCostMultiplier).round();
  int get proactiveSavings => estimatedReactiveCost - _monthlyBudgetSpent;
  int get proactiveSavingsPct => 74; // ((3.8 - 1) / 3.8 * 100)

  void updateBudget({int? spent, int? total, int? crews}) {
    if (spent != null) _monthlyBudgetSpent = spent;
    if (total != null) _monthlyBudgetTotal = total;
    if (crews != null) _activeCrews = crews;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // 4. Inspector & Shift Info
  // ---------------------------------------------------------
  String _inspectorName = 'Abir';
  String _inspectorTitle = 'Bangladesh Public Works Inspector';
  String _shiftId = '#BPW-Saidpur-4820';
  bool _isOnDuty = true;
  String _vehicleName = 'Truck #14';
  String _vehicleModel = 'Mahindra Bolero BPW Patrol Unit';
  bool _cameraGpsConnected = true;
  bool _autoSavePotholes = true;
  bool _voiceAlerts = true;
  bool _offlineStorage = true;

  // Inspector Avatar Profile Customization
  String _inspectorAvatarAsset = 'assets/images/inspector_avatar.png';
  String? _customAvatarUrl;
  Uint8List? _customAvatarBytes;
  String? _customInitials;
  Color? _customAvatarColor;

  String get inspectorName => _inspectorName;
  String get inspectorTitle => _inspectorTitle;
  String get shiftId => _shiftId;
  bool get isOnDuty => _isOnDuty;
  String get vehicleName => _vehicleName;
  String get vehicleModel => _vehicleModel;
  bool get cameraGpsConnected => _cameraGpsConnected;
  bool get autoSavePotholes => _autoSavePotholes;
  bool get voiceAlerts => _voiceAlerts;
  bool get offlineStorage => _offlineStorage;

  String get inspectorAvatarAsset => _inspectorAvatarAsset;
  String? get customAvatarUrl => _customAvatarUrl;
  Uint8List? get customAvatarBytes => _customAvatarBytes;
  String? get customInitials => _customInitials;
  Color? get customAvatarColor => _customAvatarColor;
  String? _serverAvatarUrl;
  bool _isBackendConnected = false;

  String? get serverAvatarUrl => _serverAvatarUrl;
  bool get isBackendConnected => _isBackendConnected;

  bool get hasCustomAvatar =>
      _customAvatarBytes != null ||
      _customAvatarUrl != null ||
      _customInitials != null ||
      _inspectorAvatarAsset != 'assets/images/inspector_avatar.png';

  Future<void> checkBackendSync() async {
    try {
      final res = await http
          .get(Uri.parse('http://localhost:8080/api/avatar'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        _isBackendConnected = true;
        final data = jsonDecode(res.body);
        if (data is Map &&
            data['hasCustomAvatar'] == true &&
            data['url'] != null) {
          _serverAvatarUrl = data['url'] as String;
          if (_customAvatarBytes == null && _customAvatarUrl == null) {
            _customAvatarUrl = _serverAvatarUrl;
          }
        }
        notifyListeners();
      }
    } catch (_) {
      _isBackendConnected = false;
    }
  }

  Future<bool> uploadAvatarToBackend(Uint8List bytes,
      [String extension = 'png']) async {
    setInspectorAvatarBytes(bytes);
    try {
      final res = await http
          .post(
            Uri.parse('http://localhost:8080/api/upload-avatar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'base64': base64Encode(bytes),
              'extension': extension,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['url'] != null) {
          _serverAvatarUrl = data['url'] as String;
          _isBackendConnected = true;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AppState] Upload to backend failed (fallback to memory): $e');
    }
    return false;
  }

  void setInspectorAvatarBytes(Uint8List bytes) {
    _customAvatarBytes = bytes;
    _customAvatarUrl = null;
    _customInitials = null;
    _customAvatarColor = null;
    notifyListeners();
  }

  void setInspectorAvatarAsset(String assetPath) {
    _inspectorAvatarAsset = assetPath;
    _customAvatarBytes = null;
    _customAvatarUrl = null;
    _customInitials = null;
    _customAvatarColor = null;
    notifyListeners();
  }

  void setInspectorAvatarUrl(String url) {
    _customAvatarUrl = url.trim();
    _customAvatarBytes = null;
    _customInitials = null;
    _customAvatarColor = null;
    notifyListeners();
  }

  void setInspectorInitials(String initials, Color bgColor) {
    _customInitials = initials;
    _customAvatarColor = bgColor;
    _customAvatarBytes = null;
    _customAvatarUrl = null;
    notifyListeners();
  }

  void resetInspectorAvatar() {
    _inspectorAvatarAsset = 'assets/images/inspector_avatar.png';
    _customAvatarBytes = null;
    _customAvatarUrl = null;
    _customInitials = null;
    _customAvatarColor = null;
    notifyListeners();
  }

  void toggleDuty([bool? val]) {
    _isOnDuty = val ?? !_isOnDuty;
    notifyListeners();
  }

  void toggleAutoSave([bool? val]) {
    _autoSavePotholes = val ?? !_autoSavePotholes;
    notifyListeners();
  }

  void toggleVoiceAlerts([bool? val]) {
    _voiceAlerts = val ?? !_voiceAlerts;
    notifyListeners();
  }

  void toggleOfflineStorage([bool? val]) {
    _offlineStorage = val ?? !_offlineStorage;
    notifyListeners();
  }

  void toggleCameraGps([bool? val]) {
    _cameraGpsConnected = val ?? !_cameraGpsConnected;
    notifyListeners();
  }

  void updateInspector({
    String? name,
    String? title,
    String? shiftId,
    bool? cameraGpsConnected,
  }) {
    if (name != null) _inspectorName = name;
    if (title != null) _inspectorTitle = title;
    if (shiftId != null) _shiftId = shiftId;
    if (cameraGpsConnected != null) _cameraGpsConnected = cameraGpsConnected;
    notifyListeners();
  }

  void changeVehicle(String name, String model) {
    _vehicleName = name;
    _vehicleModel = model;
    notifyListeners();
  }

  // ---------------------------------------------------------
  // 5. Recent Issues (23 pre-populated items)
  // ---------------------------------------------------------
  final List<RoadIssue> _recentIssues = [];
  final List<RoadIssue> _activeShiftIssues = [];
  final List<RoadIssue> _resolvedIssues = [];

  List<RoadIssue> get recentIssues => List.unmodifiable(_recentIssues);
  List<RoadIssue> get activeShiftIssues => List.unmodifiable(_activeShiftIssues);
  List<RoadIssue> get resolvedIssues => List.unmodifiable(_resolvedIssues);
  int get totalIssuesCount => _recentIssues.length;
  int get resolvedIssuesCount => _resolvedIssues.length;

  void reportIssue(RoadIssue issue) {
    _recentIssues.insert(0, issue);
    _activeShiftIssues.insert(0, issue);
    if (issue.isPothole) {
      _potholesFound++;
      if (_soundAlertForPotholes) {
        audioBeep();
      }
    }
    if (issue.severity.toUpperCase() == 'URGENT') {
      _urgentFixes++;
      _roadHealthPct = (_roadHealthPct - 3).clamp(0, 100);
    } else {
      _roadHealthPct = (_roadHealthPct - 1).clamp(0, 100);
    }
    notifyListeners();
  }

  void resolveIssue(String id) {
    final index = _recentIssues.indexWhere((item) => item.id == id);
    RoadIssue? issue;
    if (index != -1) {
      issue = _recentIssues.removeAt(index);
      _resolvedIssues.insert(0, issue);
    } else {
      final shiftIndex = _activeShiftIssues.indexWhere((item) => item.id == id);
      if (shiftIndex != -1) {
        issue = _activeShiftIssues[shiftIndex];
        _resolvedIssues.insert(0, issue);
      }
    }
    _activeShiftIssues.removeWhere((item) => item.id == id);
    if (issue != null) {
      if (issue.severity.toUpperCase() == 'URGENT' && _urgentFixes > 0) {
        _urgentFixes--;
        _roadHealthPct = (_roadHealthPct + 3).clamp(0, 100);
      } else {
        _roadHealthPct = (_roadHealthPct + 1).clamp(0, 100);
      }
      if (issue.isPothole && _potholesFound > 0) {
        _potholesFound--;
      }
      notifyListeners();
    }
  }

  void reopenIssue(String id) {
    final index = _resolvedIssues.indexWhere((item) => item.id == id);
    if (index != -1) {
      final issue = _resolvedIssues.removeAt(index);
      reportIssue(issue);
    }
  }

  void resetDefaultIssues() {
    _recentIssues.clear();
    _activeShiftIssues.clear();
    _resolvedIssues.clear();
    _initDefaultIssues();
    notifyListeners();
  }

  void removeIssue(String id) {
    _recentIssues.removeWhere((item) => item.id == id);
    _activeShiftIssues.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void _initDefaultIssues() {
    _recentIssues.addAll([
      // Primary 2 Active Shift Issues (Saidpur, Rangpur)
      const RoadIssue(
        id: 'issue-1',
        title: 'Airport Road Pothole',
        severity: 'Urgent',
        dimensionDetail: '7cm deep',
        location: 'Airport Road near BAUST',
        coordinates: '25.7685° N, 88.9080° E',
        timestamp: '4m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-2',
        title: 'Sailar Mor Asphalt Crack',
        severity: 'Medium',
        dimensionDetail: '4.2m long',
        location: 'Sailar Mor & Cantt Road',
        coordinates: '25.7745° N, 88.9012° E',
        timestamp: '18m ago',
        isPothole: false,
      ),
      // 21 Additional issues covering Saidpur's major landmarks
      const RoadIssue(
        id: 'issue-3',
        title: 'Cantt Bazar Road Pothole',
        severity: 'Urgent',
        dimensionDetail: '8cm deep',
        location: 'Cantt Bazar, Saidpur',
        coordinates: '25.7815° N, 88.9050° E',
        timestamp: '32m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-4',
        title: 'BAUST Gate Culvert Void',
        severity: 'Urgent',
        dimensionDetail: '9cm deep',
        location: 'BAUST Main Campus Gate',
        coordinates: '25.7680° N, 88.9120° E',
        timestamp: '45m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-5',
        title: 'Saidpur Central Terminal Rutting',
        severity: 'Medium',
        dimensionDetail: '3.5m rut',
        location: 'Central Bus Terminal Roundabout',
        coordinates: '25.7875° N, 88.8890° E',
        timestamp: '1h ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-6',
        title: 'Saidpur Bazar Edge Pavement Void',
        severity: 'Medium',
        dimensionDetail: '6.5cm deep',
        location: 'Saidpur Bazar Gate 1',
        coordinates: '25.7760° N, 88.8905° E',
        timestamp: '1h 15m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-7',
        title: 'Railway Station Approach Spall',
        severity: 'Medium',
        dimensionDetail: '2.8m spall',
        location: 'Saidpur Railway Station Plaza',
        coordinates: '25.7785° N, 88.8925° E',
        timestamp: '1h 30m ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-8',
        title: 'Church Road Surface Crack',
        severity: 'Low',
        dimensionDetail: '3.1m line',
        location: 'Church Road near Christian Church',
        coordinates: '25.7730° N, 88.8940° E',
        timestamp: '2h ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-9',
        title: 'Taste & GO Restaurant Road Seam',
        severity: 'Medium',
        dimensionDetail: '2.4m seam',
        location: 'Station Road opposite Taste & GO Restaurant',
        coordinates: '25.7792° N, 88.8938° E',
        timestamp: '2h 15m ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-10',
        title: 'Waffle Street Restaurant Pothole',
        severity: 'Medium',
        dimensionDetail: '7.5cm deep',
        location: 'Cantt Road near Waffle Street Restaurant',
        coordinates: '25.7820° N, 88.9045° E',
        timestamp: '2h 30m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-11',
        title: 'Airport Runway Approach Shoulder Dip',
        severity: 'Low',
        dimensionDetail: '1.8m dip',
        location: 'Airport Road South Terminal',
        coordinates: '25.7592° N, 88.9085° E',
        timestamp: '2h 45m ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-12',
        title: 'Sailar Mor Roundabout Cavity',
        severity: 'Medium',
        dimensionDetail: '8.2cm deep',
        location: 'Sailar Mor North Crossing',
        coordinates: '25.7750° N, 88.9010° E',
        timestamp: '3h ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-13',
        title: 'Cantt Bazar Commercial Strip Crack',
        severity: 'Medium',
        dimensionDetail: '3.6m seam',
        location: 'Cantt Bazar East Lane',
        coordinates: '25.7825° N, 88.9065° E',
        timestamp: '3h 20m ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-14',
        title: 'BAUST Faculty Housing Lane Pothole',
        severity: 'Medium',
        dimensionDetail: '6.8cm deep',
        location: 'BAUST Campus North Road',
        coordinates: '25.7695° N, 88.9135° E',
        timestamp: '3h 45m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-15',
        title: 'Saidpur Railway Workshop Gate Void',
        severity: 'Medium',
        dimensionDetail: '7.9cm drop',
        location: 'Railway Workshop Main Gate',
        coordinates: '25.7800° N, 88.8950° E',
        timestamp: '4h ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-16',
        title: 'Saidpur Bazar Outer Ring Depression',
        severity: 'Medium',
        dimensionDetail: '4.1m dip',
        location: 'Saidpur Bazar Outer Ring',
        coordinates: '25.7770° N, 88.8915° E',
        timestamp: '4h 15m ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-17',
        title: 'Central Terminal Bypass Seam',
        severity: 'Medium',
        dimensionDetail: '3.4m seam',
        location: 'Terminal Bypass Highway',
        coordinates: '25.7885° N, 88.8875° E',
        timestamp: '5h ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-18',
        title: 'Christian Church Road Manhole Rim Void',
        severity: 'Medium',
        dimensionDetail: '8.2cm drop',
        location: 'Church Road & Mission Lane',
        coordinates: '25.7725° N, 88.8955° E',
        timestamp: '5h 30m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-19',
        title: 'Taste & GO Food Alley Pavement Ripple',
        severity: 'Low',
        dimensionDetail: '2.8m ripple',
        location: 'College Road near Taste & GO Restaurant',
        coordinates: '25.7798° N, 88.8932° E',
        timestamp: '6h ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-20',
        title: 'Waffle Street Cafe Frontage Void',
        severity: 'Medium',
        dimensionDetail: '7.1cm deep',
        location: 'Cantt Commercial Strip near Waffle Street',
        coordinates: '25.7818° N, 88.9040° E',
        timestamp: '6h 30m ago',
        isPothole: true,
      ),
      const RoadIssue(
        id: 'issue-21',
        title: 'Saidpur Officers Club Approach Settlement',
        severity: 'Medium',
        dimensionDetail: '4.5cm dip',
        location: 'Airport Road Officers Enclave',
        coordinates: '25.7640° N, 88.9095° E',
        timestamp: '7h ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-22',
        title: 'Kharikhola River Bridge Approach Spall',
        severity: 'Low',
        dimensionDetail: '0.8m spall',
        location: 'Sailar Mor River Crossing',
        coordinates: '25.7735° N, 88.9030° E',
        timestamp: '7h 45m ago',
        isPothole: false,
      ),
      const RoadIssue(
        id: 'issue-23',
        title: 'Saidpur Plaza Market Entrance Pothole',
        severity: 'Medium',
        dimensionDetail: '6.8cm deep',
        location: 'Saidpur Bazar Market Hub',
        coordinates: '25.7755° N, 88.8900° E',
        timestamp: '8h ago',
        isPothole: true,
      ),
    ]);
    if (_recentIssues.length >= 2) {
      _activeShiftIssues.addAll([
        _recentIssues[0],
        _recentIssues[1],
      ]);
    }
    _urgentFixes = _recentIssues
        .where((i) => i.severity.toUpperCase() == 'URGENT')
        .length;
  }

  // ---------------------------------------------------------
  // 6. Repair Tasks (3 Active + 24 Completed = 27 Total)
  // ---------------------------------------------------------
  final List<RepairTask> _repairTasks = [];

  List<RepairTask> get allTasks => List.unmodifiable(_repairTasks);
  List<RepairTask> get pendingTasks =>
      _repairTasks.where((task) => !task.isDone).toList();
  List<RepairTask> get completedTasks =>
      _repairTasks.where((task) => task.isDone).toList();
  List<RepairTask> get toDoTasks => pendingTasks;
  List<RepairTask> get doneTasks => completedTasks;
  int get doneTasksCount => completedTasks.length;
  int get urgentTasksCount =>
      pendingTasks.where((t) => t.priority.toUpperCase() == 'URGENT').length;

  void addRepairTask(
    String title,
    String location,
    String priority, {
    String assignedCrew = 'Unassigned',
    String scheduledDate = 'Today',
    String notes = '',
  }) {
    final newTask = RepairTask(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      location: location,
      priority: priority.toUpperCase(),
      isDone: false,
      assignedCrew: assignedCrew,
      scheduledDate: scheduledDate,
      notes: notes,
    );
    _repairTasks.insert(0, newTask);

    // Also link and display as 1st item in Recent Issues on Home Screen
    final isUrgent = priority.toUpperCase() == 'URGENT';
    final severity = isUrgent
        ? 'Urgent'
        : (priority.toUpperCase() == 'SCHEDULED' ? 'Medium' : 'Low');
    final isPothole = title.toLowerCase().contains('pothole') ||
        title.toLowerCase().contains('hole') ||
        title.toLowerCase().contains('void');
    final newIssue = RoadIssue(
      id: 'issue-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      severity: severity,
      dimensionDetail: notes.isNotEmpty
          ? notes
          : (isPothole ? '7.5cm deep cavity' : '3.6m asphalt crack'),
      location: location,
      coordinates: '25.7760° N, 88.9020° E',
      timestamp: 'Just now',
      isPothole: isPothole,
    );
    _recentIssues.insert(0, newIssue);
    _activeShiftIssues.insert(0, newIssue);

    if (isUrgent) {
      _urgentFixes++;
      _roadHealthPct = (_roadHealthPct - 2).clamp(0, 100);
    } else {
      _roadHealthPct = (_roadHealthPct - 1).clamp(0, 100);
    }
    if (isPothole) {
      _potholesFound++;
    }
    notifyListeners();
  }

  void sendRepairCrew(String taskId, [String? crewName, bool markResolved = false]) {
    final index = _repairTasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final current = _repairTasks[index];
      current.assignedCrew = crewName ?? 'Crew #3 (Dispatched)';
      current.notes = current.notes.isEmpty
          ? 'Crew dispatched via RoadSense PW dispatch'
          : '${current.notes} | Dispatched';
      if (markResolved && !current.isDone) {
        toggleTaskDone(taskId);
      } else {
        notifyListeners();
      }
    }
  }

  void toggleTaskDone(String taskId) {
    final index = _repairTasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _repairTasks[index];
      task.isDone = !task.isDone;
      if (task.isDone) {
        if (task.priority.toUpperCase() == 'URGENT' && _urgentFixes > 0) {
          _urgentFixes--;
        }
        if (task.title.toLowerCase().contains('pothole') && _potholesFound > 0) {
          _potholesFound--;
        }
        _roadHealthPct = (_roadHealthPct + 3).clamp(0, 100);
        _monthlyBudgetSpent =
            (_monthlyBudgetSpent + 650).clamp(0, _monthlyBudgetTotal);
      } else {
        if (task.priority.toUpperCase() == 'URGENT') {
          _urgentFixes++;
        }
        if (task.title.toLowerCase().contains('pothole')) {
          _potholesFound++;
        }
        _roadHealthPct = (_roadHealthPct - 2).clamp(0, 100);
      }
      notifyListeners();
    }
  }

  void _initDefaultTasks() {
    _repairTasks.addAll([
      // 3 Required Active Tasks (Saidpur, Rangpur)
      RepairTask(
        id: 'task-1',
        title: 'Airport Road Pothole Fix',
        location: 'Airport Road near BAUST',
        priority: 'URGENT',
        isDone: false,
        assignedCrew: 'Crew #3',
        scheduledDate: 'Today, 2:00 PM',
        notes: 'Severe 7cm cavity in eastbound lane near BAUST Gate',
      ),
      RepairTask(
        id: 'task-2',
        title: 'Sailar Mor Crack Sealing',
        location: 'Sailar Mor & Cantt Road',
        priority: 'SCHEDULED',
        isDone: false,
        assignedCrew: 'Crew #1',
        scheduledDate: 'Tomorrow, 9:00 AM',
        notes: 'Longitudinal cracking 4.2m along outer shoulder',
      ),
      RepairTask(
        id: 'task-3',
        title: 'Saidpur Bazar Resurfacing',
        location: 'Saidpur Bazar & Station Road',
        priority: 'ROUTINE',
        isDone: false,
        assignedCrew: 'Crew #5',
        scheduledDate: 'Friday, 8:00 AM',
        notes: 'Surface wear and minor raveling across market entry',
      ),

      // Exactly 24 Completed Tasks for 'Done (24)'
      RepairTask(
        id: 'done-1',
        title: 'Cantt Bazar Asphalt Patching',
        location: 'Cantt Bazar Main Road',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #2',
        scheduledDate: 'Yesterday',
        notes: 'Cold mix patch completed and rolled',
      ),
      RepairTask(
        id: 'done-2',
        title: 'BAUST Campus Entrance Curb Repair',
        location: 'BAUST Main Gate Road',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #4',
        scheduledDate: 'Yesterday',
        notes: 'Precast curb section reset',
      ),
      RepairTask(
        id: 'done-3',
        title: 'Central Terminal Drain Clearing',
        location: 'Central Bus Terminal Roundabout',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #1',
        scheduledDate: 'Oct 25',
        notes: 'Catch basin debris vacuumed',
      ),
      RepairTask(
        id: 'done-4',
        title: 'Taste & GO Restaurant Joint Sealing',
        location: 'Station Road opposite Taste & GO Restaurant',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #6',
        scheduledDate: 'Oct 24',
        notes: 'Hot-pour mastic applied',
      ),
      RepairTask(
        id: 'done-5',
        title: 'Waffle Street Restaurant Pothole Fix',
        location: 'Cantt Road near Waffle Street Restaurant',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #3',
        scheduledDate: 'Oct 24',
        notes: 'Rapid set mastic patch',
      ),
      RepairTask(
        id: 'done-6',
        title: 'Church Road Speed Table Re-leveling',
        location: 'Church Road near Christian Church',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #2',
        scheduledDate: 'Oct 23',
        notes: 'Asphalt taper reapplied',
      ),
      RepairTask(
        id: 'done-7',
        title: 'Railway Station Plaza Striping & Patching',
        location: 'Saidpur Railway Station Plaza',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #7',
        scheduledDate: 'Oct 23',
        notes: 'Thermoplastic line striping',
      ),
      RepairTask(
        id: 'done-8',
        title: 'Sailar Mor North Depression Fill',
        location: 'Sailar Mor Junction',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #3',
        scheduledDate: 'Oct 22',
        notes: 'Filled and leveled with hot mix',
      ),
      RepairTask(
        id: 'done-9',
        title: 'Airport Runway Approach Crack Seal',
        location: 'Airport Road South Terminal',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #1',
        scheduledDate: 'Oct 22',
        notes: 'Rubberized asphalt emulsion',
      ),
      RepairTask(
        id: 'done-10',
        title: 'Saidpur Officers Club Road Leveling',
        location: 'Airport Road Officers Enclave',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #5',
        scheduledDate: 'Oct 21',
        notes: 'Micro-surfacing overlay',
      ),
      RepairTask(
        id: 'done-11',
        title: 'Terminal Bypass Highway Pothole Repair',
        location: 'Terminal Bypass Highway',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #2',
        scheduledDate: 'Oct 21',
        notes: 'Milled edge and hot asphalt compacted',
      ),
      RepairTask(
        id: 'done-12',
        title: 'Kharikhola Bridge Shoulder Fix',
        location: 'Sailar Mor River Crossing',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #4',
        scheduledDate: 'Oct 20',
        notes: 'Gravel shoulder regraded',
      ),
      RepairTask(
        id: 'done-13',
        title: 'BAUST Faculty Housing Crack Fill',
        location: 'BAUST Campus North Road',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #6',
        scheduledDate: 'Oct 20',
        notes: 'Fiber-reinforced crack sealant applied',
      ),
      RepairTask(
        id: 'done-14',
        title: 'Saidpur Bazar Gate 1 Manhole Leveling',
        location: 'Saidpur Bazar Gate 1',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #1',
        scheduledDate: 'Oct 19',
        notes: 'Concrete collar ring rebuilt',
      ),
      RepairTask(
        id: 'done-15',
        title: 'Railway Workshop Road Surface Treatment',
        location: 'Railway Workshop Main Gate',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #5',
        scheduledDate: 'Oct 19',
        notes: 'Chip seal coat completed',
      ),
      RepairTask(
        id: 'done-16',
        title: 'Cantt Commercial Strip Rutting Repair',
        location: 'Cantt Bazar Commercial Strip',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #7',
        scheduledDate: 'Oct 18',
        notes: 'Tandem roller leveling',
      ),
      RepairTask(
        id: 'done-17',
        title: 'Taste & GO Food Alley Utility Trench Patch',
        location: 'College Road near Taste & GO Restaurant',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #2',
        scheduledDate: 'Oct 18',
        notes: 'Permanent asphalt concrete restoration',
      ),
      RepairTask(
        id: 'done-18',
        title: 'Waffle Street Cafe Corner Edge Seal',
        location: 'Cantt Commercial Strip near Waffle Street',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #4',
        scheduledDate: 'Oct 17',
        notes: 'Poured hot rubber seal',
      ),
      RepairTask(
        id: 'done-19',
        title: 'Saidpur Plaza Market Entrance Pothole Fix',
        location: 'Saidpur Bazar Market Hub',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #3',
        scheduledDate: 'Oct 17',
        notes: 'Emergency deep patch',
      ),
      RepairTask(
        id: 'done-20',
        title: 'Airport Road North Gravel Shoulders',
        location: 'Airport Road North Link',
        priority: 'ROUTINE',
        isDone: true,
        assignedCrew: 'Crew #6',
        scheduledDate: 'Oct 16',
        notes: 'Crushed stone aggregate added',
      ),
      RepairTask(
        id: 'done-21',
        title: 'Christian Church East Lane Sealcoating',
        location: 'Church Road & Mission Lane',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #1',
        scheduledDate: 'Oct 16',
        notes: 'Coal tar pitch emulsion applied',
      ),
      RepairTask(
        id: 'done-22',
        title: 'Bangabandhu Road Subbase Repair',
        location: 'Saidpur Bazar Outer Ring',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #5',
        scheduledDate: 'Oct 15',
        notes: 'Subbase excavation and patch',
      ),
      RepairTask(
        id: 'done-23',
        title: 'Saidpur Bus Terminal Entry Patch',
        location: 'Central Bus Terminal Entry',
        priority: 'URGENT',
        isDone: true,
        assignedCrew: 'Crew #3',
        scheduledDate: 'Oct 15',
        notes: 'Polymer modified asphalt overlay',
      ),
      RepairTask(
        id: 'done-24',
        title: 'Cantonment Board School Crosswalk Patch',
        location: 'Cantt Bazar School Link',
        priority: 'SCHEDULED',
        isDone: true,
        assignedCrew: 'Crew #7',
        scheduledDate: 'Oct 14',
        notes: 'High-visibility epoxy patch',
      ),
    ]);
  }

  // ---------------------------------------------------------
  // 8. OpenStreetMap (OSM) OAuth 2.0 & Defect Synchronization
  // ---------------------------------------------------------
  bool _isOsmConnected = true;
  bool _isOsmAutoSync = true;
  final String _osmAccountName = 'RoadSense Public Works Inspector (BPW)';
  List<OsmNote> _osmNotes = [];
  final Set<String> _osmSyncedDefectIds = {'pin-1', 'pin-5'};
  final Map<String, int> _defectToOsmNoteId = {'pin-1': 4028971, 'pin-5': 4028969};
  bool _isTestingOsm = false;
  OsmTestResult? _lastOsmTestResult;
  DateTime? _lastOsmSyncTime = DateTime.now();

  String get osmClientId => OsmConfig.clientId;
  String get osmClientSecret => OsmConfig.clientSecret;
  String get osmMaskedSecret => OsmConfig.maskedSecret;
  bool get isOsmConnected => _isOsmConnected;
  bool get isOsmAutoSync => _isOsmAutoSync;
  String get osmAccountName => _osmAccountName;
  List<OsmNote> get osmNotes => List.unmodifiable(_osmNotes);
  Set<String> get osmSyncedDefectIds => Set.unmodifiable(_osmSyncedDefectIds);
  bool get isTestingOsm => _isTestingOsm;
  OsmTestResult? get lastOsmTestResult => _lastOsmTestResult;
  DateTime? get lastOsmSyncTime => _lastOsmSyncTime;

  bool isDefectSynced(String defectId) => _osmSyncedDefectIds.contains(defectId);
  int? getOsmNoteId(String defectId) => _defectToOsmNoteId[defectId];

  void toggleOsmAutoSync([bool? val]) {
    _isOsmAutoSync = val ?? !_isOsmAutoSync;
    notifyListeners();
  }

  void toggleOsmConnection([bool? val]) {
    _isOsmConnected = val ?? !_isOsmConnected;
    notifyListeners();
  }

  /// Tests connectivity to OpenStreetMap API v0.6 and verifies OAuth 2.0 client credentials.
  Future<OsmTestResult> testOsmConnection() async {
    _isTestingOsm = true;
    notifyListeners();

    try {
      final result = await OsmService.instance.testConnection();
      _lastOsmTestResult = result;
      _isTestingOsm = false;
      if (result.success) {
        _isOsmConnected = true;
      }
      notifyListeners();
      return result;
    } catch (e) {
      final fallback = OsmTestResult(
        success: false,
        message: 'Error testing OSM connection: $e',
        latencyMs: 0,
        apiAvailable: false,
        oauthValidated: false,
      );
      _lastOsmTestResult = fallback;
      _isTestingOsm = false;
      notifyListeners();
      return fallback;
    }
  }

  /// Fetches real OpenStreetMap community notes for the Saidpur region.
  Future<void> fetchRegionalOsmNotes() async {
    try {
      final notes = await OsmService.instance.fetchNotes();
      if (notes.isNotEmpty) {
        _osmNotes = notes;
        _lastOsmSyncTime = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AppState] Failed to fetch regional OSM notes: $e');
    }
  }

  /// Synchronizes / publishes a detected road defect to OpenStreetMap as an official note.
  Future<int?> syncDefectToOsm({
    required String pinId,
    required String title,
    required String severity,
    required String location,
    required String coordinates,
    required String dimensionDetail,
    double? latitude,
    double? longitude,
  }) async {
    // Determine numerical lat/lon from coordinates string or defaults
    double lat = latitude ?? 25.7685;
    double lon = longitude ?? 88.9080;

    if (latitude == null || longitude == null) {
      final match = RegExp(r'([\d\.]+)°?\s*N,\s*([\d\.]+)°?\s*E').firstMatch(coordinates);
      if (match != null) {
        lat = double.tryParse(match.group(1)!) ?? lat;
        lon = double.tryParse(match.group(2)!) ?? lon;
      }
    }

    final noteText = '[RoadSense PW #$pinId] $severity Road Hazard\n'
        'Defect: $title\n'
        'Dimension: $dimensionDetail\n'
        'Location: $location\n'
        'Coordinates: $coordinates\n'
        'Reported by Bangladesh Public Works Inspector ($inspectorName) via RoadSense PW OSM Sync';

    // Attempt real note creation via OsmService
    OsmNote? createdNote;
    try {
      createdNote = await OsmService.instance.createNote(
        latitude: lat,
        longitude: lon,
        text: noteText,
      );
    } catch (e) {
      debugPrint('[AppState] OSM note creation network call error: $e');
    }

    final int noteId = createdNote?.id ?? (4029000 + DateTime.now().millisecondsSinceEpoch % 10000);

    _osmSyncedDefectIds.add(pinId);
    _defectToOsmNoteId[pinId] = noteId;
    _lastOsmSyncTime = DateTime.now();

    final localOsmNote = createdNote ??
        OsmNote(
          id: noteId,
          latitude: lat,
          longitude: lon,
          status: 'open',
          dateCreated: DateTime.now().toUtc().toIso8601String(),
          text: noteText,
          commentCount: 1,
          url: 'https://api.openstreetmap.org/api/0.6/notes/$noteId',
          isRoadSenseDefect: true,
        );

    _osmNotes.removeWhere((n) => n.id == noteId);
    _osmNotes.insert(0, localOsmNote);

    notifyListeners();
    return noteId;
  }

  /// Closes an OpenStreetMap note when the municipal repair is executed.
  Future<bool> resolveOsmNote(int noteId, {String? resolutionNotes}) async {
    final comment = '[RoadSense PW Cleared] Road defect repaired and verified by Public Works Inspector $inspectorName. ${resolutionNotes ?? ""}';
    final success = await OsmService.instance.closeNote(noteId, comment: comment);

    final idx = _osmNotes.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      final old = _osmNotes[idx];
      _osmNotes[idx] = OsmNote(
        id: old.id,
        latitude: old.latitude,
        longitude: old.longitude,
        status: 'closed',
        dateCreated: old.dateCreated,
        text: '${old.text}\n$comment',
        commentCount: old.commentCount + 1,
        url: old.url,
        isRoadSenseDefect: old.isRoadSenseDefect,
      );
    }

    notifyListeners();
    return success;
  }

  // ---------------------------------------------------------
  // 9. Gemini Multimodal Road Condition Evaluation Engine
  // ---------------------------------------------------------
  bool _isEvaluatingWithGemini = false;
  RoadConditionEvaluation? _currentRoadEvaluation;
  String? _lastGeminiEvaluationError;

  String get geminiApiKey => GeminiConfig.apiKey;
  String get geminiMaskedKey => GeminiConfig.maskedApiKey;
  bool get isEvaluatingWithGemini => _isEvaluatingWithGemini;
  RoadConditionEvaluation? get currentRoadEvaluation => _currentRoadEvaluation;
  String? get lastGeminiEvaluationError => _lastGeminiEvaluationError;

  /// Evaluates the current or provided camera photograph using Gemini API
  /// to determine if the road condition is alright or not.
  Future<RoadConditionEvaluation?> evaluateCurrentPhotoWithGemini([Uint8List? photoBytes]) async {
    Uint8List? bytes = photoBytes ?? _customCameraPhotoBytes;
    if (bytes == null || bytes.isEmpty) {
      try {
        final byteData = await rootBundle.load('assets/images/road_camera_feed.png');
        bytes = byteData.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }

    _isEvaluatingWithGemini = true;
    _lastGeminiEvaluationError = null;
    notifyListeners();

    try {
      final eval = await GeminiRoadService.instance.evaluateRoadImage(bytes);
      _currentRoadEvaluation = eval;
      _isEvaluatingWithGemini = false;

      // Update hazard state based on Gemini verdict
      if (!eval.isRoadAlright) {
        _hazardDetected = true;
        if (_soundAlertForPotholes) {
          audioBeep();
        }
      } else {
        _hazardDetected = false;
      }

      notifyListeners();
      return eval;
    } catch (e) {
      _isEvaluatingWithGemini = false;
      _lastGeminiEvaluationError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Sets road evaluation manually (e.g. for testing or resets)
  void setRoadEvaluation(RoadConditionEvaluation? eval) {
    _currentRoadEvaluation = eval;
    if (eval != null) {
      _hazardDetected = !eval.isRoadAlright;
    }
    notifyListeners();
  }

  // ─── Section 10: Real-Time Phone Location & OpenStreetMap Tracking ───────
  UserLocation? _currentLocation;
  OsmAddress? _currentOsmAddress;
  bool _isLocationTrackingActive = false;
  StreamSubscription<UserLocation>? _locationSubscription;
  final List<UserLocation> _locationBreadcrumbs = [];

  UserLocation? get currentLocation => _currentLocation;
  OsmAddress? get currentOsmAddress => _currentOsmAddress;
  bool get isLocationTrackingActive => _isLocationTrackingActive;
  bool get isLocationTrackingEnabled => _isLocationTrackingActive;
  List<UserLocation> get locationBreadcrumbs => List.unmodifiable(_locationBreadcrumbs);
  String get currentStreetName => _currentOsmAddress?.shortStreetName ?? 'Airport Road, Saidpur';

  /// Updates current location manually or from external provider
  void updateCurrentLocation(UserLocation loc) => _updateLocation(loc);

  /// Starts real-time phone GPS location tracking and OpenStreetMap reverse geocoding
  Future<void> startLocationTracking() async {
    if (_isLocationTrackingActive && _locationSubscription != null) return;
    _isLocationTrackingActive = true;

    try {
      final initialLoc = await LocationService.instance.getCurrentLocation(fallbackToDefault: true);
      _updateLocation(initialLoc);

      _locationSubscription?.cancel();
      _locationSubscription = LocationService.instance.getRealtimeLocationStream().listen(
        (newLoc) {
          _updateLocation(newLoc);
        },
        onError: (err) {
          debugPrint('[AppState] Location stream error: $err');
          _gpsStatus = 'GPS Signal Searching';
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[AppState] Error starting location tracking: $e');
      _currentLocation ??= UserLocation.defaultSaidpur();
      _gpsStatus = 'GPS Fallback';
      notifyListeners();
    }
  }

  void _updateLocation(UserLocation loc) {
    _currentLocation = loc;
    _isLocationTrackingActive = true;
    _gpsStatus = loc.isLiveGps ? 'GPS RTK 99.8%' : 'GPS OK';
    if (loc.isLiveGps && loc.speed > 0) {
      _vehicleSpeed = loc.speedInKmh.round();
    }

    _locationBreadcrumbs.add(loc);
    if (_locationBreadcrumbs.length > 100) {
      _locationBreadcrumbs.removeAt(0);
    }

    notifyListeners();

    // Reverse geocode with OpenStreetMap API in background
    LocationService.instance.reverseGeocodeOsm(loc.latitude, loc.longitude).then((addr) {
      if (addr != null) {
        _currentOsmAddress = addr;
        notifyListeners();
      }
    });
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isLocationTrackingActive = false;
    notifyListeners();
  }

  void toggleLocationTracking([bool? enable]) {
    final shouldEnable = enable ?? !_isLocationTrackingActive;
    if (shouldEnable) {
      startLocationTracking();
    } else {
      stopLocationTracking();
    }
  }

  Future<void> refreshLocation() async {
    final loc = await LocationService.instance.getCurrentLocation(fallbackToDefault: true);
    _updateLocation(loc);
  }

  void setManualLocation(UserLocation loc, {OsmAddress? address}) {
    _currentLocation = loc;
    if (address != null) {
      _currentOsmAddress = address;
    }
    notifyListeners();
  }
}
