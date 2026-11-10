---
phase: "2"
slug: "live-interactive-openstreetmap-view-real-time-device-gps-tra"
status: approved
shadcn_initialized: false
preset: not applicable
created: "2026-11-11"
---

# Phase 2 — UI Design Contract: Live Interactive OpenStreetMap View & Real-Time Device GPS Tracking

> Visual and interaction contract for the "Defect GIS & Road Map" screen.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Flutter Material 3 |
| Preset | not applicable |
| Component library | Flutter Framework + flutter_map |
| Icon library | Icons (Material Icons) |
| Font | Google Fonts Inter |

---

## Spacing Scale

Declared values (multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, badge padding, small margins |
| sm | 8px | Button margins, chip item spacing, pill gap |
| md | 16px | Section horizontal padding, floating controls offset |
| lg | 20px | Header padding, quick card interior padding |
| xl | 24px | Major view offsets |
| 2xl | 32px | Dialog margins |
| 3xl | 48px | Map control floating heights |

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Display / Screen Title | 22px | 700 (Bold) | 1.2 |
| Section / Subhead | 13px | 400 (Regular) | 1.3 |
| Pill & Live Badge | 12px | 600 (Semi-bold) | 1.2 |
| Filter Chip Text | 12px | 500 / 600 | 1.2 |
| Coordinates / Scale | 10px | 600 (Semi-bold) | 1.2 |
| Attribution Text | 9.5px | 500 (Medium) | 1.1 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F8FAFC` / `#FFFFFF` | Background, card surfaces, control container |
| Secondary (30%) | `#09495C` (Primary Teal) | Active filter chips, brand accents, action CTAs |
| Accent (10%) | `#16A34A` (Scan Green) | Live GPS tracking indicator, active GPS status |
| Urgent / Danger | `#DC2626` (Urgent Red) | High-severity pothole markers, critical alerts |
| Warning / Medium | `#B45309` (Amber) | Medium-severity asphalt crack markers |
| Destructive | `#DC2626` | Dismiss / clear action |

Accent reserved for:
- Live GPS pulse dot and "GPS RTK 99.8%" indicator
- Re-center / Locate Phone GPS crosshair button
- Live tracking active toggle state

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Header Title | Defect GIS & Road Map |
| Header Subtitle | Bangladesh Public Works • Saidpur, Rangpur |
| Live Tracking Pill | LIVE TRACKING: {Truck} ({Inspector}) • {Speed} mph |
| Live GPS Coordinates Badge | 200 m • {lat.toFixed(4)}° N, {lon.toFixed(4)}° E |
| Locate Toast / SnackBar | 📍 Located via OpenStreetMap: {Street} \n{Coordinates} (±{Accuracy}m) |
| Empty Filter State | No defects found for selected filter |
| Location Permission Denied Dialog | Location Permission Required: Please grant location permission to view your real-time vehicle position on the road map. |

---

## Interactive Controls & Viewport Binding Contract

| Control | Action | Target / Behavior |
|---------|--------|-------------------|
| Floating `+` Button | Tap | Zoom in map camera by +1.0 zoom level (`mapController.move(center, zoom + 1)`) |
| Floating `-` Button | Tap | Zoom out map camera by -1.0 zoom level (`mapController.move(center, zoom - 1)`) |
| Re-center Crosshair (`my_location_rounded`) | Tap | Animate/center map camera to device's live `LatLng(latitude, longitude)` at zoom 16.0 |
| GPS Pin Toggle (`gps_fixed_rounded`) | Tap | Toggle continuous GPS position stream (`AppState.toggleLocationTracking()`) |
| Filter Chips (`All Defects`, `Potholes Only`, `Cracks Only`) | Tap | Filter `MarkerLayer` pins dynamically without resetting map camera viewport |
| Map Marker Pin | Tap | Select active defect pin and display floating `_buildDefectQuickCard` |

---

## UI Considerations

Applicable state considerations resolved: 4 covered, 0 unresolved

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| {loading} | TileLayer & GPS fix | ✅ covered | OpenStreetMap tile fallback container `#F2EFE9` while loading; initial location defaults to Saidpur municipal center until GPS fix acquired |
| {empty} | Filter chips | ✅ covered | If filter yields 0 pins, map remains fully interactive; no markers rendered on layer |
| {overflow} | Bottom Quick Card | ✅ covered | Quick Card positioned at `bottom: 14` with fixed height, padding `14px`, and scroll-safe content layout |
| {permission} | Geolocator runtime prompt | ✅ covered | Handled asynchronously via `LocationService.instance.handlePermission()` with non-blocking fallback |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-11-11
