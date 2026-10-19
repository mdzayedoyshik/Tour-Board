import 'package:intl/intl.dart';

import 'currency.dart';

/// Largest amount accepted for a single record, in minor units.
///
/// Kept well below 2^53 so values survive any JSON/JS round trip and so that
/// display conversion to a double (see [formatMoney]) is exact. Mirrors
/// `maxAmountMinor()` in firestore.rules.
const int maxAmountMinor = 999999999999;

enum AmountParseError { empty, invalid, tooManyDecimals, notPositive, tooLarge }

class AmountParseResult {
  const AmountParseResult.ok(int this.minor) : error = null;
  const AmountParseResult.failed(AmountParseError this.error) : minor = null;

  final int? minor;
  final AmountParseError? error;

  bool get isValid => minor != null;
}

/// Parses user input such as "1,250.50" into integer minor units.
///
/// Works purely on the digit string — no double arithmetic — so "0.1 + 0.2"
/// style errors cannot occur. Accepts '.' and the locale decimal separator;
/// strips spaces and the locale grouping separator.
AmountParseResult parseAmount(
  String input,
  Currency currency, {
  String decimalSeparator = '.',
  String groupSeparator = ',',
  bool allowZero = false,
}) {
  var text = input.trim().replaceAll(RegExp(r'[\s  ]'), '');
  if (text.isEmpty) {
    return const AmountParseResult.failed(AmountParseError.empty);
  }

  // Normalise the decimal separator to '.' and drop grouping characters.
  if (groupSeparator != decimalSeparator && groupSeparator.isNotEmpty) {
    text = text.replaceAll(groupSeparator, '');
  }
  if (decimalSeparator != '.') {
    text = text.replaceAll(decimalSeparator, '.');
  }
  if (!RegExp(r'^\d*\.?\d*$').hasMatch(text) || text == '.') {
    return const AmountParseResult.failed(AmountParseError.invalid);
  }

  final parts = text.split('.');
  final wholePart = parts[0].isEmpty ? '0' : parts[0];
  final fractionPart = parts.length > 1 ? parts[1] : '';
  if (fractionPart.length > currency.minorDigits) {
    return const AmountParseResult.failed(AmountParseError.tooManyDecimals);
  }
  // Guard length before int.parse so huge inputs cannot overflow.
  final digits =
      wholePart.replaceFirst(RegExp(r'^0+(?=\d)'), '') +
      fractionPart.padRight(currency.minorDigits, '0');
  if (digits.length > maxAmountMinor.toString().length) {
    return const AmountParseResult.failed(AmountParseError.tooLarge);
  }
  final minor = int.parse(digits);
  if (minor > maxAmountMinor) {
    return const AmountParseResult.failed(AmountParseError.tooLarge);
  }
  if (minor == 0 && !allowZero) {
    return const AmountParseResult.failed(AmountParseError.notPositive);
  }
  return AmountParseResult.ok(minor);
}

/// Converts minor units to a plain editable string ("1250.50"), used to
/// pre-fill amount fields. Pure string arithmetic.
String minorToPlainString(int minor, Currency currency) {
  final negative = minor < 0;
  final abs = minor.abs().toString().padLeft(currency.minorDigits + 1, '0');
  if (currency.minorDigits == 0) return '${negative ? '-' : ''}$abs';
  final cut = abs.length - currency.minorDigits;
  return '${negative ? '-' : ''}${abs.substring(0, cut)}.${abs.substring(cut)}';
}

/// Formats minor units for display using locale conventions.
///
/// Division happens only here, for presentation; amounts are bounded by
/// [maxAmountMinor] so the double conversion is exact at the shown precision.
String formatMoney(int minor, String currencyCode, {String? locale}) {
  final currency = currencyOrDefault(currencyCode);
  final format = NumberFormat.currency(
    locale: locale,
    name: currency.code,
    symbol: _symbolFor(currency.code, locale),
    decimalDigits: currency.minorDigits,
  );
  return format.format(minor / currency.minorPerMajor);
}

/// Locale-aware separators for amount input fields.
({String decimal, String group}) numberSeparators(String? locale) {
  final symbols = NumberFormat.decimalPattern(locale).symbols;
  return (decimal: symbols.DECIMAL_SEP, group: symbols.GROUP_SEP);
}

String _symbolFor(String code, String? locale) {
  try {
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: code,
    ).currencySymbol;
  } catch (_) {
    return code;
  }
}
