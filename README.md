# 🛣️ RoadSense — Intelligent Road Quality Monitoring & Assessment Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Gemini AI](https://img.shields.io/badge/Google_Gemini-Multimodal_AI-8E75C2?logo=google)](https://ai.google.dev/)
[![OpenStreetMap](https://img.shields.io/badge/OpenStreetMap-OAuth_2.0-7EBC6F?logo=openstreetmap)](https://www.openstreetmap.org)
[![Tests](https://img.shields.io/badge/Tests-Passing_29%2F29-success)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**RoadSense** is a mobile and web-ready road quality monitoring, asset management, and automated pavement condition assessment system built with Flutter and Dart.

Designed for highway authorities, civil municipal inspectors, and road maintenance crews, RoadSense brings together **Google Gemini Multimodal AI**, **OpenStreetMap (OSM) OAuth 2.0 Integration**, **Real-Time GPS Telemetry**, and **Dynamic Repair Dispatching** into a unified, cyber-themed responsive interface.

---

## 🌟 Key Features

### 1. 🤖 Multimodal AI Road Inspection (Google Gemini)
- **Automated Pavement Defect Classification:** Uses Gemini Multimodal AI (`gemini-3.5-flash-lite` and `gemini-3.8-flash`) to analyze road camera frames in real time.
- **Defect Detection:** Accurately classifies and rates potholes, longitudinal/alligator cracks, rutting, and surface roughness.
- **Automated Cost & Repair Prediction:** Predicts repair severity and computes estimated maintenance budgets in Bangladeshi Taka (`৳`).

### 2. 🗺️ OpenStreetMap (OSM) Integration & Crowdsourced Reporting
- **OSM OAuth 2.0 Workflow:** Secure authentication flow supporting authorized contributor actions.
- **Geospatial Road Segment Tagging:** Queries highway classifications (`motorway`, `trunk`, `primary`, `secondary`, `residential`) and surface attributes directly from OSM.
- **OSM Note Creation:** Directly submits geo-tagged defect reports to OpenStreetMap as field inspection notes.

### 3. 📍 Real-Time GPS & Telemetry Tracking
- **High-Accuracy Geolocation:** Continuous live GPS coordinate streaming using `geolocator`.
- **Live Speed Telemetry:** Real-time speed calculation displayed in both `km/h` and `mph`.
- **Breadcrumb Trail:** Visual path recording to trace inspection routes and survey passes.
- **Interactive Defect Overlays:** Map pins with defect severity indicators and live radar sweeps.

### 4. 📊 Dynamic Metrics Dashboard & Asset Analytics
- **Pavement Condition Index (PCI):** Real-time road health score computed across inspected segments.
- **Dynamic Metric Recalculation:** Instant dashboard updates whenever defects are detected, resolved, or marked completed.
- **Manual Calibration Sheet:** Allows road authorities and supervisors to calibrate and edit live metrics manually.

### 5. 🛠️ Maintenance & Repair Crew Dispatching
- **Task Management:** Filter maintenance tasks by status (`All`, `Urgent`, `In Progress`, `Completed`).
- **Crew Allocation:** Assign municipal repair crews, track progress, and record repair timestamps.
- **Budget Tracking:** Real-time budget expenditure tracking in Bangladeshi Taka (`৳`).

### 6. 👤 Inspector Profile & Custom Avatar Backend Microservice
- **Profile Management:** Inspector identity, role, credentials, and field assessment counters.
- **Dart Microservice:** Standalone local HTTP server (`backend/server.dart`) handling multipart avatar uploads and metadata persistence.

---

## 🏛️ Project Architecture

```text
road_sense/
├── android/                 # Android native runner & permissions
├── assets/
│   └── images/              # App branding, logo, and inspection camera feed
├── backend/
│   ├── server.dart          # Local Dart HTTP API server (CORS, OSM proxy, uploads)
│   ├── avatar_metadata.json # Inspector profile metadata
│   └── uploads/             # Server avatar upload storage
├── ios/                     # iOS native runner & configuration
├── lib/
│   ├── config/
│   │   ├── gemini_config.dart   # Gemini API endpoints & model specifications
│   │   └── osm_config.dart      # OpenStreetMap OAuth 2.0 endpoints & client config
│   ├── screens/
│   │   ├── home_screen.dart           # Dashboard, health metrics, quick actions
│   │   ├── camera_screen.dart         # AI camera HUD & live detection feed
│   │   ├── map_screen.dart            # OSM map, defect markers, GPS telemetry
│   │   ├── repair_tasks_screen.dart   # Crew dispatching & task status tracking
│   │   ├── asset_analysis_screen.dart # Pavement Condition Index analytics
│   │   ├── field_capture_screen.dart  # Rapid field defect capture
│   │   ├── reports_screen.dart        # Road survey history & report export
│   │   └── profile_screen.dart        # Inspector credentials & photo upload
│   ├── services/
│   │   ├── gemini_road_service.dart   # Multimodal road evaluation service
│   │   ├── location_service.dart      # High-accuracy GPS streaming & speed conversion
│   │   └── osm_service.dart           # OpenStreetMap API & note creation client
│   ├── state/
│   │   └── app_state.dart             # Central ChangeNotifier application state
│   ├── theme/
│   │   └── app_theme.dart             # Modern dark & light Cyberpunk theme palettes
│   ├── widgets/
│   │   ├── feature_card.dart          # Interactive status/metric cards
│   │   ├── gradient_button.dart       # Neon glowing action buttons
│   │   └── inspector_avatar.dart      # Avatar image picker & upload widget
│   └── main.dart            # Flutter application entry point
├── test/                    # Unit, widget, and integration test suite (29 tests)
│   ├── gemini_road_evaluation_test.dart
│   ├── osm_integration_test.dart
│   ├── realtime_location_tracking_test.dart
│   ├── road_sense_test.dart
│   └── widget_test.dart
├── web/                     # Web platform runner & manifest
├── analysis_options.yaml    # Dart static analysis configuration
├── pubspec.yaml             # Flutter dependencies & assets definition
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>= 3.0.0 < 4.0.0`)
- [Dart SDK](https://dart.dev/get-dart)
- An active Internet connection for Google Gemini & OpenStreetMap features

### 1. Clone the Repository
```bash
git clone https://github.com/alarafathabir/RoadSense.git
cd RoadSense
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Start the Backend Microservice (Optional for Avatar/Proxy)
The app includes a lightweight Dart HTTP server for image uploads and proxy calls:
```bash
dart run backend/server.dart
```
The server will start listening at `http://localhost:8080`.

### 4. Run the Flutter Application
Run on your preferred connected device or emulator:
```bash
# For Chrome (Web)
flutter run -d chrome

# For Android
flutter run -d android

# For Windows Desktop
flutter run -d windows
```

---

## 🧪 Testing

The repository contains an automated test suite covering state management, AI evaluations, OpenStreetMap integration, and UI flows:

```bash
flutter test
```

All **29/29 tests** execute and pass out-of-the-box.

---

## ⚙️ Configuration

### Google Gemini API
Model and endpoint settings are managed in [`lib/config/gemini_config.dart`](lib/config/gemini_config.dart):
- **Primary Model:** `gemini-3.5-flash-lite` (low-latency road classification)
- **Advanced Model:** `gemini-3.8-flash` (in-depth pavement structural analysis)

### OpenStreetMap (OSM)
OAuth credentials and endpoint configurations are located in [`lib/config/osm_config.dart`](lib/config/osm_config.dart).

---

## 📄 License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author
**Al Arafath Abir Ahmed**
- GitHub: [@alarafathabir](https://github.com/alarafathabir)
