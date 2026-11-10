export 'package:road_sense/screens/camera_screen.dart';

import 'package:flutter/material.dart';
import 'package:road_sense/screens/camera_screen.dart';

/// FieldCaptureScreen: Backward-compatible alias forwarding directly to [CameraScreen]
/// to provide the live road camera viewfinder and AI hazard detection.
class FieldCaptureScreen extends StatelessWidget {
  const FieldCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraScreen();
  }
}
