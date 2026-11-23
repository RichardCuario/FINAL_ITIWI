import 'package:flutter/material.dart';

/// Shared by certificate appointments and facility borrowing requests.
/// Keep admin workflow states distinct instead of treating them as pending.
({String label, Color color}) onlineServiceStatus(String? status) {
  switch (status?.trim().toLowerCase() ?? '') {
    case 'approved':
      return (label: 'Approved', color: const Color(0xFF16A34A));
    case 'confirmed':
      return (label: 'Confirmed', color: const Color(0xFF16A34A));
    case 'completed':
      return (label: 'Completed', color: const Color(0xFF16A34A));
    case 'processing':
      return (label: 'Ready for Release', color: const Color(0xFFB45309));
    case 'rejected':
      return (label: 'Rejected', color: const Color(0xFFDC2626));
    case 'cancelled':
    case 'canceled':
      return (label: 'Cancelled', color: const Color(0xFF64748B));
    case '':
    case 'pending':
      return (label: 'Pending', color: const Color(0xFF1E88E5));
    default:
      return (label: 'Unknown', color: const Color(0xFF64748B));
  }
}
