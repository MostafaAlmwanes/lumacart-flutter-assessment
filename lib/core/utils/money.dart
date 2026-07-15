import 'package:intl/intl.dart';

abstract class Money {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );

  static int centsFromDouble(double value) {
    if (!value.isFinite || value <= 0) return 0;
    return (value * 100).round();
  }

  static String formatCents(int cents) => _formatter.format(cents / 100);

  static String formatDouble(double value) =>
      formatCents(centsFromDouble(value));
}
