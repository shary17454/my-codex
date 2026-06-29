import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/interests/domain/repositories/interests_repository.dart';

class SaveInterestsUseCase {
  const SaveInterestsUseCase(this._repository);

  final InterestsRepository _repository;

  Future<void> call({
    required String userId,
    required List<AppCategory> interests,
  }) {
    return _repository.saveInterests(userId: userId, interests: interests);
  }
}
