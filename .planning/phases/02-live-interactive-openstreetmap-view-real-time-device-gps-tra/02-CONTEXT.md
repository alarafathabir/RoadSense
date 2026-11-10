# Phase 2 Context: Live Interactive OpenStreetMap View & Real-Time Device GPS Tracking

## User Intent & Scope
Replace the hardcoded static map canvas on the "Defect GIS & Road Map" screen with a live, interactive OpenStreetMap view and real-time device GPS tracking for the Flutter APK.

## Core Scope & Technical Requirements

### 1. Dependencies & Android Permissions
- Add `flutter_map` and `latlong2` to `pubspec.yaml` for rendering OpenStreetMap tiles, markers, and layers.
- Verify and ensure `geolocator: ^14.1.2` is configured for native device GPS access.
- Confirm Android permissions in `android/app/src/main/AndroidManifest.xml`:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.ACCESS_COARSE_LOCATION`

### 2. Live Device Location (Geolocator)
- Request runtime location permissions automatically when opening the Map tab.
- Fetch initial GPS fix using `Geolocator.getCurrentPosition` (via `LocationService` / `AppState`).
- Subscribe to continuous position updates via `Geolocator.getPositionStream` for live telemetry and tracking.
- Replace the hardcoded coordinate badge (`25.7685° N, 88.9080° E`) and road label at the bottom with live GPS coordinates (latitude, longitude, accuracy) from the device.

### 3. OpenStreetMap & API Integration
- Replace the static custom road illustration / canvas with a real interactive `FlutterMap` widget.
- Configure `TileLayer` connected to the official OpenStreetMap tile server (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`) with appropriate `User-Agent` headers in compliance with OSM usage policy.
- Bind the right-side floating control buttons (+, -, re-center crosshair, and GPS tracking pin) to a `MapController`:
  - `+` button zooms in the map (`mapController.move(center, zoom + 1)`).
  - `-` button zooms out the map (`mapController.move(center, zoom - 1)`).
  - Re-center crosshair centers the map camera immediately onto the phone's live GPS coordinates (`LatLng(latitude, longitude)`).
  - GPS pin toggles/resumes live location stream tracking.
- Render dynamic `MarkerLayer` pins for detected potholes and cracks based on geographic coordinates (`LatLng`).
- Connect marker filtering to the top selection chips ("All Defects", "Potholes Only", "Cracks Only", "High Severity").
- Tapping a defect marker pops up the detailed `DefectQuickCard` with action options (Dispatch, Verify, OSM Sync).

## Architecture Boundaries
- Keep UI responsive and smooth during continuous GPS updates.
- Gracefully handle cases where location permission is denied or location services are disabled by falling back to default municipal coordinates (Saidpur, Rangpur: `25.7685° N, 88.9080° E`) without crashing.
- Maintain existing OSM OAuth 2.0 client configuration in `lib/config/osm_config.dart` and `lib/services/osm_service.dart`.
