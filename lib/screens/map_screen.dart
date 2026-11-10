import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:road_sense/config/osm_config.dart';
import 'package:road_sense/screens/field_capture_screen.dart';
import 'package:road_sense/services/location_service.dart';
import 'package:road_sense/services/osm_service.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';

/// Defect GIS Pin Model representing mapped road hazards
class DefectMapPin {
  final String id;
  final String title;
  final String severity; // 'Urgent' | 'Medium' | 'Low' | 'Cleared'
  final String dimensionDetail;
  final String location;
  final String coordinates;
  final Offset position;
  final double latitude;
  final double longitude;
  final bool isPothole;
  final bool isCleared;

  const DefectMapPin({
    required this.id,
    required this.title,
    required this.severity,
    required this.dimensionDetail,
    required this.location,
    required this.coordinates,
    required this.position,
    this.latitude = 25.7685,
    this.longitude = 88.9080,
    required this.isPothole,
    this.isCleared = false,
  });
}

/// Official RoadSense PW Defect GIS & Road Map Screen
/// Provides an interactive Public Works cartographic view of municipal road assets,
/// defect pins, live inspector vehicle tracking (Truck #14), filter chips,
/// and quick dispatch action cards.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Map viewport transform
  Offset _panOffset = const Offset(0, 0);
  double _scale = 1.0;

  // Filters: 'All Defects', 'Potholes Only', 'Cracks Only', 'High Severity'
  String _selectedFilter = 'All Defects';

  // Selected Defect Pin
  DefectMapPin? _selectedPin;

  // Layer mode: false = GIS Streets, true = Satellite Hybrid
  bool _isSatelliteLayer = false;

  // OpenStreetMap Layer mode: true = OSM Cartography & Notes
  bool _isOsmLayer = true;

  // Pre-configured municipal defect pins across Saidpur, Rangpur road network
  final List<DefectMapPin> _pins = const [
    DefectMapPin(
      id: 'pin-1',
      title: 'Airport Road Pothole',
      severity: 'Urgent',
      dimensionDetail: '7cm deep cavity',
      location: 'Airport Road near BAUST',
      coordinates: '25.7685° N, 88.9080° E',
      position: Offset(240, 240),
      latitude: 25.7685,
      longitude: 88.9080,
      isPothole: true,
    ),
    DefectMapPin(
      id: 'pin-2',
      title: 'Sailar Mor Asphalt Crack',
      severity: 'Medium',
      dimensionDetail: '4.2m longitudinal crack',
      location: 'Sailar Mor & Cantt Road',
      coordinates: '25.7745° N, 88.9012° E',
      position: Offset(390, 240),
      latitude: 25.7745,
      longitude: 88.9012,
      isPothole: false,
    ),
    DefectMapPin(
      id: 'pin-3',
      title: 'Cantt Bazar Road Pothole',
      severity: 'Urgent',
      dimensionDetail: '8cm deep cavity',
      location: 'Cantt Bazar, Saidpur',
      coordinates: '25.7815° N, 88.9050° E',
      position: Offset(560, 170),
      latitude: 25.7815,
      longitude: 88.9050,
      isPothole: true,
    ),
    DefectMapPin(
      id: 'pin-4',
      title: 'Waffle Street Restaurant Cavity',
      severity: 'Urgent',
      dimensionDetail: '7.5cm deep void',
      location: 'Cantt Road near Waffle Street Restaurant',
      coordinates: '25.7820° N, 88.9045° E',
      position: Offset(560, 100),
      latitude: 25.7820,
      longitude: 88.9045,
      isPothole: true,
    ),
    DefectMapPin(
      id: 'pin-5',
      title: 'BAUST Gate Culvert Void',
      severity: 'Urgent',
      dimensionDetail: '9cm deep edge void',
      location: 'BAUST Main Campus Gate',
      coordinates: '25.7680° N, 88.9120° E',
      position: Offset(130, 240),
      latitude: 25.7680,
      longitude: 88.9120,
      isPothole: true,
    ),
    DefectMapPin(
      id: 'pin-6',
      title: 'Railway Station Approach Spall',
      severity: 'Medium',
      dimensionDetail: '2.8m spall pattern',
      location: 'Saidpur Railway Station Plaza',
      coordinates: '25.7785° N, 88.8925° E',
      position: Offset(220, 380),
      latitude: 25.7785,
      longitude: 88.8925,
      isPothole: false,
    ),
    DefectMapPin(
      id: 'pin-7',
      title: 'Taste & GO Restaurant Road Seam',
      severity: 'Medium',
      dimensionDetail: '2.4m seam fracture',
      location: 'Station Road opposite Taste & GO Restaurant',
      coordinates: '25.7792° N, 88.8938° E',
      position: Offset(220, 450),
      latitude: 25.7792,
      longitude: 88.8938,
      isPothole: false,
    ),
    DefectMapPin(
      id: 'pin-8',
      title: 'Saidpur Bazar Edge Void',
      severity: 'Urgent',
      dimensionDetail: '6.5cm deep cavity',
      location: 'Saidpur Bazar Gate 1',
      coordinates: '25.7760° N, 88.8905° E',
      position: Offset(390, 480),
      latitude: 25.7760,
      longitude: 88.8905,
      isPothole: true,
    ),
    DefectMapPin(
      id: 'pin-9',
      title: 'Central Terminal Rutting',
      severity: 'Medium',
      dimensionDetail: '3.5m asphalt rut',
      location: 'Saidpur Central Bus Terminal',
      coordinates: '25.7875° N, 88.8890° E',
      position: Offset(650, 120),
      latitude: 25.7875,
      longitude: 88.8890,
      isPothole: false,
    ),
    DefectMapPin(
      id: 'pin-10',
      title: 'Church Road Cleared Patch',
      severity: 'Cleared',
      dimensionDetail: 'Cold mix patch verified',
      location: 'Church Road near Christian Church',
      coordinates: '25.7730° N, 88.8940° E',
      position: Offset(260, 320),
      latitude: 25.7730,
      longitude: 88.8940,
      isPothole: false,
      isCleared: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default select Item 1: Airport Road Pothole
    _selectedPin = _pins[0];

    // Truck movement and radar scan pulse animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Start real-time phone GPS location tracking & OpenStreetMap location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState.instance.startLocationTracking();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<DefectMapPin> get _filteredPins {
    return _pins.where((pin) {
      if (_selectedFilter == 'Potholes Only') {
        return pin.isPothole && !pin.isCleared;
      }
      if (_selectedFilter == 'Cracks Only') {
        return !pin.isPothole && !pin.isCleared;
      }
      if (_selectedFilter == 'High Severity') {
        return pin.severity.toLowerCase() == 'urgent';
      }
      return true; // 'All Defects'
    }).toList();
  }

  /// Calculates dynamic screen offset for the phone's live GPS position
  Offset _computePhonePosition(UserLocation loc) {
    if (loc.isLiveGps) {
      const baseLat = 25.7685;
      const baseLon = 88.9080;
      final dx = (loc.longitude - baseLon) * 16000.0;
      final dy = -(loc.latitude - baseLat) * 16000.0;
      final mappedX = (400.0 + dx).clamp(50.0, 750.0);
      final mappedY = (290.0 + dy).clamp(50.0, 550.0);
      return Offset(mappedX, mappedY);
    }

    final t = _animController.value;
    final truckX = 120.0 + 440.0 * (t < 0.5 ? (t * 2) : (2 - t * 2));
    return Offset(truckX, 240);
  }

  /// Centers the interactive map onto the phone's live GPS position
  void _centerOnUserLocation(AppState state) {
    final loc = state.currentLocation ?? UserLocation.defaultSaidpur();
    final pos = _computePhonePosition(loc);
    setState(() {
      _scale = 1.35;
      _panOffset = (const Offset(400, 290) - pos) * _scale;
    });

    state.refreshLocation();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '📍 Located via OpenStreetMap: ${state.currentStreetName}\n${loc.formattedCoordinates} (±${loc.accuracy.toStringAsFixed(1)}m)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF09495C),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMapTap(Offset localPos, Size widgetSize) {
    // Map center is widgetSize / 2
    // Pin canvas origin is (400, 300)
    final canvasCenter = Offset(widgetSize.width / 2, widgetSize.height / 2);
    final worldTap = (localPos - canvasCenter - _panOffset) / _scale + const Offset(400, 290);

    // Find closest pin within hit radius (36px)
    DefectMapPin? nearest;
    double nearestDist = 36.0;

    for (final pin in _filteredPins) {
      final dist = (pin.position - worldTap).distance;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = pin;
      }
    }

    if (nearest != null) {
      setState(() {
        _selectedPin = nearest;
      });
    }
  }

  void _centerOnPin(DefectMapPin pin) {
    setState(() {
      _selectedPin = pin;
      _scale = 1.25;
      // Pan so pin.position is centered
      _panOffset = (const Offset(400, 290) - pin.position) * _scale;
    });
  }

  /// Builds a real-time OpenStreetMap Slippy Map Tile layer centered around phone location
  Widget _buildOsmTileGrid(Size size, AppState state) {
    if (!_isOsmLayer) return const SizedBox.shrink();

    final loc = state.currentLocation ?? UserLocation.defaultSaidpur();
    const int zoomInt = 16;
    final double subZoomScale = _scale;

    final double worldLonNorm = (loc.longitude + 180.0) / 360.0;
    final double latRad = loc.latitude.clamp(-85.0511, 85.0511) * math.pi / 180.0;
    final double worldLatNorm = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0;

    final centerTileX = worldLonNorm * (1 << zoomInt);
    final centerTileY = worldLatNorm * (1 << zoomInt);

    final halfW = size.width / 2;
    final halfH = size.height / 2;

    final int spanX = (halfW / (256.0 * subZoomScale)).ceil() + 1;
    final int spanY = (halfH / (256.0 * subZoomScale)).ceil() + 1;

    final int minTileX = (centerTileX - spanX).floor();
    final int maxTileX = (centerTileX + spanX).ceil();
    final int minTileY = (centerTileY - spanY).floor();
    final int maxTileY = (centerTileY + spanY).ceil();

    const maxTileIndex = (1 << zoomInt) - 1;
    final List<Widget> tiles = [];

    for (int tx = minTileX; tx <= maxTileX; tx++) {
      for (int ty = minTileY; ty <= maxTileY; ty++) {
        if (ty < 0 || ty > maxTileIndex) continue;
        final wrappedTx = (tx % (maxTileIndex + 1) + (maxTileIndex + 1)) % (maxTileIndex + 1);

        final tileDx = (tx - centerTileX) * 256.0 * subZoomScale + halfW + _panOffset.dx;
        final tileDy = (ty - centerTileY) * 256.0 * subZoomScale + halfH + _panOffset.dy;
        final tileSize = 256.0 * subZoomScale;

        final url = 'https://tile.openstreetmap.org/$zoomInt/$wrappedTx/$ty.png';

        tiles.add(
          Positioned(
            left: tileDx,
            top: tileDy,
            width: tileSize,
            height: tileSize,
            child: Opacity(
              opacity: 0.94,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                headers: const {
                  'User-Agent': 'RoadSense-PW-App/1.0 (Public Works; contact@roadsense.pw)',
                },
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF2EFE9),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: tiles);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final loc = state.currentLocation ?? UserLocation.defaultSaidpur();
        final phonePos = _computePhonePosition(loc);

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(state),
                _buildFilterChipsBar(),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    children: [
                      // Interactive Vector GIS & OpenStreetMap Canvas
                      Positioned.fill(
                        child: ClipRect(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);

                              return GestureDetector(
                                onScaleUpdate: (details) {
                                  setState(() {
                                    _scale = (_scale * details.scale).clamp(0.65, 2.5);
                                    _panOffset += details.focalPointDelta;
                                  });
                                },
                                onTapUp: (details) {
                                  _handleMapTap(details.localPosition, size);
                                },
                                child: Stack(
                                  children: [
                                    // 1. Live OpenStreetMap Standard Slippy Tile Grid
                                    if (_isOsmLayer)
                                      _buildOsmTileGrid(size, state),

                                    // 2. Interactive Real-Time Location Tracking Canvas
                                    AnimatedBuilder(
                                      animation: _animController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          size: size,
                                          painter: _GisRoadNetworkPainter(
                                            panOffset: _panOffset,
                                            scale: _scale,
                                            pins: _filteredPins,
                                            selectedPin: _selectedPin,
                                            truckPosition: phonePos,
                                            truckHeadingAngle: loc.isLiveGps
                                                ? (loc.heading * math.pi / 180.0)
                                                : (_animController.value < 0.5 ? 0.0 : math.pi),
                                            animValue: _animController.value,
                                            isSatellite: _isSatelliteLayer,
                                            isOsmLayer: _isOsmLayer,
                                            osmNotes: state.osmNotes,
                                            vehicleSpeed: state.vehicleSpeed,
                                            truckName: state.vehicleName,
                                            userLocation: loc,
                                            breadcrumbs: state.locationBreadcrumbs,
                                          ),
                                        );
                                      },
                                    ),

                                    // 3. OpenStreetMap Attribution (Mandatory by OSM License)
                                    if (_isOsmLayer)
                                      Positioned(
                                        bottom: _selectedPin != null ? 158 : 6,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
                                          ),
                                          child: const Text(
                                            '© OpenStreetMap contributors',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              color: Color(0xFF475569),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Map Control Overlay (Zoom In, Zoom Out, Locate Phone, Layer)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: _buildMapControls(state),
                      ),

                      // Scale indicator / Real Phone Coordinates (bottom left of map)
                      Positioned(
                        bottom: _selectedPin != null ? 170 : 16,
                        left: 14,
                        child: _buildScaleBadge(state),
                      ),

                      // Defect Quick Card (Floats when a pin is selected)
                      if (_selectedPin != null)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: _buildDefectQuickCard(_selectedPin!, state),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // 1. Header with Title & Live Tracking Indicator
  // ---------------------------------------------------------
  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Defect GIS & Road Map',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bangladesh Public Works • Saidpur, Rangpur',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              // Live camera shortcut
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FieldCaptureScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.videocam_rounded),
                color: AppTheme.primaryTeal,
                tooltip: 'Live Camera Scan',
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Live tracking indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.lightGreenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.scanGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Pulsing dot
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final pulse = 0.4 + 0.6 * math.sin(_animController.value * 2 * math.pi).abs();
                    return Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.scanGreen.withValues(alpha: pulse),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.scanGreen.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'LIVE TRACKING: ${state.vehicleName} (${state.inspectorName}) • ${state.vehicleSpeed} mph',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.badgeGreenText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'GPS RTK 99.8%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.badgeGreenText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // OpenStreetMap Real-Time Street Location Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF86EFAC),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pin_drop_rounded,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '📍 OSM Located: ${state.currentStreetName} • ${state.currentLocation?.formattedCoordinates ?? "25.7685° N, 88.9080° E"}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF166534),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OSM ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // OpenStreetMap Integration telemetry pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.public_rounded,
                  size: 14,
                  color: Color(0xFF0284C7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'OpenStreetMap OAuth 2.0 • Client: ${OsmConfig.clientId.substring(0, 10)}... • ${state.osmSyncedDefectIds.length} hazards synced',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SYNC READY',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 2. Filter Chips Bar
  // ---------------------------------------------------------
  Widget _buildFilterChipsBar() {
    final filters = [
      'All Defects',
      'Potholes Only',
      'Cracks Only',
      'High Severity',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            int count;
            if (filter == 'Potholes Only') {
              count = _pins.where((p) => p.isPothole && !p.isCleared).length;
            } else if (filter == 'Cracks Only') {
              count = _pins.where((p) => !p.isPothole && !p.isCleared).length;
            } else if (filter == 'High Severity') {
              count = _pins.where((p) => p.severity.toLowerCase() == 'urgent').length;
            } else {
              count = _pins.length;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: isSelected,
                label: Text('$filter ($count)'),
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                backgroundColor: AppTheme.scaffoldBackground,
                selectedColor: AppTheme.primaryTeal,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor,
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 3. Map Controls (Zoom In, Zoom Out, Locate Phone, Layer)
  // ---------------------------------------------------------
  Widget _buildMapControls(AppState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            color: AppTheme.textPrimary,
            tooltip: 'Zoom In',
            onPressed: () {
              setState(() => _scale = (_scale + 0.25).clamp(0.65, 2.5));
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            color: AppTheme.textPrimary,
            tooltip: 'Zoom Out',
            onPressed: () {
              setState(() => _scale = (_scale - 0.25).clamp(0.65, 2.5));
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          // Locate Phone GPS Position with OpenStreetMap
          IconButton(
            icon: const Icon(Icons.my_location_rounded, size: 20),
            color: AppTheme.primaryTeal,
            tooltip: 'Locate Phone GPS Position',
            onPressed: () => _centerOnUserLocation(state),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          // Toggle Realtime GPS Tracking stream
          IconButton(
            icon: Icon(
              state.isLocationTrackingActive
                  ? Icons.gps_fixed_rounded
                  : Icons.gps_not_fixed_rounded,
              size: 20,
            ),
            color: state.isLocationTrackingActive
                ? const Color(0xFF16A34A)
                : const Color(0xFF94A3B8),
            tooltip: state.isLocationTrackingActive
                ? 'Live GPS Tracking Active'
                : 'Resume Live GPS Tracking',
            onPressed: () {
              state.toggleLocationTracking();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.isLocationTrackingActive
                      ? '✓ Live GPS Location Tracking Resumed'
                      : '⏸ Live GPS Location Tracking Paused'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          // Layer Toggle (OSM Standard / GIS / Satellite)
          IconButton(
            icon: Icon(
              _isOsmLayer
                  ? Icons.public_rounded
                  : (_isSatelliteLayer ? Icons.satellite_alt_rounded : Icons.layers_rounded),
              size: 20,
            ),
            color: _isOsmLayer ? const Color(0xFF0284C7) : AppTheme.textSecondary,
            tooltip: 'Switch Map Layer (OSM / GIS / Satellite)',
            onPressed: () {
              setState(() {
                if (_isOsmLayer) {
                  _isOsmLayer = false;
                  _isSatelliteLayer = false;
                } else if (!_isSatelliteLayer) {
                  _isSatelliteLayer = true;
                } else {
                  _isOsmLayer = true;
                  _isSatelliteLayer = false;
                }
              });
              final layerName = _isOsmLayer
                  ? 'OpenStreetMap Standard Tiles'
                  : (_isSatelliteLayer ? 'Satellite Hybrid Mode' : 'Municipal Vector GIS Layer');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Map Layer: $layerName'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 4. Cartographic Scale & Real Phone Coordinate Badge
  // ---------------------------------------------------------
  Widget _buildScaleBadge(AppState state) {
    final loc = state.currentLocation ?? UserLocation.defaultSaidpur();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten_rounded, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            '200 m • ${loc.formattedCoordinates}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 5. Defect Quick Card (Tapping Pin Pops up Action Options)
  // ---------------------------------------------------------
  Widget _buildDefectQuickCard(DefectMapPin pin, AppState state) {
    Color severityBg;
    Color severityText;
    Color dotColor;

    if (pin.isCleared) {
      severityBg = AppTheme.lightGreenBg;
      severityText = AppTheme.badgeGreenText;
      dotColor = AppTheme.scanGreen;
    } else if (pin.severity.toLowerCase() == 'urgent') {
      severityBg = AppTheme.urgentRedBg;
      severityText = AppTheme.badgeRedText;
      dotColor = AppTheme.urgentRed;
    } else {
      severityBg = AppTheme.scheduledAmberBg;
      severityText = AppTheme.badgeAmberText;
      dotColor = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title, dot, severity badge, close
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pin.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pin.severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: severityText,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _selectedPin = null),
                child: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Subtext: Location & Dimensions
          Text(
            '${pin.location} • ${pin.dimensionDetail}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pin.coordinates,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // 4-Point Quick Breakdown: Kothay, Kih Hoyse, Koto Tuku Damage, Minimal Cost
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF09495C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'কোথায়: ${pin.location} (${pin.coordinates})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'কী হয়েছে: ${pin.isPothole ? "গভীর গর্ত ও অ্যাসফল্ট ক্ষয় (Pothole Cavity)" : "রাস্তার ফাটল (Asphalt Surface Crack)"}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          'ক্ষতি: ${pin.dimensionDetail}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ন্যূনতম খরচ: ৳2,800',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // OpenStreetMap Sync Status & Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: state.isDefectSynced(pin.id)
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.isDefectSynced(pin.id)
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFBAE6FD),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 14,
                  color: state.isDefectSynced(pin.id)
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.isDefectSynced(pin.id)
                        ? 'OpenStreetMap Note #${state.getOsmNoteId(pin.id) ?? 4028971} Synced'
                        : 'OpenStreetMap: Ready to report defect note',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: state.isDefectSynced(pin.id)
                          ? const Color(0xFF166534)
                          : const Color(0xFF0369A1),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    if (state.isDefectSynced(pin.id)) {
                      final noteId = state.getOsmNoteId(pin.id) ?? 4028971;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing OSM Note #$noteId: https://api.openstreetmap.org/api/0.6/notes/$noteId'),
                          backgroundColor: const Color(0xFF09495C),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      final messenger = ScaffoldMessenger.of(context);
                      final noteId = await state.syncDefectToOsm(
                        pinId: pin.id,
                        title: pin.title,
                        severity: pin.severity,
                        location: pin.location,
                        coordinates: pin.coordinates,
                        dimensionDetail: pin.dimensionDetail,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('✓ Published defect to OpenStreetMap Note #$noteId via OAuth 2.0!'),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: state.isDefectSynced(pin.id)
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.isDefectSynced(pin.id) ? 'OSM Synced ✓' : 'Sync to OSM',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: state.isDefectSynced(pin.id)
                            ? const Color(0xFF15803D)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons Row: Deep Details | Send Crew | Add Task
          Row(
            children: [
              // Details Button (Kothay, Kih hoyse, Koto tuku damage, Kih step neya jay)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDefectDeepDetailsModal(context, pin, state),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text(
                    'প্রতিকার পদক্ষেপ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09495C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Crew Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    state.addRepairTask(
                      pin.title,
                      pin.location,
                      pin.severity.toUpperCase(),
                      assignedCrew: 'Crew #3 (Dispatched)',
                      notes: '${pin.dimensionDetail} • Dispatched from GIS Map • Est: ৳2,800',
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.scanGreen,
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Crew #3 dispatched to ${pin.location}!',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send Crew', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.scanGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Focus Pin on Map
              IconButton(
                onPressed: () => _centerOnPin(pin),
                icon: const Icon(Icons.center_focus_strong_rounded),
                color: AppTheme.primaryTeal,
                tooltip: 'Focus Pin',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 6. Comprehensive Defect Details Modal Sheet
  // (কোথায়, কী হয়েছে, কতটুকু ক্ষতি, কী পদক্ষেপ নেওয়া যায়)
  // ---------------------------------------------------------
  void _showDefectDeepDetailsModal(
      BuildContext context, DefectMapPin pin, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with Title & Severity Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pin.title,
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pin.severity.toLowerCase() == 'urgent'
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pin.severity.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: pin.severity.toLowerCase() == 'urgent'
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. কোথায় (Location & Coordinates)
                  _buildAnalysisSection(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF09495C),
                    bgColor: const Color(0xFFEEF5FD),
                    title: '১. কোথায় (Location & Area)',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.location,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'GPS স্থানাঙ্ক: ${pin.coordinates}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'এলাকা: সৈয়দপুর পৌরসভা • রংপুর বিভাগ (বাংলাদেশ পাবলিক ওয়ার্কস)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF09495C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. কী হয়েছে (What Happened / Defect Nature)
                  _buildAnalysisSection(
                    icon: Icons.report_problem_rounded,
                    iconColor: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEE2E2),
                    title: '২. কী হয়েছে (What Happened)',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.isPothole
                              ? 'গভীর গর্ত ও অ্যাসফল্ট স্তর ক্ষয় (Sub-base Bitumen Cavity)'
                              : 'পৃষ্ঠের ফাটল ও সিমিং ফ্র্যাকচার (Longitudinal Surface Crack)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pin.isPothole
                              ? 'বৃষ্টির পানি জমে অ্যাসফল্টের নিচের বালু-পাথর ধসে রাস্তার মাঝখানে বিপজ্জনক গর্ত তৈরি হয়েছে।'
                              : 'ভারী যানবাহনের অতিরিক্ত চাপ ও তাপমাত্রার ওঠানামার কারণে অ্যাসফল্ট স্তর ফেটে পানি প্রবেশ করছে।',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. কতটুকু ক্ষতি (Extent of Damage & Risk)
                  _buildAnalysisSection(
                    icon: Icons.straighten_rounded,
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    title: '৩. কতটুকু ক্ষতি (Damage Extent & Severity)',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'পরিমাপ: ',
                              style: GoogleFonts.inter(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              pin.dimensionDetail,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pin.isPothole
                              ? 'প্রভাবিত এলাকা: আনুমানিক ১.২ বর্গমিটার • গভীরতা ৭-৯ সেমি'
                              : 'প্রভাবিত এলাকা: আনুমানিক ৩.৫ - ৪.২ মিটার দৈর্ঘ্য',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ঝুঁকি: অটোরিকশা, মোটরসাইকেল ও বাসের চাকা আটকে দুর্ঘটনা ঘটার প্রবল আশঙ্কা।',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. কী পদক্ষেপ নেওয়া যায় (Action Steps & Minimal Cost in Taka)
                  _buildAnalysisSection(
                    icon: Icons.engineering_rounded,
                    iconColor: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    title: '৪. কী পদক্ষেপ নেওয়া যায় (Action Steps & Cost)',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepItem('ধাপ ১', 'তাত্ক্ষণিক রিফ্লেক্টিভ কোন ও সতর্কতা সাইন স্থাপন।'),
                        _buildStepItem('ধাপ ২', 'ভেতরের আলগা পাথর ও পানি উচ্চচাপ বাতাস দিয়ে পরিষ্কার।'),
                        _buildStepItem('ধাপ ৩', 'ইমালশন প্রাইম টেক কোট স্প্রে করে আঠালো বন্ধন নিশ্চিতকরণ।'),
                        _buildStepItem('ধাপ ৪', 'কোল্ড-মিক্স/হট-মিক্স অ্যাসফল্ট ফেলে প্লেট কম্প্যাক্টরে লেভেলিং।'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ন্যূনতম জরুরি প্যাচ খরচ:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                  Text(
                                    'স্থায়ী হট-মিক্স সংস্কার: ৳৫,৫০০',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '৳২,৮০০',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Modal Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            state.addRepairTask(
                              pin.title,
                              pin.location,
                              pin.severity.toUpperCase(),
                              assignedCrew: 'Crew #3 (Immediate Dispatch)',
                              notes:
                                  '${pin.dimensionDetail} • Dispatched via Defect Analysis • Est: ৳2,800',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.scanGreen,
                                content: Text('Crew #3 dispatched to ${pin.location}!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text(
                            'Send Repair Crew',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09495C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('বন্ধ করুন'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisSection({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FD),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              step,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF09495C),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartographic Custom Painter rendering the Public Works Road Network,
/// Defect Pins, Live Truck Marker, and Radar Scanning Cone.
class _GisRoadNetworkPainter extends CustomPainter {
  final Offset panOffset;
  final double scale;
  final List<DefectMapPin> pins;
  final DefectMapPin? selectedPin;
  final Offset truckPosition;
  final double truckHeadingAngle;
  final double animValue;
  final bool isSatellite;
  final bool isOsmLayer;
  final List<OsmNote> osmNotes;
  final int vehicleSpeed;
  final String truckName;
  final UserLocation? userLocation;
  final List<UserLocation> breadcrumbs;

  _GisRoadNetworkPainter({
    required this.panOffset,
    required this.scale,
    required this.pins,
    required this.selectedPin,
    required this.truckPosition,
    required this.truckHeadingAngle,
    required this.animValue,
    required this.isSatellite,
    this.isOsmLayer = false,
    this.osmNotes = const [],
    required this.vehicleSpeed,
    required this.truckName,
    this.userLocation,
    this.breadcrumbs = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Map Center is size / 2, world anchor is (400, 290)
    canvas.translate(size.width / 2 + panOffset.dx, size.height / 2 + panOffset.dy);
    canvas.scale(scale);
    canvas.translate(-400, -290);

    // 1. Background Fill
    final bgPaint = Paint()
      ..color = isSatellite
          ? const Color(0xFF1E293B)
          : (isOsmLayer ? const Color(0xFFF2EFE9) : const Color(0xFFF1F5F9));
    canvas.drawRect(const Rect.fromLTWH(-200, -200, 1200, 1000), bgPaint);

    // 2. Municipal Grid Lines
    final gridPaint = Paint()
      ..color = isSatellite
          ? Colors.white.withValues(alpha: 0.05)
          : (isOsmLayer ? const Color(0xFFE5E0D8) : const Color(0xFFE2E8F0))
      ..strokeWidth = 1.0;

    for (double x = -100; x <= 900; x += 100) {
      canvas.drawLine(Offset(x, -100), Offset(x, 800), gridPaint);
    }
    for (double y = -100; y <= 800; y += 100) {
      canvas.drawLine(Offset(-100, y), Offset(900, y), gridPaint);
    }

    // 3. Waterway (Kharikhola River, Saidpur)
    final riverPath = Path()
      ..moveTo(20, 520)
      ..cubicTo(200, 480, 420, 390, 780, 540)
      ..lineTo(780, 590)
      ..cubicTo(420, 440, 200, 530, 20, 570)
      ..close();

    final riverPaint = Paint()
      ..color = isSatellite
          ? const Color(0xFF0F3A5A)
          : (isOsmLayer ? const Color(0xFFAAD3DF) : const Color(0xFFD6E8F7));
    canvas.drawPath(riverPath, riverPaint);

    // 4. Municipal Parkland & Campuses (BAUST Campus & Green Reserve)
    final parkRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(320, 110, 190, 100),
      const Radius.circular(16),
    );
    final parkPaint = Paint()
      ..color = isSatellite
          ? const Color(0xFF143324)
          : (isOsmLayer ? const Color(0xFFC8FACC) : const Color(0xFFDCF0DC));
    canvas.drawRRect(parkRect, parkPaint);

    // Label: BAUST Campus
    _drawText(
      canvas,
      'BAUST Campus & Cantonment',
      const Offset(415, 160),
      isSatellite ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      11,
      FontWeight.w700,
    );

    // Green Area 2: Saidpur Railway Heritage Park
    final railParkRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(80, 440, 160, 80),
      const Radius.circular(12),
    );
    canvas.drawRRect(railParkRect, parkPaint);
    _drawText(
      canvas,
      'Railway Heritage Park',
      const Offset(160, 480),
      isSatellite ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      10,
      FontWeight.w600,
    );

    // 5. Saidpur Roads Network Canvas:
    // Airport Road, Cantt Bazar, Sailar Mor, Station Road, Terminal Bypass, Church Road
    _drawRoadsNetwork(canvas);

    // 6. Live Inspector Truck Marker (Truck #14) & Radar Scan Cone
    _drawTruckMarker(canvas);

    // 7. Defect Pins
    _drawDefectPins(canvas);

    // 8. OpenStreetMap Notes and Attribution (when OSM Layer is enabled)
    if (isOsmLayer) {
      _drawOsmNotes(canvas);

      // Attribution watermark
      _drawText(
        canvas,
        '© OpenStreetMap contributors • OAuth 2.0 (${OsmConfig.clientId.substring(0, 10)}...)',
        const Offset(400, 680),
        const Color(0xFF0284C7),
        11,
        FontWeight.w700,
      );
    }

    canvas.restore();
  }

  void _drawRoadsNetwork(Canvas canvas) {
    // Road styling
    final asphaltMajor = isSatellite ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final asphaltMinor = isSatellite ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final roadBorder = isSatellite ? const Color(0xFF1E293B) : const Color(0xFF94A3B8);

    // -------------------------------------------------------
    // Road 1: Airport Road (East-West Major Arterial Highway to BAUST & Airport)
    // -------------------------------------------------------
    final airportBorder = Paint()
      ..color = roadBorder
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(40, 240), const Offset(760, 240), airportBorder);

    final airportFill = Paint()
      ..color = asphaltMajor
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(40, 240), const Offset(760, 240), airportFill);

    // Airport Road center dashed divider
    _drawDashedLine(
      canvas,
      const Offset(40, 240),
      const Offset(760, 240),
      const Color(0xFFEAB308),
      1.8,
      8,
      6,
    );

    // -------------------------------------------------------
    // Road 2: Cantt Bazar Road (North-South Cantonment Highway)
    // -------------------------------------------------------
    final canttBorder = Paint()
      ..color = roadBorder
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(560, 40), const Offset(560, 560), canttBorder);

    final canttSurface = Paint()
      ..color = asphaltMajor
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(560, 40), const Offset(560, 560), canttSurface);

    _drawDashedLine(
      canvas,
      const Offset(560, 40),
      const Offset(560, 560),
      Colors.white.withValues(alpha: 0.9),
      1.8,
      10,
      8,
    );

    // -------------------------------------------------------
    // Road 3: Sailar Mor Connector (Diagonal Junction Arterial)
    // -------------------------------------------------------
    final sailarBorder = Paint()
      ..color = roadBorder
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(100, 100), const Offset(680, 460), sailarBorder);

    final sailarFill = Paint()
      ..color = asphaltMajor
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(100, 100), const Offset(680, 460), sailarFill);

    // -------------------------------------------------------
    // Road 4: Terminal Bypass Road (North Terminal Arterial)
    // -------------------------------------------------------
    final terminalBorder = Paint()
      ..color = roadBorder
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(60, 120), const Offset(740, 120), terminalBorder);

    final terminalFill = Paint()
      ..color = asphaltMinor
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(60, 120), const Offset(740, 120), terminalFill);

    // -------------------------------------------------------
    // Road 5: Station Road / Saidpur Bazar (City Center Arterial)
    // -------------------------------------------------------
    final stationBorder = Paint()
      ..color = roadBorder
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(220, 60), const Offset(220, 540), stationBorder);

    final stationFill = Paint()
      ..color = asphaltMajor
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(220, 60), const Offset(220, 540), stationFill);

    // -------------------------------------------------------
    // Road 6: Church Road (Link to Christian Church)
    // -------------------------------------------------------
    final churchBorder = Paint()
      ..color = roadBorder
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(120, 320), const Offset(390, 320), churchBorder);

    final churchFill = Paint()
      ..color = asphaltMinor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(120, 320), const Offset(390, 320), churchFill);

    // Intersection crosswalk markings
    _drawCrosswalk(canvas, const Offset(220, 225), isHorizontal: true);
    _drawCrosswalk(canvas, const Offset(390, 225), isHorizontal: true);
    _drawCrosswalk(canvas, const Offset(560, 225), isHorizontal: true);

    // Road Labels & Landmark tags
    final labelColor = isSatellite ? Colors.white70 : const Color(0xFF475569);
    final accentLabelColor = isSatellite ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);

    _drawText(canvas, 'AIRPORT ROAD (Saidpur-Rangpur Highway)', const Offset(150, 230), labelColor, 10, FontWeight.w700);
    _drawText(canvas, 'CANTT BAZAR ROAD', const Offset(575, 90), labelColor, 10, FontWeight.w700, angle: math.pi / 2);
    _drawText(canvas, 'SAILAR MOR JUNCTION', const Offset(350, 205), labelColor, 10, FontWeight.w700, angle: 0.55);
    _drawText(canvas, 'TERMINAL BYPASS ROAD (Central Terminal)', const Offset(220, 110), labelColor, 9, FontWeight.w600);
    _drawText(canvas, 'STATION ROAD (Saidpur Bazar)', const Offset(232, 110), labelColor, 9, FontWeight.w600, angle: math.pi / 2);
    _drawText(canvas, 'CHURCH ROAD', const Offset(180, 310), labelColor, 9, FontWeight.w600);

    // Landmark Callout Badges (Restaurants & Key Places)
    _drawText(canvas, '★ Taste & GO Restaurant', const Offset(232, 440), accentLabelColor, 9, FontWeight.w700);
    _drawText(canvas, '★ Waffle Street Restaurant', const Offset(575, 100), accentLabelColor, 9, FontWeight.w700);
    _drawText(canvas, '✈ Saidpur Airport (SPD)', const Offset(660, 230), const Color(0xFF0284C7), 9, FontWeight.w700);
    _drawText(canvas, '🚂 Saidpur Railway Station', const Offset(232, 370), const Color(0xFF0D9488), 9, FontWeight.w700);
    _drawText(canvas, '⛪ Christian Church', const Offset(180, 335), const Color(0xFF7C3AED), 9, FontWeight.w700);
    _drawText(canvas, '🏢 Cantt Bazar Hub', const Offset(575, 180), const Color(0xFFB45309), 9, FontWeight.w700);
    _drawText(canvas, '🚌 Central Bus Terminal', const Offset(660, 110), const Color(0xFFC026D3), 9, FontWeight.w700);
    _drawText(canvas, '🛍 Saidpur Bazar', const Offset(390, 465), const Color(0xFFEA580C), 9, FontWeight.w700);
  }

  void _drawCrosswalk(Canvas canvas, Offset center, {required bool isHorizontal}) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;

    for (int i = -3; i <= 3; i++) {
      if (isHorizontal) {
        canvas.drawLine(
          Offset(center.dx + i * 4, center.dy - 3),
          Offset(center.dx + i * 4, center.dy + 3),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(center.dx - 3, center.dy + i * 4),
          Offset(center.dx + 3, center.dy + i * 4),
          paint,
        );
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width,
    double dashLength,
    double dashSpace,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalDist = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / totalDist;
    final unitY = dy / totalDist;

    double currentDist = 0.0;
    while (currentDist < totalDist) {
      final p1 = Offset(start.dx + unitX * currentDist, start.dy + unitY * currentDist);
      final p2Dist = math.min(currentDist + dashLength, totalDist);
      final p2 = Offset(start.dx + unitX * p2Dist, start.dy + unitY * p2Dist);
      canvas.drawLine(p1, p2, paint);
      currentDist += dashLength + dashSpace;
    }
  }

  void _drawTruckMarker(Canvas canvas) {
    // 0. Breadcrumb trail from real-time phone GPS tracking
    if (breadcrumbs.length >= 2) {
      final trailPaint = Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.65)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final trailPath = Path();
      bool first = true;
      for (final pt in breadcrumbs) {
        const baseLat = 25.7685;
        const baseLon = 88.9080;
        final dx = (pt.longitude - baseLon) * 16000.0;
        final dy = -(pt.latitude - baseLat) * 16000.0;
        final offset = Offset((400.0 + dx).clamp(50.0, 750.0), (290.0 + dy).clamp(50.0, 550.0));
        if (first) {
          trailPath.moveTo(offset.dx, offset.dy);
          first = false;
        } else {
          trailPath.lineTo(offset.dx, offset.dy);
        }
      }
      canvas.drawPath(trailPath, trailPaint);
    }

    // 0.1 GPS Accuracy Halo Ring
    if (userLocation != null && userLocation!.isLiveGps) {
      final accuracyRadius = (userLocation!.accuracy * 1.5).clamp(16.0, 65.0);
      final accuracyPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(truckPosition, accuracyRadius, accuracyPaint);

      final accuracyBorder = Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(truckPosition, accuracyRadius, accuracyBorder);
    }

    // 1. Radar Scanning Cone forward from truck
    const scanConeAngle = 0.65; // ~37 degrees spread
    const scanRadius = 75.0;

    final conePath = Path()
      ..moveTo(truckPosition.dx, truckPosition.dy)
      ..arcTo(
        Rect.fromCircle(center: truckPosition, radius: scanRadius),
        truckHeadingAngle - scanConeAngle / 2,
        scanConeAngle,
        false,
      )
      ..close();

    final scanGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        const Color(0xFF09495C).withValues(alpha: 0.35),
        const Color(0xFF14B8A6).withValues(alpha: 0.08),
        Colors.transparent,
      ],
    );

    final scanPaint = Paint()
      ..shader = scanGradient.createShader(Rect.fromCircle(center: truckPosition, radius: scanRadius));
    canvas.drawPath(conePath, scanPaint);

    // Animated scan sweep arc
    final sweepAngle = truckHeadingAngle - scanConeAngle / 2 + scanConeAngle * (animValue * 3 % 1.0);
    final sweepPaint = Paint()
      ..color = const Color(0xFF14B8A6).withValues(alpha: 0.6)
      ..strokeWidth = 2.0;

    final sweepTarget = Offset(
      truckPosition.dx + scanRadius * math.cos(sweepAngle),
      truckPosition.dy + scanRadius * math.sin(sweepAngle),
    );
    canvas.drawLine(truckPosition, sweepTarget, sweepPaint);

    // 2. Outer glowing ring
    final pulse = 0.6 + 0.4 * math.sin(animValue * 4 * math.pi).abs();
    final haloPaint = Paint()
      ..color = const Color(0xFF09495C).withValues(alpha: 0.25 * pulse);
    canvas.drawCircle(truckPosition, 18, haloPaint);

    // 3. Vehicle Circle
    final truckPaint = Paint()..color = const Color(0xFF09495C);
    canvas.drawCircle(truckPosition, 11, truckPaint);

    final truckBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(truckPosition, 11, truckBorder);

    // Direction indicator arrowhead
    final headOffset = Offset(
      truckPosition.dx + 13 * math.cos(truckHeadingAngle),
      truckPosition.dy + 13 * math.sin(truckHeadingAngle),
    );
    final headPaint = Paint()..color = const Color(0xFF14B8A6);
    canvas.drawCircle(headOffset, 3.5, headPaint);

    // Callout pill above truck: "Truck #14 • 35 mph"
    final calloutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(truckPosition.dx, truckPosition.dy - 22),
        width: 104,
        height: 18,
      ),
      const Radius.circular(9),
    );

    final calloutPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.88);
    canvas.drawRRect(calloutRect, calloutPaint);

    _drawText(
      canvas,
      '$truckName • $vehicleSpeed mph',
      Offset(truckPosition.dx, truckPosition.dy - 22),
      Colors.white,
      9,
      FontWeight.w700,
    );
  }

  void _drawDefectPins(Canvas canvas) {
    for (final pin in pins) {
      final isSelected = selectedPin?.id == pin.id;
      final pos = pin.position;

      Color pinColor;
      if (pin.isCleared) {
        pinColor = AppTheme.scanGreen;
      } else if (pin.severity.toLowerCase() == 'urgent') {
        pinColor = AppTheme.urgentRed;
      } else {
        pinColor = const Color(0xFFD97706); // Amber
      }

      // If selected or urgent, draw animated outer pulse halo
      if (isSelected || pin.severity.toLowerCase() == 'urgent') {
        final haloPulse = 0.5 + 0.5 * math.sin(animValue * 3 * math.pi + pin.position.dx).abs();
        final haloPaint = Paint()
          ..color = pinColor.withValues(alpha: isSelected ? 0.35 : 0.2 * haloPulse);
        canvas.drawCircle(pos, isSelected ? 22 : 16, haloPaint);
      }

      // Pin Pinhead Circle
      final pinPaint = Paint()..color = pinColor;
      canvas.drawCircle(pos, isSelected ? 12 : 9, pinPaint);

      final pinBorder = Paint()
        ..color = Colors.white
        ..strokeWidth = isSelected ? 2.5 : 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, isSelected ? 12 : 9, pinBorder);

      // Icon symbol inside pin
      if (pin.isCleared) {
        // White checkmark
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(pos.dx - 3, pos.dy), Offset(pos.dx - 1, pos.dy + 3), checkPaint);
        canvas.drawLine(Offset(pos.dx - 1, pos.dy + 3), Offset(pos.dx + 4, pos.dy - 3), checkPaint);
      } else if (pin.isPothole) {
        // Inner white circle (cavity void)
        final cavityPaint = Paint()..color = Colors.white;
        canvas.drawCircle(pos, isSelected ? 4 : 3, cavityPaint);
      } else {
        // Crack zigzag line
        final crackPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(pos.dx - 3, pos.dy - 2), Offset(pos.dx, pos.dy + 2), crackPaint);
        canvas.drawLine(Offset(pos.dx, pos.dy + 2), Offset(pos.dx + 3, pos.dy - 1), crackPaint);
      }

      // Defect label below pin
      _drawText(
        canvas,
        pin.title,
        Offset(pos.dx, pos.dy + (isSelected ? 18 : 14)),
        isSatellite ? Colors.white : AppTheme.textPrimary,
        isSelected ? 11 : 9.5,
        isSelected ? FontWeight.w700 : FontWeight.w600,
      );
    }
  }

  void _drawOsmNotes(Canvas canvas) {
    final noteList = osmNotes.isNotEmpty
        ? osmNotes
        : const [
            OsmNote(
              id: 4028971,
              latitude: 25.76088,
              longitude: 88.91778,
              status: 'open',
              dateCreated: '2023-12-15',
              text: 'BAUST Campus Hazard',
              url: 'https://api.openstreetmap.org/api/0.6/notes/4028971',
            ),
            OsmNote(
              id: 4028969,
              latitude: 25.76210,
              longitude: 88.91500,
              status: 'open',
              dateCreated: '2023-12-15',
              text: 'Airport Road Joint',
              url: 'https://api.openstreetmap.org/api/0.6/notes/4028969',
            ),
          ];

    final notePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    final noteBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final samplePositions = [
      const Offset(170, 290),
      const Offset(470, 310),
      const Offset(310, 190),
    ];

    for (int i = 0; i < noteList.length && i < samplePositions.length; i++) {
      final note = noteList[i];
      final pos = samplePositions[i];

      // Draw shadow
      canvas.drawCircle(
        Offset(pos.dx, pos.dy + 2),
        10,
        Paint()..color = Colors.black26,
      );

      // Pin circle
      canvas.drawCircle(pos, 10, notePaint);
      canvas.drawCircle(pos, 10, noteBorderPaint);

      // Text inside note marker
      _drawText(
        canvas,
        'OSM',
        pos,
        Colors.white,
        7.5,
        FontWeight.w800,
      );

      // Note label
      final shortText = note.text.length > 15 ? '${note.text.substring(0, 15)}...' : note.text;
      _drawText(
        canvas,
        'OSM #${note.id}: $shortText',
        Offset(pos.dx, pos.dy + 16),
        const Color(0xFF0369A1),
        9.0,
        FontWeight.w700,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize,
    FontWeight fontWeight, {
    double angle = 0.0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (angle != 0.0) {
      canvas.rotate(angle);
    }

    final textSpan = TextSpan(
      text: text,
      style: GoogleFonts.inter(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GisRoadNetworkPainter oldDelegate) {
    return true; // continuous animation for truck & scanning sweep
  }
}
