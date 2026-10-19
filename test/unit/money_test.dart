import 'package:flutter_test/flutter_test.dart';
import 'package:tour_board/core/money/currency.dart';
import 'package:tour_board/core/money/money.dart';

void main() {
  const bdt = Currency('BDT', 2);
  const jpy = Currency('JPY', 0);
  const kwd = Currency('KWD', 3);

  group('parseAmount', () {
    test('parses whole and fractional values into minor units', () {
      expect(parseAmount('1250', bdt).minor, 125000);
      expect(parseAmount('1250.5', bdt).minor, 125050);
      expect(parseAmount('1,250.05', bdt).minor, 125005);
      expect(parseAmount('.5', bdt).minor, 50);
      expect(parseAmount('0.01', bdt).minor, 1);
      expect(parseAmount(' 12 ', bdt).minor, 1200);
    });

    test('respects currency exponent', () {
      expect(parseAmount('1500', jpy).minor, 1500);
      expect(parseAmount('1.5', jpy).error, AmountParseError.tooManyDecimals);
      expect(parseAmount('1.234', kwd).minor, 1234);
      expect(
        parseAmount('1.2345', kwd).error,
        AmountParseError.tooManyDecimals,
      );
    });

    test('handles locale separators', () {
      final r = parseAmount(
        '1.250,75',
        bdt,
        decimalSeparator: ',',
        groupSeparator: '.',
      );
      expect(r.minor, 125075);
    });

    test('rejects invalid, zero, negative and huge input', () {
      expect(parseAmount('', bdt).error, AmountParseError.empty);
      expect(parseAmount('abc', bdt).error, AmountParseError.invalid);
      expect(parseAmount('-5', bdt).error, AmountParseError.invalid);
      expect(parseAmount('1.2.3', bdt).error, AmountParseError.invalid);
      expect(parseAmount('.', bdt).error, AmountParseError.invalid);
      expect(parseAmount('0', bdt).error, AmountParseError.notPositive);
      expect(parseAmount('0.00', bdt).error, AmountParseError.notPositive);
      expect(parseAmount('0', bdt, allowZero: true).minor, 0);
      expect(
        parseAmount('99999999999999999999', bdt).error,
        AmountParseError.tooLarge,
      );
      expect(parseAmount('10000000000', bdt).error, AmountParseError.tooLarge);
      expect(parseAmount('9999999999.99', bdt).minor, maxAmountMinor);
    });

    test('leading zeros do not change value', () {
      expect(parseAmount('000012.30', bdt).minor, 1230);
    });
  });

  group('minorToPlainString', () {
    test('round-trips with parseAmount', () {
      for (final value in [1, 9, 10, 99, 100, 12345, 100000, maxAmountMinor]) {
        final text = minorToPlainString(value, bdt);
        expect(parseAmount(text, bdt).minor, value, reason: text);
      }
      expect(minorToPlainString(5, bdt), '0.05');
      expect(minorToPlainString(1500, jpy), '1500');
      expect(minorToPlainString(-250, bdt), '-2.50');
    });
  });

  group('formatMoney', () {
    test('uses currency digits without hardcoded symbols in logic', () {
      expect(formatMoney(125050, 'USD', locale: 'en_US'), r'$1,250.50');
      expect(formatMoney(1500, 'JPY', locale: 'en_US'), contains('1,500'));
      expect(formatMoney(1500, 'JPY', locale: 'en_US'), isNot(contains('.')));
      expect(
        formatMoney(maxAmountMinor, 'USD', locale: 'en_US'),
        r'$9,999,999,999.99',
      );
    });
  });

  group('currency metadata', () {
    test('lookup is case-insensitive and rejects unknown codes', () {
      expect(currencyForCode('bdt')?.minorDigits, 2);
      expect(currencyForCode('XYZ'), isNull);
      expect(isSupportedCurrency('JPY'), isTrue);
      expect(currencyOrDefault('XYZ').minorDigits, 2);
      expect(const Currency('KWD', 3).minorPerMajor, 1000);
    });
  });
}
