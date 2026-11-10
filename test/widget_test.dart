import 'package:flutter_test/flutter_test.dart';
import 'package:road_sense/main.dart';
import 'package:road_sense/state/app_state.dart';

void main() {
  testWidgets('RoadSense app smoke test', (WidgetTester tester) async {
    AppState.instance.stopSpeedSimulation();
    await tester.pumpWidget(const RoadSenseApp());
    await tester.pump();
    expect(find.text('RoadSense'), findsWidgets);
    expect(find.text('Good morning, Abir'), findsOneWidget);
    expect(find.text('Start Road Scan'), findsOneWidget);
    expect(find.text('Today\'s Summary'), findsOneWidget);
  });
}
