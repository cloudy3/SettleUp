import 'package:intl/intl.dart';

/// Formats [amount] using [currencyCode] (ISO 4217, e.g. USD, EUR).
String formatCurrencyAmount(double amount, String currencyCode) {
  final code = currencyCode.trim().toUpperCase();
  if (code.isEmpty) {
    return amount.toStringAsFixed(2);
  }
  try {
    return NumberFormat.simpleCurrency(name: code).format(amount);
  } catch (_) {
    return '$code ${amount.toStringAsFixed(2)}';
  }
}
