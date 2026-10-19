/// ISO 4217 currency metadata used for minor-unit arithmetic.
///
/// Only the number of minor digits matters for calculations; symbols come
/// from the locale at display time so no symbol is hardcoded in logic.
class Currency {
  const Currency(this.code, this.minorDigits);

  final String code;

  /// Number of decimal digits in the minor unit (2 for BDT/USD, 0 for JPY).
  final int minorDigits;

  /// 10^minorDigits, i.e. how many minor units make one major unit.
  int get minorPerMajor {
    var result = 1;
    for (var i = 0; i < minorDigits; i++) {
      result *= 10;
    }
    return result;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

/// Supported currencies. Keep this list in sync with `supportedCurrencies()`
/// in firestore.rules.
const List<Currency> supportedCurrencies = [
  Currency('AED', 2),
  Currency('AUD', 2),
  Currency('BDT', 2),
  Currency('BHD', 3),
  Currency('BTN', 2),
  Currency('CAD', 2),
  Currency('CHF', 2),
  Currency('CNY', 2),
  Currency('EUR', 2),
  Currency('GBP', 2),
  Currency('HKD', 2),
  Currency('IDR', 2),
  Currency('INR', 2),
  Currency('JPY', 0),
  Currency('KRW', 0),
  Currency('KWD', 3),
  Currency('LKR', 2),
  Currency('MVR', 2),
  Currency('MYR', 2),
  Currency('NPR', 2),
  Currency('NZD', 2),
  Currency('OMR', 3),
  Currency('PHP', 2),
  Currency('PKR', 2),
  Currency('QAR', 2),
  Currency('SAR', 2),
  Currency('SGD', 2),
  Currency('THB', 2),
  Currency('TRY', 2),
  Currency('USD', 2),
  Currency('VND', 0),
  Currency('ZAR', 2),
];

final Map<String, Currency> _byCode = {
  for (final c in supportedCurrencies) c.code: c,
};

/// Returns metadata for [code], or null when the code is not supported.
Currency? currencyForCode(String? code) =>
    code == null ? null : _byCode[code.toUpperCase()];

bool isSupportedCurrency(String? code) => currencyForCode(code) != null;

/// Like [currencyForCode] but falls back to 2 minor digits so that display
/// never crashes on an unexpected value coming from storage.
Currency currencyOrDefault(String code) =>
    currencyForCode(code) ?? Currency(code.toUpperCase(), 2);
