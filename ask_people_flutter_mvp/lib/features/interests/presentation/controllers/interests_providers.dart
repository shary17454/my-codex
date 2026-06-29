import 'package:ask_people/app/di/providers.dart';
import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/auth/presentation/controllers/auth_providers.dart';
import 'package:ask_people/features/interests/data/repositories/firestore_interests_repository.dart';
import 'package:ask_people/features/interests/domain/repositories/interests_repository.dart';
import 'package:ask_people/features/interests/domain/usecases/save_interests_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final interestsRepositoryProvider = Provider<InterestsRepository>((ref) {
  return FirestoreInterestsRepository(ref.watch(firebaseFirestoreProvider));
});

final interestsControllerProvider =
    NotifierProvider<InterestsController, InterestsState>(
  InterestsController.new,
);

class InterestsState {
  const InterestsState({
    this.selected = const {},
    this.saveState = const AsyncData(null),
  });

  final Set<AppCategory> selected;
  final AsyncValue<void> saveState;

  InterestsState copyWith({
    Set<AppCategory>? selected,
    AsyncValue<void>? saveState,
  }) {
    return InterestsState(
      selected: selected ?? this.selected,
      saveState: saveState ?? this.saveState,
    );
  }
}

class InterestsController extends Notifier<InterestsState> {
  @override
  InterestsState build() {
    return const InterestsState();
  }

  void toggle(AppCategory interest) {
    final selected = <AppCategory>{...state.selected};
    if (selected.contains(interest)) {
      selected.remove(interest);
    } else {
      selected.add(interest);
    }

    state = state.copyWith(selected: selected);
  }

  Future<bool> save() async {
    final user = ref.read(authStateProvider).when(
          data: (user) => user,
          error: (error, stackTrace) => null,
          loading: () => null,
        );
    if (user == null || state.selected.isEmpty) {
      return false;
    }

    state = state.copyWith(saveState: const AsyncLoading());
    try {
      await SaveInterestsUseCase(ref.read(interestsRepositoryProvider))(
        userId: user.id,
        interests: state.selected.toList(),
      );

      state = state.copyWith(saveState: const AsyncData(null));
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(saveState: AsyncError(error, stackTrace));
      return false;
    }
  }
}
