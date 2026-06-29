import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_detector/app/config/app_config.dart';
import 'package:subscription_detector/features/transactions/data/parsers/csv_statement_parser.dart';

void main() {
  test('parses csv statement rows with header', () {
    const parser = CsvStatementParser();
    final bytes = utf8.encode(
      'date,merchant,amount,currency\n'
      '2026-01-05,Netflix,39.99,SAR\n'
      '2026-02-05,Spotify,19.99,USD\n',
    );

    final transactions = parser.parse(bytes);

    expect(transactions, hasLength(2));
    expect(transactions.first.merchant, 'Netflix');
    expect(transactions.first.amount, 39.99);
    expect(transactions.first.currency, SupportedCurrency.sar);
    expect(transactions.last.currency, SupportedCurrency.usd);
  });
}
