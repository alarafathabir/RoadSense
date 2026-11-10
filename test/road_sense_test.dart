import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_sense/main.dart';
import 'package:road_sense/screens/camera_screen.dart';
import 'package:road_sense/screens/home_screen.dart';
import 'package:road_sense/screens/map_screen.dart';
import 'package:road_sense/screens/profile_screen.dart';
import 'package:road_sense/screens/repair_tasks_screen.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';

void main() {
  setUp(() {
    AppState.instance.stopSpeedSimulation();
  });

  tearDown(() {
    AppState.instance.stopSpeedSimulation();
  });

  group('RoadSense Complete Feature Verification', () {
    testWidgets('1. Home Dashboard renders all widgets and metrics accurately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // Header branding
      expect(find.text('RoadSense'), findsOneWidget);
      expect(find.text('Abir'), findsOneWidget);
      expect(find.text('Good morning, Abir'), findsOneWidget);

      // Hero button
      expect(find.text('Start Road Scan'), findsOneWidget);
      expect(find.text('Camera ready'), findsOneWidget);

      // 2x2 Summary grid
      expect(find.text('Roads Checked'), findsOneWidget);
      expect(find.text('Road Health'), findsOneWidget);
      expect(find.text('Potholes Found'), findsOneWidget);
      expect(find.text('Urgent Fixes'), findsOneWidget);
      expect(find.text('142 km'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Recent issues
      expect(find.text('Recent Issues'), findsOneWidget);
      expect(find.text('See All (23)'), findsOneWidget);
      expect(find.text('Airport Road Pothole'), findsOneWidget);
      expect(find.text('Sailar Mor Asphalt Crack'), findsOneWidget);
    });

    testWidgets('2. Camera Screen renders AI HUD and interactive controls',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.resetHazardState();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CameraScreen(),
        ),
      );
      await tester.pump();

      // Card Header
      expect(find.text('Live Road Camera'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Camera HUD overlays: Defaults safely to NO POTHOLE DETECTED
      expect(find.text('AI Scanning Road'), findsOneWidget);
      expect(find.text('Hazard Detection - Active'), findsOneWidget);
      expect(find.text('NO POTHOLE DETECTED'), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
      expect(find.text('GPS OK'), findsOneWidget);

      // When hazard is verified, HUD transitions dynamically to Pothole Detected
      state.setHazardDetected(true);
      await tester.pump();
      expect(find.text('Pothole Detected (High)'), findsOneWidget);
      expect(find.text('Alert'), findsOneWidget);
      expect(find.text('POTHOLE DETECTED'), findsOneWidget);

      // Action buttons
      expect(find.text('Report Issue'), findsOneWidget);
      expect(find.text('Stop Scan'), findsOneWidget);

      // Sound Alert toggle card
      expect(find.text('Sound Alert for Potholes'), findsOneWidget);
      expect(find.text('Beep when damage is detected'), findsOneWidget);

      // Toggle Stop Scan -> Start Scan
      await tester.tap(find.text('Stop Scan'));
      await tester.pump();
      expect(find.text('Start Scan'), findsOneWidget);

      // Resume Scan
      await tester.tap(find.text('Start Scan'));
      await tester.pump();
      expect(find.text('Stop Scan'), findsOneWidget);
    });

    testWidgets('3. Repair Tasks renders budget, tabs, and crew dispatch',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RepairTasksScreen(),
        ),
      );
      await tester.pump();

      // Header
      expect(find.text('Repair Tasks'), findsOneWidget);
      expect(find.text('Bangladesh Public Works'), findsOneWidget);

      // Budget Card
      expect(find.text('Monthly Budget'), findsOneWidget);
      expect(find.text('7 Crews Active'), findsOneWidget);
      expect(find.text('৳42,500'), findsOneWidget);
      expect(find.text('spent of ৳60,000'), findsOneWidget);

      // Advanced Budget Analytics & Breakdown
      expect(find.text('Cost Breakdown & Savings'), findsOneWidget);
      expect(find.text('Asphalt & Mix'), findsOneWidget);
      expect(find.text('Labor & Crews'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);
      expect(find.text('Proactive Cost Savings'), findsOneWidget);
      expect(find.text('+৳119,000'), findsOneWidget);

      // Toggle analytics collapse/expand
      await tester.tap(find.text('Hide'));
      await tester.pump();
      expect(find.text('Asphalt & Mix'), findsNothing);

      await tester.tap(find.text('View'));
      await tester.pump();
      expect(find.text('Asphalt & Mix'), findsOneWidget);

      // Tabs
      expect(find.text('To Do (3)'), findsOneWidget);
      expect(find.text('Done (24)'), findsOneWidget);

      // Tasks in To Do
      expect(find.text('Airport Road Pothole Fix'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.text('Location: Airport Road near BAUST'), findsOneWidget);
      expect(find.text('Send Repair Crew'), findsOneWidget);

      expect(find.text('Sailar Mor Crack Sealing'), findsOneWidget);
      expect(find.text('SCHEDULED'), findsOneWidget);
      expect(find.text('Details'), findsWidgets);

      // Add New Task button
      expect(find.text('+ + Add New Task'), findsOneWidget);

      // Switch to Done tab
      await tester.tap(find.text('Done (24)'));
      await tester.pump();
      expect(find.text('COMPLETED'), findsWidgets);
    });

    testWidgets('4. Profile Screen renders Inspector, Vehicle, and Settings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pump();

      // Inspector Profile
      expect(find.text('Abir'), findsOneWidget);
      expect(find.text('Bangladesh Public Works Inspector'), findsOneWidget);
      expect(find.text('Shift ID: #BPW-Saidpur-4820'), findsOneWidget);

      // Vehicle
      expect(find.text('Current Vehicle'), findsOneWidget);
      expect(find.text('Truck #14'), findsOneWidget);
      expect(find.text('Mahindra Bolero BPW Patrol Unit'), findsOneWidget);
      expect(find.text('Camera & GPS Connected'), findsOneWidget);

      // Shift Assistant Settings
      expect(find.text('Shift Assistant Settings'), findsOneWidget);
      expect(find.text('Auto-Save Potholes'), findsOneWidget);
      expect(find.text('Voice Alerts'), findsOneWidget);
      expect(find.text('Offline Storage'), findsOneWidget);

      // End Shift button
      expect(find.text('End Inspection Shift'), findsOneWidget);
      expect(find.text('Need Help? Call Bangladesh Public Works Support (Saidpur)'),
          findsOneWidget);
    });

    testWidgets('5. Map Screen renders Defect GIS and filters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MapScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Defect GIS & Road Map'), findsOneWidget);
      expect(find.text('All Defects (10)'), findsOneWidget);
      expect(find.text('Potholes Only (5)'), findsOneWidget);
    });

    testWidgets('6. MainNavigator switches tabs cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const RoadSenseApp());
      await tester.pump();

      // Starts at Home
      expect(find.text('Good morning, Abir'), findsOneWidget);

      // Tap Camera
      await tester.tap(find.text('Camera'));
      await tester.pump();
      expect(find.text('Live Road Camera'), findsOneWidget);

      // Tap Tasks
      await tester.tap(find.text('Tasks'));
      await tester.pump();
      expect(find.text('Repair Tasks'), findsOneWidget);

      // Tap Map
      await tester.tap(find.text('Map'));
      await tester.pump();
      expect(find.text('Defect GIS & Road Map'), findsOneWidget);
    });

    testWidgets(
        '7. Inspector Profile photo can be changed and updated across AppState',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pump();

      // Open Change Photo Modal
      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Change Inspector Photo'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.text('Presets'), findsOneWidget);
      expect(find.text('Web URL'), findsOneWidget);
      expect(find.text('Monogram'), findsOneWidget);
      expect(find.text('Choose Any Picture from Your Computer'), findsOneWidget);
      expect(find.text('Browse Computer Files'), findsOneWidget);

      // Tap Presets tab
      await tester.tap(find.text('Presets'));
      await tester.pumpAndSettle();

      // Select preset
      expect(find.text('Marcus Vance'), findsOneWidget);
      await tester.tap(find.text('Marcus Vance'));
      await tester.pump();

      // State is updated
      expect(AppState.instance.hasCustomAvatar, isTrue);

      // Test custom photo bytes from user upload
      AppState.instance.setInspectorAvatarBytes(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]));
      await tester.pump();
      expect(AppState.instance.customAvatarBytes, isNotNull);

      // Reset to default
      await tester.tap(find.text('Reset to Default'));
      await tester.pumpAndSettle();
      expect(AppState.instance.hasCustomAvatar, isFalse);
      expect(AppState.instance.customAvatarBytes, isNull);
    });

    testWidgets(
        '8. Dynamic recalculation: reporting, resolving defects and completing tasks dynamically update Road Health, Potholes, and Urgent Fixes',
        (WidgetTester tester) async {
      final state = AppState.instance;

      // Baseline reset
      state.updateTelemetry(
        roadsCheckedKm: 142.0,
        roadHealthPct: 78,
        potholesFound: 14,
        urgentFixes: 3,
      );

      expect(state.roadHealthPct, 78);
      expect(state.potholesFound, 14);
      expect(state.urgentFixes, 3);

      // 1. Report a new urgent pothole defect
      state.reportIssue(
        const RoadIssue(
          id: 'test-defect-01',
          title: 'Test Maple St Pothole',
          severity: 'Urgent',
          dimensionDetail: '9cm deep',
          location: 'Maple St & 5th Ave',
          coordinates: '42.3601° N, 71.0589° W',
          timestamp: 'Just now',
          isPothole: true,
        ),
      );

      // Potholes & Urgent incremented, Road health decremented
      expect(state.potholesFound, 15);
      expect(state.urgentFixes, 4);
      expect(state.roadHealthPct, 75); // 78 - 3

      // 2. Resolve the defect
      state.resolveIssue('test-defect-01');

      // Potholes & Urgent decremented, Road health increased
      expect(state.potholesFound, 14);
      expect(state.urgentFixes, 3);
      expect(state.roadHealthPct, 78); // 75 + 3

      // 3. Complete a repair task
      final initialDoneCount = state.doneTasks.length;
      final initialToDoCount = state.toDoTasks.length;
      final firstToDo = state.toDoTasks.first;

      state.toggleTaskDone(firstToDo.id);

      expect(state.toDoTasks.length, initialToDoCount - 1);
      expect(state.doneTasks.length, initialDoneCount + 1);
      expect(state.roadHealthPct, 81); // 78 + 3
      expect(state.urgentFixes, 2); // 3 - 1
      expect(state.potholesFound, 13); // 14 - 1
    });

    testWidgets(
        '9. Home Screen allows manual metric editing via Edit Metrics modal and instantly updates UI',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.updateTelemetry(
        roadsCheckedKm: 142.0,
        roadHealthPct: 78,
        potholesFound: 14,
        urgentFixes: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // Verify initial cards
      expect(find.text('142 km'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Open Edit Metrics Modal via "Edit Metrics" button
      expect(find.text('Edit Metrics'), findsOneWidget);
      await tester.tap(find.text('Edit Metrics'));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text("Edit Today's Road Metrics"), findsOneWidget);
      expect(find.text('Road Health (%)'), findsOneWidget);
      expect(find.text('Quick Simulation Actions'), findsOneWidget);
      expect(find.text('Fix A Defect'), findsOneWidget);
      expect(find.text('New Defect'), findsOneWidget);
      expect(find.text('Save & Apply Metrics'), findsOneWidget);

      // Simulate fixing a defect right from the modal
      await tester.tap(find.text('Fix A Defect'));
      await tester.pump();

      // State is updated dynamically
      expect(state.roadHealthPct, greaterThan(78));

      // Close modal by saving
      await tester.tap(find.text('Save & Apply Metrics'));
      await tester.pumpAndSettle();

      // Home Screen now reflects the new health percentage
      expect(find.text('${state.roadHealthPct}%'), findsOneWidget);
    });

    testWidgets(
        '10. Home screen dynamically decrements Recent Issues (2 -> 1 -> 0 / All Clear) when resolved',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.resetDefaultIssues();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // Starts with 2 issues
      expect(find.text('Airport Road Pothole'), findsOneWidget);
      expect(find.text('Sailar Mor Asphalt Crack'), findsOneWidget);
      expect(find.text('See All (23)'), findsOneWidget);

      // Resolve first issue ('issue-1')
      state.resolveIssue('issue-1');
      await tester.pump();

      // Now only 1 issue remains on Home screen! (Sailar Mor Asphalt Crack)
      expect(find.text('Airport Road Pothole'), findsNothing);
      expect(find.text('Sailar Mor Asphalt Crack'), findsOneWidget);
      expect(find.text('1 resolved'), findsOneWidget);
      expect(find.text('See All (22)'), findsOneWidget);

      // Resolve second issue ('issue-2')
      state.resolveIssue('issue-2');
      await tester.pump();

      // Now 0 issues remain on Home screen -> All Clear green banner!
      expect(find.text('Airport Road Pothole'), findsNothing);
      expect(find.text('Sailar Mor Asphalt Crack'), findsNothing);
      expect(find.text('All Clear! No Active Hazards'), findsOneWidget);
      expect(find.text('2 resolved'), findsOneWidget);
      expect(find.text('See All (21)'), findsOneWidget);

      // Reporting a new issue adds it back to active shift issues
      state.reportIssue(
        const RoadIssue(
          id: 'new-issue-99',
          title: 'Cantt Bazar Crossing Void',
          severity: 'Urgent',
          dimensionDetail: '10cm deep',
          location: 'Cantt Bazar Crossing',
          coordinates: '25.78° N, 88.90° E',
          timestamp: 'Just now',
          isPothole: true,
        ),
      );
      await tester.pump();

      // Newly reported issue is now active on Home
      expect(find.text('Cantt Bazar Crossing Void'), findsOneWidget);
      expect(find.text('All Clear! No Active Hazards'), findsNothing);
    });

    testWidgets(
        '11. Urgent counts match perfectly between Home Screen summary (3) and Recent Issues modal sheet filter chip (3)',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.resetDefaultIssues();

      expect(state.urgentFixes, 3);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // Home Screen summary card shows 3 for Urgent Fixes
      expect(find.text('Urgent Fixes'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Open "See All (23)" bottom sheet
      await tester.tap(find.text('See All (23)'));
      await tester.pumpAndSettle();

      // In the modal sheet, filter chip must show "Urgent (3)"
      expect(find.text('Urgent (3)'), findsOneWidget);

      // Tap on "Urgent (3)" filter chip
      await tester.tap(find.text('Urgent (3)'));
      await tester.pumpAndSettle();

      // The 3 urgent items are visible in the filtered list
      expect(find.text('Airport Road Pothole'), findsWidgets);
      expect(find.text('Cantt Bazar Road Pothole'), findsOneWidget);
      expect(find.text('BAUST Gate Culvert Void'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // When an urgent issue is resolved
      state.resolveIssue('issue-1');
      await tester.pump();

      // Home Screen now shows 2
      expect(state.urgentFixes, 2);
      expect(find.text('2'), findsWidgets);

      // Open "See All (22)" again
      await tester.tap(find.text('See All (22)'));
      await tester.pumpAndSettle();

      // Now "Urgent (2)" is shown in the sheet
      expect(find.text('Urgent (2)'), findsOneWidget);
    });

    testWidgets(
        '12. New task added appears 1st in Home screen Recent Issues and budget is in Taka (৳)',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.resetDefaultIssues();

      // Initially, first active issue is Airport Road Pothole
      expect(state.activeShiftIssues.first.title, 'Airport Road Pothole');

      // Add a new repair task
      state.addRepairTask(
        'Terminal Bypass Rutting Fix',
        'Terminal Bypass Highway',
        'URGENT',
        notes: 'Deep rutting • Minimal cost: ৳3,200',
      );

      // It must be at index 0 (1st item) in both activeShiftIssues and recentIssues
      expect(state.activeShiftIssues.first.title, 'Terminal Bypass Rutting Fix');
      expect(state.recentIssues.first.title, 'Terminal Bypass Rutting Fix');

      // Pump Home Screen
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pump();

      // Newly added task is displayed 1st on Home screen Recent Issues
      expect(find.text('Terminal Bypass Rutting Fix'), findsOneWidget);
      expect(find.text('Location: Terminal Bypass Highway'), findsNothing); // format on card
      expect(find.text('See All (24)'), findsOneWidget);

      // Reset budget telemetry to baseline and pump Repair Tasks Screen
      state.updateBudget(spent: 42500, total: 60000, crews: 7);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RepairTasksScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('৳42,500'), findsOneWidget);
      expect(find.text('spent of ৳60,000'), findsOneWidget);
      // Dollar signs should not appear in the budget card
      expect(find.text('\$42,500'), findsNothing);
      expect(find.text('spent of \$60,000'), findsNothing);
    });

    testWidgets(
        '13. Camera Screen toggles feed/detection, predicts minimal cost in ৳, and Map shows defect breakdown',
        (WidgetTester tester) async {
      final state = AppState.instance;
      state.toggleCameraFeed(true);
      state.toggleAiDetection(true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CameraScreen(),
        ),
      );
      await tester.pump();

      // Camera control bar
      expect(find.text('Camera Feed'), findsOneWidget);
      expect(find.text('AI Detection'), findsOneWidget);
      expect(find.text('Access Device Camera'), findsOneWidget);

      // AI Damage & Minimal Cost Prediction Card
      expect(find.text('AI Damage & Cost Prediction'), findsOneWidget);
      expect(find.text('৳2,800'), findsWidgets); // minimal fix cost
      expect(find.text('৳5,500'), findsWidgets); // permanent fix cost

      // Turn camera feed OFF
      state.toggleCameraFeed(false);
      await tester.pump();
      expect(find.text('Camera Feed Paused'), findsOneWidget);

      // Turn camera feed back ON
      state.toggleCameraFeed(true);
      await tester.pump();
      expect(find.text('AI Scanning Road'), findsOneWidget);

      // Test Map Screen defect breakdown
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MapScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Defect GIS & Road Map'), findsOneWidget);
    });
  });
}
