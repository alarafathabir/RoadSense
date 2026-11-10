---
phase: "2"
slug: "live-interactive-openstreetmap-view-real-time-device-gps-tra"
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| **Quick run command** | `flutter test test/screens/map_screen_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/screens/map_screen_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | REQ-MAP-01 (Dependencies) | — | Dependencies resolve cleanly | command | `flutter pub get` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | REQ-MAP-02 (Permissions) | — | Android location permissions checked safely | unit | `flutter test test/services/location_service_test.dart` | ✅ | ⬜ pending |
| 02-01-03 | 01 | 2 | REQ-MAP-03 (FlutterMap & Tiles) | — | Slippy OSM tiles rendered with user agent | widget | `flutter test test/screens/map_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 2 | REQ-MAP-04 (Live GPS & Badge) | — | Live telemetry updates badge and car marker | widget | `flutter test test/screens/map_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-05 | 01 | 3 | REQ-MAP-05 (MapController Controls) | — | Zoom +, Zoom -, and Re-center move camera | widget | `flutter test test/screens/map_screen_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-06 | 01 | 3 | REQ-MAP-06 (Defect MarkerLayer) | — | Pins filtered by chips and select quick card | widget | `flutter test test/screens/map_screen_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/screens/map_screen_test.dart` — widget tests for FlutterMap, MapController, and defect marker filtering
- [ ] `test/services/location_service_test.dart` — unit tests for location permissions and coordinates formatting

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real GPS hardware movement tracking | REQ-MAP-04 | Requires physical device GPS satellite reception | Run APK on physical Android device outdoors and verify truck moves along road |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending 2026-11-11
