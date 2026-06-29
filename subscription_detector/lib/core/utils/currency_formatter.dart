import 'package:intl/intl.dart';

import '../../app/config/app_config.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String format(
    num amount, {
    required SupportedCurrency currency,
    required String locale,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      name: currency.code,
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }
}
