import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = InMemoryAuthRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});
