import '../../domain/entities/ocr_result.dart';

class OcrTextParser {
  const OcrTextParser();

  OcrResult parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return OcrResult(
      rawText: rawText,
      productName: _extractProductName(lines),
      price: _extractPrice(rawText),
    );
  }

  String? _extractProductName(List<String> lines) {
    for (final line in lines) {
      final hasDigit = RegExp(r'\d').hasMatch(line);
      if (!hasDigit && line.length >= 3) {
        return line;
      }
    }

    return lines.isEmpty ? null : lines.first;
  }

  double? _extractPrice(String text) {
    final matches = RegExp(r'(\d+(?:[.,]\d{1,2})?)').allMatches(text);
    final values = matches
        .map((match) => match.group(1))
        .whereType<String>()
        .map((value) => double.tryParse(value.replaceAll(',', '.')))
        .whereType<double>()
        .where((value) => value > 0)
        .toList(growable: false);

    if (values.isEmpty) {
      return null;
    }

    values.sort();
    return values.last;
  }
}
