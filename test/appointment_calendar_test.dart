import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/appointment_calendar.dart';

void main() {
  test('appointments are available only Monday through Thursday', () {
    const closed = <String>{};
    expect(isAppointmentDayAvailable(DateTime(2026, 10, 8), closed), isTrue);
    expect(isAppointmentDayAvailable(DateTime(2026, 10, 9), closed), isFalse);
    expect(isAppointmentDayAvailable(DateTime(2026, 10, 10), closed), isFalse);
    expect(isAppointmentDayAvailable(DateTime(2026, 10, 11), closed), isFalse);
  });

  test('published national holidays are unavailable but working holidays are not', () {
    const closed = <String>{};
    expect(isAppointmentDayAvailable(DateTime(2026, 12, 8), closed), isFalse);
    expect(isAppointmentDayAvailable(DateTime(2027, 3, 25), closed), isFalse);
    expect(isAppointmentDayAvailable(DateTime(2027, 2, 25), closed), isTrue);
  });

  test('admin closures and future Holy Week dates are unavailable', () {
    expect(
      isAppointmentDayAvailable(DateTime(2026, 10, 8), {'2026-10-08'}),
      isFalse,
    );
    expect(isPhilippineNationalHoliday(DateTime(2028, 4, 13)), isTrue);
  });
}
