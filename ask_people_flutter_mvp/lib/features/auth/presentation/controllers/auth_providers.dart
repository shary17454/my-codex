import 'package:ask_people/app/di/providers.dart';
import 'package:ask_people/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:ask_people/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:ask_people/features/auth/domain/entities/app_user.dart';
import 'package:ask_people/features/auth/domain/repositories/auth_repository.dart';
import 'package:ask_people/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:ask_people/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:ask_people/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:ask_people/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:ask_people/features/profile/data/repositories/firestore_profile_repository.dart';
import 'package:ask_people/features/profile/domain/entities/user_profile.dart';
import 'package:ask_people/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource(ref.watch(firebaseAuthProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthDataSourceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirestoreProfileRepository(ref.watch(firebaseFirestoreProvider));
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return WatchAuthStateUseCase(ref.watch(authRepositoryProvider))();
});

final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).when(
        data: (user) => user,
        error: (error, stackTrace) => null,
        loading: () => null,
      );
  if (user == null) {
    return const Stream.empty();
  }

  return ref.watch(profileRepositoryProvider).watchProfile(user.id);
});

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await SignInUseCase(ref.read(authRepositoryProvider))(
        email: email.trim(),
        password: password,
      );

      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await SignUpUseCase(ref.read(authRepositoryProvider))(
        displayName: displayName.trim(),
        email: email.trim(),
        password: password,
      );

      await ref.read(profileRepositoryProvider).createProfile(
        UserProfile(
          id: user.id,
          email: user.email,
          displayName: displayName.trim(),
          interests: const [],
          createdAt: DateTime.now(),
        ),
      );

      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> signOut() {
    return SignOutUseCase(ref.read(authRepositoryProvider))();
  }
}
