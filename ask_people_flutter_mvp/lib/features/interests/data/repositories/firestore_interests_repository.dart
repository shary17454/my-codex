import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/interests/domain/repositories/interests_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInterestsRepository implements InterestsRepository {
  const FirestoreInterestsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveInterests({
    required String userId,
    required List<AppCategory> interests,
  }) {
    return _firestore.collection('users').doc(userId).set(
      {
        'interests': interests.map((interest) => interest.id).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<List<AppCategory>> getUserInterests(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    final data = snapshot.data();
    final interestIds = List<String>.from(data?['interests'] as List? ?? []);

    return interestIds
        .map(
          (id) => AppCategory.values.firstWhere(
            (category) => category.id == id,
            orElse: () => AppCategory.other,
          ),
        )
        .toList();
  }
}
