import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hms/screens/auth_screen.dart';
import 'package:hms/screens/students_screen.dart';

void main() {
  testWidgets('Login validates empty fields without contacting Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    expect(find.text('Roll number'), findsOneWidget);
    expect(find.text('Seed Firebase Test Data'), findsNothing);
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(2));
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Admin email'), findsOneWidget);
  });
  test('Rupee parser preserves paise and rejects malformed values', () {
    expect(parsePaise('123.45'), 12345);
    expect(parsePaise('0.01'), 1);
    expect(parsePaise('10.999'), isNull);
    expect(parsePaise('-1'), isNull);
    expect(parsePaise('NaN'), isNull);
  });
}
