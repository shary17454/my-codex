import 'package:ask_people/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Stream<UserProfile?> watchProfile(String userId);

  Future<UserProfile?> getProfile(String userId);

  Future<void> createProfile(UserProfile profile);
}
