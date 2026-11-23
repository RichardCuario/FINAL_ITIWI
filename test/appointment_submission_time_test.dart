import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/appointment_submission_time.dart';

void main() {
  test('shows the exact Philippine submission time', () {
    expect(
      formatAppointmentSubmittedAt('2026-10-07T01:02:03Z'),
      'Oct 7, 2026 | 09:02:03 PHT',
    );
  });

  test('calculates elapsed days, hours, minutes, and seconds', () {
    expect(
      formatAppointmentTimeSinceSubmission(
        '2026-10-07T01:02:03Z',
        now: DateTime.utc(2026, 10, 8, 3, 5, 7),
      ),
      '1d 02h 03m 04s',
    );
  });

  test('does not claim an exact time for date-only values', () {
    expect(formatAppointmentSubmittedAt('2026-10-07'), 'Not recorded');
    expect(formatAppointmentTimeSinceSubmission(null), 'Not recorded');
  });
}
