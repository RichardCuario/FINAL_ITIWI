import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/online_service_status.dart';

void main() {
  test(
    'admin workflow states keep their labels instead of becoming pending',
    () {
      const labels = {
        'pending': 'Pending',
        'processing': 'Ready for Release',
        'completed': 'Completed',
        'rejected': 'Rejected',
        'approved': 'Approved',
        'confirmed': 'Confirmed',
        'cancelled': 'Cancelled',
        'canceled': 'Cancelled',
      };
      for (final entry in labels.entries) {
        expect(onlineServiceStatus(entry.key).label, entry.value);
        expect(
          onlineServiceStatus('  ${entry.key.toUpperCase()}  ').label,
          entry.value,
        );
      }
    },
  );

  test('completed and confirmed appointments have the approval color', () {
    for (final status in ['approved', 'confirmed', 'completed']) {
      expect(onlineServiceStatus(status).color, const Color(0xFF16A34A));
      expect(
        onlineServiceStatus(status).color,
        isNot(onlineServiceStatus('pending').color),
      );
    }
  });

  test('missing status defaults to pending but unknown states do not', () {
    expect(onlineServiceStatus(null).label, 'Pending');
    expect(onlineServiceStatus('  ').label, 'Pending');
    expect(onlineServiceStatus('unexpected-status').label, 'Unknown');
  });
}
