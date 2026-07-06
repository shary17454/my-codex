import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  const LocalStorage(this._box);

  static const productReportsBox = 'product_reports';

  final Box<dynamic> _box;

  static Future<LocalStorage> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(productReportsBox);
    return LocalStorage(box);
  }

  Future<void> putMap(String key, Map<String, dynamic> value) {
    return _box.put(key, value);
  }

  Map<String, dynamic>? getMap(String key) {
    final value = _box.get(key);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
