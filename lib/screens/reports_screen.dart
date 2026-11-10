import 'package:flutter/material.dart';
import 'package:road_sense/screens/repair_tasks_screen.dart';

export 'package:road_sense/screens/repair_tasks_screen.dart';

/// Screen displaying municipal Repair Tasks and budget tracking.
/// Serves as the primary Reports / Tasks view in RoadSense PW navigation.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepairTasksScreen();
  }
}
