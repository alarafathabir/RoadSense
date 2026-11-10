---
phase: "2"
slug: "live-interactive-openstreetmap-view-real-time-device-gps-tra"
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-11"
---

# Phase 2 — Validation Strategy: Live Interactive OpenStreetMap View & Real-Time Device GPS Tracking

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter Test (`package:flutter_test`) |
| **Config file** | `pubspec.yaml` / `analysis_options.yaml` |
| **Quick run command** | `flutter test test/realtime_location_tracking_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~5-10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/realtime_location_tracking_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | REQ-MAP-01 (Dependencies) | T-02-04 | Packages pinned and resolved | command | `flutter pub get` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | REQ-MAP-02 (Live Location & Perms) | T-02-03 | Non-blocking permission handling | unit | `flutter test test/realtime_location_tracking_test.dart --plain-name "3. AppState handles real-time phone location updates"` | ✅ | ⬜ pending |
| 02-01-03 | 01 | 1 | REQ-MAP-03 (FlutterMap & Controls) | T-02-02 | Slippy OSM tiles & MapController controls | widget | `flutter test test/realtime_location_tracking_test.dart --plain-name "4. MapScreen renders OpenStreetMap layer"` | ✅ | ⬜ pending |
| 02-02-01 | 02 | 2 | REQ-MAP-04 (Defect MarkerLayer) | T-02-01 | Geographic coordinate bounds checked | widget | `flutter test test/realtime_location_tracking_test.dart --plain-name "4. MapScreen renders OpenStreetMap layer"` | ✅ | ⬜ pending |
| 02-02-02 | 02 | 2 | REQ-MAP-05 (Automated Test Suite) | — | Full regression test suite pass | test suite | `flutter test test/realtime_location_tracking_test.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/realtime_location_tracking_test.dart` — already present, contains tests for `UserLocation`, `OsmAddress`, `AppState` location tracking, and `MapScreen` widget test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real GPS satellite hardware movement tracking | REQ-MAP-02 | Requires physical device GPS satellite reception | Run APK on physical Android device outdoors and verify truck moves along road |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-11-11
