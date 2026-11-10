# RoadSense Project Architecture & Specification

## Executive Summary
RoadSense is a road quality monitoring, civil infrastructure asset management, and automated pavement condition assessment platform built with Flutter, Dart, and Google Gemini Multimodal AI.

## Core Capabilities
- **Multimodal AI Vision:** Real-time road camera frame inspection with Google Gemini (potholes, cracks, rutting, roughness, severity grading, cost estimation in BDT ৳).
- **OpenStreetMap (OSM) Integration:** OAuth 2.0 authentication, roadway tag classification, and live defect note submission.
- **Geospatial Telemetry:** High-accuracy GPS tracking, live speed computation (km/h & mph), and breadcrumb routing.
- **Municipal Maintenance:** Repair task tracking, crew dispatching, and dynamic budget auditing.
- **Local Dart Microservice:** `backend/server.dart` HTTP microservice for multipart avatar uploads and API proxying.

## Technology Stack
- **Frontend / Framework:** Flutter 3.x, Dart 3.x
- **State Management:** Provider / ChangeNotifier (`AppState`)
- **AI Models:** Google Gemini Vision (`gemini-2.5-flash`, `gemini-3.5-flash-lite`, `gemini-3.8-flash`)
- **Geospatial / GIS:** `geolocator`, OpenStreetMap API v0.6
- **Testing:** `flutter_test` (Unit, Widget, and Integration test suites)
