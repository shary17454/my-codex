import '../../../../core/storage/local_storage.dart';
import '../models/product_report_dto.dart';
import '../../domain/entities/product_report.dart';

class ProductReportLocalDataSource {
  const ProductReportLocalDataSource(this._storage);

  static const _latestReportKey = 'latest_product_report';

  final LocalStorage _storage;

  Future<void> saveLatest(ProductReport report) {
    return _storage.putMap(_latestReportKey, ProductReportDto.toMap(report));
  }

  Future<ProductReport?> getLatest() async {
    final map = _storage.getMap(_latestReportKey);
    return map == null ? null : ProductReportDto.fromMap(map);
  }
}
