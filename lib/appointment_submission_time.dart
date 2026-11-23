import 'dart:async';

import 'package:flutter/material.dart';

DateTime? parseAppointmentSubmissionTime(String? value) {
  if (value == null || !RegExp(r'[T\s]\d{2}:\d{2}:\d{2}').hasMatch(value)) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc();
}

String formatAppointmentSubmittedAt(String? value) {
  final submittedAt = parseAppointmentSubmissionTime(value);
  if (submittedAt == null) return 'Not recorded';
  final pht = submittedAt.add(const Duration(hours: 8));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int number) => number.toString().padLeft(2, '0');
  return '${months[pht.month - 1]} ${pht.day}, ${pht.year} | '
      '${two(pht.hour)}:${two(pht.minute)}:${two(pht.second)} PHT';
}

String formatAppointmentTimeSinceSubmission(String? value, {DateTime? now}) {
  final submittedAt = parseAppointmentSubmissionTime(value);
  if (submittedAt == null) return 'Not recorded';
  final elapsed = (now ?? DateTime.now()).toUtc().difference(submittedAt);
  var seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
  final days = seconds ~/ 86400;
  seconds %= 86400;
  final hours = seconds ~/ 3600;
  seconds %= 3600;
  final minutes = seconds ~/ 60;
  seconds %= 60;
  String two(int number) => number.toString().padLeft(2, '0');
  return '${days > 0 ? '${days}d ' : ''}'
      '${two(hours)}h ${two(minutes)}m ${two(seconds)}s';
}

class AppointmentSubmissionTime extends StatefulWidget {
  const AppointmentSubmissionTime({
    super.key,
    required this.submittedAt,
    required this.isDark,
  });

  final String? submittedAt;
  final bool isDark;

  @override
  State<AppointmentSubmissionTime> createState() =>
      _AppointmentSubmissionTimeState();
}

class _AppointmentSubmissionTimeState extends State<AppointmentSubmissionTime> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (parseAppointmentSubmissionTime(widget.submittedAt) != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppointmentSubmissionTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.submittedAt == widget.submittedAt) return;
    _timer?.cancel();
    _timer = null;
    if (parseAppointmentSubmissionTime(widget.submittedAt) != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = widget.isDark ? Colors.white60 : const Color(0xFF666D78);
    final valueColor = widget.isDark ? Colors.white : const Color(0xFF20242C);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF292D38)
            : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submitted', style: TextStyle(color: labelColor, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            formatAppointmentSubmittedAt(widget.submittedAt),
            style: TextStyle(
              color: valueColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time Since Submission',
            style: TextStyle(color: labelColor, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            formatAppointmentTimeSinceSubmission(widget.submittedAt),
            style: const TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
