import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/interests/domain/repositories/interests_repository.dart';

class GetUserInterestsUseCase {
  const GetUserInterestsUseCase(this._repository);

  final InterestsRepository _repository;

  Future<List<AppCategory>> call(String userId) {
    return _repository.getUserInterests(userId);
  }
}
