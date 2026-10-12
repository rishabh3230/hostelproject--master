import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hms/screens/login_selection_screen.dart';

void main() {
  testWidgets('LoginSelectionScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginSelectionScreen(),
      ),
    );

    // Verify system title shows up
    expect(find.text('IERT Hostel'), findsOneWidget);
    expect(find.text('Hostel Management System'), findsOneWidget);

    // Verify action buttons are present
    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('Student Login'), findsOneWidget);
    expect(find.text('Seed Firebase Test Data'), findsOneWidget);
  });
}
