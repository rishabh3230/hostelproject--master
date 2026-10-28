import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hms/models/student_record.dart';
import 'package:hms/models/room_input.dart';
import 'package:hms/screens/students_screen.dart';
import 'package:hms/screens/rooms_screen.dart';

void main() {
  test('Missing or malformed fee values remain unknown, never zero', () {
    for (final value in [null, '50000', double.nan, -1, 1.5]) {
      final record = StudentRecord('u', {
        'authUid': 'u',
        'feeTotal': value,
        'manualPaid': 0,
        'onlinePaid': 0,
      });
      expect(record.hasFees, false);
      expect(record.paid, isNull);
      expect(record.canManage, false);
    }
    expect(
      StudentRecord('u', {
        'authUid': 'u',
        'feeTotal': 50000,
        'manualPaid': 10000,
        'onlinePaid': 5000,
      }).paid,
      15000,
    );
  });
  testWidgets('Legacy student card renders without numeric casts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentCard(
              uid: 'STU001',
              data: {
                'name': 'Test Student',
                'rollNo': 'STU001',
                'hostelBlock': 'Old block',
                'roomAllotted': '101',
                'phone': '9999999999',
                'feeStatus': 'Paid',
              },
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Test Student • STU001'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Fee: Not recorded'), findsOneWidget);
    expect(find.textContaining('Old block / 101'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Edit fees'))
          .onPressed,
      isNull,
    );
  });
  test('Room validation and normalized IDs', () {
    expect(
      RoomInput(' Hostel 1 ', '301', '3').id,
      RoomInput('hostel 1', '301', '3').id,
    );
    expect(RoomInput('Hostel 1', '301', '3').error, isNull);
    for (final capacity in ['0', '21', '3.5', 'bad']) {
      expect(RoomInput('Hostel 1', '301', capacity).error, isNotNull);
    }
  });
  testWidgets('Room form displays validation inside the dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RoomDialog())),
    );
    await tester.tap(find.text('Save room'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a block name (up to 60 characters).'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
