# RoadSense Project Roadmap

## Active Milestones

### Phase 1: AI Vision Pothole Verification & Camera Detection Pipeline
- **Status:** In Planning
- **Goal:** Replace static and false-positive camera detection states with an authenticated Gemini Vision verification pipeline (`gemini-2.5-flash`), enforcing strict confidence thresholds (> 0.75) and fail-safe error defaults.
- **Plans:**
  - `01-01-PLAN.md`: Gemini 2.5 Flash Vision verification contract, fail-safe state pipeline, confidence gating (> 0.75), and UI HUD overhaul.

### Phase 2: Live Interactive OpenStreetMap View & Real-Time Device GPS Tracking
- **Status:** Planned
- **Goal:** Replace the hardcoded static map canvas on the "Defect GIS & Road Map" screen with a live, interactive OpenStreetMap view and real-time device GPS tracking for the Flutter APK.
- **Plans:** 1 plan
- **Plan List:**
  - [ ] 02-01-PLAN.md — Live OpenStreetMap interactive map integration (flutter_map, latlong2), native Android GPS tracking (geolocator), MapController viewport bindings, and dynamic defect MarkerLayer pins.

### Phase 3: Offline Edge Inference & TFLite Fallback
- **Status:** Backlog
- **Goal:** Add on-device TensorFlow Lite model for offline edge inspection when internet connection is completely unavailable.

### Phase 4: Automated Municipal Work Order Generation
- **Status:** Backlog
- **Goal:** Automatically convert verified high-confidence potholes (> 0.85) into draft work orders with assigned crews and budget allocations.
