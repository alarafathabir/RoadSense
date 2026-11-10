# RoadSense Project Roadmap

## Active Milestones

### Phase 1: AI Vision Pothole Verification & Camera Detection Pipeline
- **Status:** Complete (Verified: 33/33 tests passing)
- **Goal:** Replace static and false-positive camera detection states with an authenticated Gemini Vision verification pipeline (`gemini-2.5-flash`), enforcing strict confidence thresholds (> 0.75) and fail-safe error defaults.
- **Plans:**
  - `01-01-PLAN.md`: Gemini 2.5 Flash Vision verification contract, fail-safe state pipeline, confidence gating (> 0.75), and UI HUD overhaul. (Completed)

### Phase 2: Offline Edge Inference & TFLite Fallback
- **Status:** Backlog
- **Goal:** Add on-device TensorFlow Lite model for offline edge inspection when internet connection is completely unavailable.

### Phase 3: Automated Municipal Work Order Generation
- **Status:** Backlog
- **Goal:** Automatically convert verified high-confidence potholes (> 0.85) into draft work orders with assigned crews and budget allocations.
