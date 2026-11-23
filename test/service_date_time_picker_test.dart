import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/service_date_time_picker.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('date selection retains restrictions in $brightness mode', (tester) async {
      DateTime? result;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(builder: (context) => Scaffold(body: TextButton(
          onPressed: () async { result = await showServiceDatePicker(
            context: context, initialDate: DateTime(2026, 10, 21),
            firstDate: DateTime(2026, 10, 1), lastDate: DateTime(2026, 10, 31),
            selectableDayPredicate: (date) => date.day != 22,
          ); }, child: const Text('Open'),
        ))),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('22'));
      await tester.tap(find.text('Confirm date'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 10, 21));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('time picker confirms a time and supports cancellation', (tester) async {
    TimeOfDay? result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () async { result = await showServiceTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 30)); },
      child: const Text('Open'),
    )))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsWidgets);
    await tester.tap(find.text('Confirm time'));
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 9, minute: 30));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
