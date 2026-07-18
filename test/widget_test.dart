import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_8/main.dart'; // Ensure this matches your project name

void main() {
  testWidgets('App should build successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WorkoutApp());

    // Basic test to ensure it loads without crashing
    expect(find.byType(WorkoutApp), findsOneWidget);
  });
}
