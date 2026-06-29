import 'dart:convert';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../../app/config/app_config.dart';
import '../../domain/entities/transaction.dart';

class PdfStatementParser {
  const PdfStatementParser();

  List<Transaction> parse(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();

    return _parseExtractedText(text);
  }

  List<Transaction> _parseExtractedText(String text) {
    final lines = const LineSplitter().convert(text);
    final transactions = <Transaction>[];
    final pattern = RegExp(
      r'(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4})\s+(.+?)\s+(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)',
    );

    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match == null) {
        continue;
      }

      final date = _parseDate(match.group(1)!);
      final merchant = match.group(2)!.trim();
      final amount = double.tryParse(match.group(3)!.replaceAll(',', ''));

      if (date == null || merchant.isEmpty || amount == null) {
        continue;
      }

      transactions.add(
        Transaction(
          id: '${date.millisecondsSinceEpoch}-${merchant.hashCode}-${amount.hashCode}',
          date: date,
          merchant: merchant,
          amount: amount.abs(),
          currency: text.toUpperCase().contains('USD')
              ? SupportedCurrency.usd
              : SupportedCurrency.sar,
          description: line.trim(),
        ),
      );
    }

    return transactions;
  }

  DateTime? _parseDate(String value) {
    final normalized = value.replaceAll('/', '-');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return parsed;
    }

    final parts = normalized.split('-');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }
}
