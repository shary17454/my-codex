import 'package:ask_people/features/auth/domain/entities/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUserDto {
  const AppUserDto({
    required this.id,
    required this.email,
    this.displayName,
  });

  factory AppUserDto.fromFirebaseUser(User user) {
    return AppUserDto(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  final String id;
  final String? email;
  final String? displayName;

  AppUser toDomain() {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
    );
  }
}
