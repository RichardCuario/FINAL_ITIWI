import 'package:flutter/material.dart';

/// Shared Material 3 styling for service dates, historical dates and times.
Widget _pickerTheme(BuildContext context, Widget? child) {
  final base = Theme.of(context);
  final dark = base.brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2563EB),
    brightness: base.brightness,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));
  return Theme(
    data: ThemeData.from(colorScheme: colors, useMaterial3: true).copyWith(
      textTheme: base.textTheme,
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        headerBackgroundColor: colors.primaryContainer,
        headerForegroundColor: colors.onPrimaryContainer,
        headerHeadlineStyle: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
        todayBorder: BorderSide(color: colors.primary, width: 1.5),
        dividerColor: colors.outlineVariant,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.surface,
        shape: shape,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        hourMinuteColor: colors.primaryContainer,
        hourMinuteTextColor: colors.onPrimaryContainer,
        dialBackgroundColor: colors.surfaceContainerHighest,
        dialHandColor: colors.primary,
        entryModeIconColor: colors.primary,
        helpTextStyle: TextStyle(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? colors.surfaceContainerHigh
            : colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(72, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

Future<DateTime?> showServiceDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  SelectableDayPredicate? selectableDayPredicate,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  helpText: helpText ?? 'Choose a date',
  confirmText: 'Confirm date',
  cancelText: 'Cancel',
  selectableDayPredicate: selectableDayPredicate,
  builder: _pickerTheme,
);

Future<TimeOfDay?> showServiceTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  initialEntryMode: TimePickerEntryMode.input,
  helpText: 'Choose a time',
  confirmText: 'Confirm time',
  cancelText: 'Cancel',
  builder: _pickerTheme,
);
