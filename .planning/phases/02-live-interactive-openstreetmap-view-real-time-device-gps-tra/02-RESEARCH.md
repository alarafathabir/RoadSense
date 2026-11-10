# Phase 2: Live Interactive OpenStreetMap View & Real-Time Device GPS Tracking - Research

**Researched:** 2026-11-11
**Domain:** Flutter Mobile GIS, OpenStreetMap Integration, Native GPS Telemetry
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Replace the hardcoded static road illustration on the "Defect GIS & Road Map" screen with an interactive `FlutterMap` widget.
- Use `flutter_map` (^8.3.2) and `latlong2` (^0.10.1) for tile rendering, markers, and vector map controls.
- Use `geolocator` (^14.1.2) for native device GPS access, runtime permission handling, initial position acquisition, and continuous position streaming.
- Declare `INTERNET`, `ACCESS_FINE_LOCATION`, and `ACCESS_COARSE_LOCATION` in `android/app/src/main/AndroidManifest.xml`.
- Bind the floating map controls (+, -, crosshair, and GPS pin) to a `MapController`.
- Dynamic `MarkerLayer` pins for detected potholes and cracks with active filter chip synchronization.
- Replace the hardcoded coordinate badge (`25.7685° N, 88.9080° E`) with live GPS telemetry.

### Discretion
- Styling of the vehicle tracking marker and defect pin indicators.
- Attribution layout and caching configuration for OpenStreetMap tiles.
</user_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| OSM Tile Rendering | Client UI (FlutterMap) | CDN / OSM Tile Server | Tiles fetched over HTTPS from OpenStreetMap servers |
| Device GPS Stream | Client Native Service (`LocationService` via Geolocator) | Android Location Provider | High accuracy GPS hardware sensor managed natively |
| State Management | Client (`AppState`) | UI View (`MapScreen`) | ChangeNotifier distributes live location and filter state |
| Defect Pins | Client (`DefectMapPin`) | Local Storage / State | Pins mapped by geographic `LatLng` |
</architectural_responsibility_map>

<research_summary>
## Summary
The current `MapScreen` in `lib/screens/map_screen.dart` renders a 700-line synthetic `CustomPainter` (`_GisRoadNetworkPainter`) displaying a hardcoded grid, simulated road curves, and a mock vehicle path that oscillates back and forth. While there is a manual tile mathematical loop in `_buildOsmTileGrid`, it is not an interactive slippy map and lacks standard pan/zoom inertia, tile caching, dynamic markers, and camera coordination.

By integrating `flutter_map: ^8.3.2` and `latlong2: ^0.10.1`:
1. `FlutterMap` provides out-of-the-box hardware-accelerated slippy map rendering, gesture handling (pinch-to-zoom, fling, pan, rotate), and multi-layer compositing (`TileLayer`, `MarkerLayer`, `CircleLayer`).
2. A single `MapController` cleanly drives programmatic camera maneuvers (zoom in, zoom out, smooth re-center on live GPS fix).
3. The existing `LocationService` (which wraps `geolocator: ^14.1.2`) already provides `handlePermission()`, `getCurrentLocation()`, and `getRealtimeLocationStream()`. We wire these directly into `AppState` and bind them to the map camera and coordinate displays.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_map` | `^8.3.2` | Interactive OpenStreetMap widget | Standard community GIS framework for Flutter |
| `latlong2` | `^0.10.1` | Latitude/Longitude math and coordinate primitives | Lightweight coordinate container designed for flutter_map |
| `geolocator` | `^14.1.2` | Native GPS hardware sensor access and permissions | Flutter standard for GPS hardware access on Android/iOS |

### Android Permissions
In `android/app/src/main/AndroidManifest.xml`:
- `android.permission.INTERNET` (for downloading OSM map tiles)
- `android.permission.ACCESS_FINE_LOCATION` (for high-accuracy GPS satellite fix)
- `android.permission.ACCESS_COARSE_LOCATION` (for network/cellular location fallback)
*(Note: all three permissions are already declared in the manifest; verification confirmed)*

</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Component Hierarchy
```
MapScreen (StatefulWidget)
├── Header (Bangladesh Public Works, Live Tracking Indicator)
├── FilterChipsBar (All Defects, Potholes Only, Cracks Only)
└── Expanded Map Stack
    ├── FlutterMap
    │   ├── MapOptions (initialCenter: LatLng(25.7685, 88.9080), initialZoom: 16.0)
    │   ├── TileLayer (https://tile.openstreetmap.org/{z}/{x}/{y}.png, userAgentPackageName: 'com.roadsense.app')
    │   ├── MarkerLayer (Defect pins: Potholes, Cracks)
    │   └── MarkerLayer (Current vehicle/inspector live GPS marker)
    ├── FloatingMapControls (Zoom +, Zoom -, Re-center Crosshair, Live GPS Toggle)
    ├── LiveCoordinateScaleBadge (Real-time Lat/Lon, GPS Accuracy)
    └── DefectQuickCard (Shown when a pin is selected)
```

### Pattern 1: MapController Navigation
```dart
final MapController _mapController = MapController();

void _zoomIn() {
  final currentZoom = _mapController.camera.zoom;
  _mapController.move(_mapController.camera.center, (currentZoom + 1.0).clamp(3.0, 19.0));
}

void _zoomOut() {
  final currentZoom = _mapController.camera.zoom;
  _mapController.move(_mapController.camera.center, (currentZoom - 1.0).clamp(3.0, 19.0));
}

void _centerOnUser(UserLocation loc) {
  _mapController.move(LatLng(loc.latitude, loc.longitude), 16.5);
}
```

### Pattern 2: Dynamic MarkerLayer Generation
```dart
List<Marker> _buildDefectMarkers(List<DefectMapPin> pins) {
  return pins.map((pin) {
    return Marker(
      point: LatLng(pin.latitude, pin.longitude),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => setState(() => _selectedPin = pin),
        child: _buildPinIcon(pin, isSelected: _selectedPin?.id == pin.id),
      ),
    );
  }).toList();
}
```
</architecture_patterns>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: OpenStreetMap Tile Usage Policy Violations
**Issue:** OSM tile servers block apps that lack a custom `User-Agent` or spam tiles without caching.
**Remedy:** Set `userAgentPackageName: 'com.roadsense.app'` or configure custom HTTP headers on `TileLayer`.

### Pitfall 2: Re-centering Loop on Continuous GPS Stream
**Issue:** If the map re-centers to the device location on *every* location stream event, the user cannot manually pan or explore other parts of the map without getting violently snapped back.
**Remedy:** Continuous GPS updates should only update the live inspector vehicle marker and the bottom coordinates badge. Re-centering the map viewport should occur on the initial fix or when the user explicitly taps the crosshair button.

### Pitfall 3: Permission Denied Crash
**Issue:** If GPS permission is denied or location hardware is off, calling `Geolocator.getCurrentPosition` throws an exception.
**Remedy:** Wrap in `try-catch`, handle `LocationPermission.denied` and `LocationPermission.deniedForever`, and fall back to default Saidpur coordinates without crashing.
</common_pitfalls>

## Validation Architecture

### Automated Verification Plan
1. **Dependency Analysis:** Run `flutter pub get` and verify `flutter_map` and `latlong2` resolve without conflicts.
2. **Static Analysis:** Run `flutter analyze` ensuring zero compiler errors or warnings on `MapScreen`, `LocationService`, and `AppState`.
3. **Unit Tests:**
   - Test `LocationService.getCurrentLocation()` with mock positions.
   - Test `AppState` location stream subscription and coordinate formatting.
   - Test defect pin filtering logic for 'All Defects', 'Potholes Only', 'Cracks Only'.
4. **Widget Tests:**
   - Test `MapScreen` renders `FlutterMap` and `TileLayer`.
   - Test tapping `+` and `-` zoom controls updates `MapController`.
   - Test tapping crosshair button triggers `MapController.move`.
   - Test coordinate badge displays live coordinates.
