import 'dart:convert';

import 'package:csv/csv.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/transaction.dart';

class CsvStatementParser {
  const CsvStatementParser();

  List<Transaction> parse(List<int> bytes) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final rows = csv.decode(content);

    if (rows.isEmpty) {
      return [];
    }

    final header = rows.first.map((cell) => cell.toString().toLowerCase()).toList();
    final dataRows = _looksLikeHeader(header) ? rows.skip(1) : rows;

    return dataRows
        .map((row) => _parseRow(row, header: _looksLikeHeader(header) ? header : null))
        .whereType<Transaction>()
        .toList();
  }

  bool _looksLikeHeader(List<String> header) {
    return header.any((cell) => cell.contains('date') || cell.contains('التاريخ')) ||
        header.any((cell) => cell.contains('amount') || cell.contains('المبلغ'));
  }

  Transaction? _parseRow(List<dynamic> row, {List<String>? header}) {
    if (row.length < 3) {
      return null;
    }

    final dateValue = _cell(row, header, ['date', 'transaction date', 'التاريخ'], 0);
    final merchant = _cell(row, header, ['merchant', 'description', 'details', 'الوصف'], 1);
    final amountValue = _cell(row, header, ['amount', 'debit', 'المبلغ'], 2);

    final date = _parseDate(dateValue);
    final amount = _parseAmount(amountValue);

    if (date == null || merchant.trim().isEmpty || amount == null) {
      return null;
    }

    return Transaction(
      id: '${date.millisecondsSinceEpoch}-${merchant.hashCode}-${amount.hashCode}',
      date: date,
      merchant: merchant.trim(),
      amount: amount.abs(),
      currency: _parseCurrency(row.join(' ')),
      description: merchant.trim(),
    );
  }

  String _cell(
    List<dynamic> row,
    List<String>? header,
    List<String> names,
    int fallbackIndex,
  ) {
    if (header != null) {
      final index = header.indexWhere(
        (cell) => names.any((name) => cell.contains(name)),
      );
      if (index >= 0 && index < row.length) {
        return row[index].toString();
      }
    }

    if (fallbackIndex < row.length) {
      return row[fallbackIndex].toString();
    }

    throw const AppException('CSV row does not contain required columns.');
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim();
    return DateTime.tryParse(normalized) ??
        _tryDateParts(normalized, '/') ??
        _tryDateParts(normalized, '-');
  }

  DateTime? _tryDateParts(String value, String separator) {
    final parts = value.split(separator);
    if (parts.length != 3) {
      return null;
    }

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);

    if (first == null || second == null || third == null) {
      return null;
    }

    if (parts[0].length == 4) {
      return DateTime(first, second, third);
    }

    return DateTime(third, second, first);
  }

  double? _parseAmount(String value) {
    final normalized = value.replaceAll(',', '').replaceAll(RegExp('[^0-9.-]'), '');
    return double.tryParse(normalized);
  }

  SupportedCurrency _parseCurrency(String value) {
    final upper = value.toUpperCase();
    if (upper.contains('USD') || value.contains(r'$')) {
      return SupportedCurrency.usd;
    }
    return SupportedCurrency.sar;
  }
}
