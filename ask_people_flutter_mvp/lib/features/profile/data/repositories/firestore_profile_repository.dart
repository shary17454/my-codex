import 'package:ask_people/features/profile/data/models/user_profile_dto.dart';
import 'package:ask_people/features/profile/domain/entities/user_profile.dart';
import 'package:ask_people/features/profile/domain/repositories/profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProfileRepository implements ProfileRepository {
  const FirestoreProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _users.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return UserProfileDto.fromFirestore(snapshot).toDomain();
    });
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final snapshot = await _users.doc(userId).get();
    if (!snapshot.exists) {
      return null;
    }

    return UserProfileDto.fromFirestore(snapshot).toDomain();
  }

  @override
  Future<void> createProfile(UserProfile profile) {
    final dto = UserProfileDto.fromDomain(profile);
    return _users.doc(profile.id).set(dto.toFirestore(), SetOptions(merge: true));
  }
}
