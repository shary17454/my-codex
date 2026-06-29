import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mlkit_ocr_repository.dart';
import '../../domain/repositories/ocr_repository.dart';

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  final repository = MlKitOcrRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
