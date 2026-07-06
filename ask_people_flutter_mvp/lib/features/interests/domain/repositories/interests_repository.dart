import 'package:ask_people/core/constants/app_categories.dart';

abstract interface class InterestsRepository {
  Future<void> saveInterests({
    required String userId,
    required List<AppCategory> interests,
  });

  Future<List<AppCategory>> getUserInterests(String userId);
}
