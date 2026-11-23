import 'service_date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Nationwide regular and special nonworking days from Proclamations 1006
// (2026) and 1427 (2027), plus separately proclaimed 2026 Eid dates.
// Working holidays and local proclamations are excluded. Admins can add
// later proclamations and local closures in Online Services.
const _publishedHolidays = <String>{
  '2026-01-01', '2026-02-17', '2026-03-20', '2026-04-02',
  '2026-04-03', '2026-04-04', '2026-04-09', '2026-05-01',
  '2026-05-27', '2026-06-12', '2026-08-21', '2026-08-31',
  '2026-11-01', '2026-11-02', '2026-11-30', '2026-12-08',
  '2026-12-24', '2026-12-25', '2026-12-30', '2026-12-31',
  '2027-01-01', '2027-02-06', '2027-03-25', '2027-03-26',
  '2027-03-27', '2027-04-09', '2027-05-01', '2027-06-12',
  '2027-08-21', '2027-08-30', '2027-11-01', '2027-11-02',
  '2027-11-30', '2027-12-08', '2027-12-24', '2027-12-25',
  '2027-12-30', '2027-12-31',
};

String appointmentDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime(year, month, day);
}

bool isPhilippineNationalHoliday(DateTime date) {
  if (_publishedHolidays.contains(appointmentDateKey(date))) return true;

  // Recurring nationwide dates and Holy Week protect future calendar years
  // until each year's proclamation is available.
  final fixed = <String>{
    '01-01', '04-09', '05-01', '06-12', '08-21', '11-01',
    '11-30', '12-08', '12-25', '12-30', '12-31',
  };
  final monthDay = appointmentDateKey(date).substring(5);
  if (fixed.contains(monthDay)) return true;
  if (date.month == 8 && date.weekday == DateTime.monday && date.day + 7 > 31) {
    return true; // National Heroes Day: last Monday of August.
  }
  final easter = _easterSunday(date.year);
  final difference = DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(easter.year, easter.month, easter.day))
      .inDays;
  return difference == -3 || difference == -2 || difference == -1;
}

bool isAppointmentDayAvailable(DateTime date, Set<String> adminClosedDates) {
  return date.weekday <= DateTime.thursday &&
      !isPhilippineNationalHoliday(date) &&
      !adminClosedDates.contains(appointmentDateKey(date));
}

Future<Set<String>> loadAdminClosedAppointmentDates() async {
  final rows = await Supabase.instance.client
      .from('appointment_unavailable_dates')
      .select('date');
  return (rows as List)
      .map((row) => row['date']?.toString() ?? '')
      .where((date) => date.isNotEmpty)
      .toSet();
}

Future<DateTime?> pickAvailableAppointmentDate(
  BuildContext context,
  DateTime? selectedDate,
) async {
  final adminClosedDates = await loadAdminClosedAppointmentDates();
  if (!context.mounted) return null;

  final now = DateTime.now();
  final firstDate = DateTime(now.year, now.month, now.day + 1);
  final lastDate = DateTime(now.year + 2);
  var initialDate = selectedDate ?? firstDate;
  if (initialDate.isBefore(firstDate) ||
      initialDate.isAfter(lastDate) ||
      !isAppointmentDayAvailable(initialDate, adminClosedDates)) {
    initialDate = firstDate;
    while (!initialDate.isAfter(lastDate) &&
        !isAppointmentDayAvailable(initialDate, adminClosedDates)) {
      initialDate = initialDate.add(const Duration(days: 1));
    }
  }
  if (initialDate.isAfter(lastDate)) return null;

  return showServiceDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: 'Choose a date (Monday–Thursday)',
    selectableDayPredicate: (date) =>
        isAppointmentDayAvailable(date, adminClosedDates),
  );
}

Future<bool> confirmAppointmentDateAvailable(DateTime date) async {
  final adminClosedDates = await loadAdminClosedAppointmentDates();
  return isAppointmentDayAvailable(date, adminClosedDates);
}
