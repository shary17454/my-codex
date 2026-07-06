import 'package:flutter_test/flutter_test.dart';
import 'package:price_detector/features/ocr/data/services/ocr_text_parser.dart';

void main() {
  test('extracts a product name and the highest detected price', () {
    const parser = OcrTextParser();

    final result = parser.parse('Coffee Beans\nOld 42.00\nNow 35.50');

    expect(result.productName, 'Coffee Beans');
    expect(result.price, 42);
  });

  test('returns null values for empty OCR text', () {
    const parser = OcrTextParser();

    final result = parser.parse('');

    expect(result.productName, isNull);
    expect(result.price, isNull);
  });

  test('supports comma decimal prices', () {
    const parser = OcrTextParser();

    final result = parser.parse('Milk\n6,75 SAR');

    expect(result.productName, 'Milk');
    expect(result.price, 6.75);
  });
}
