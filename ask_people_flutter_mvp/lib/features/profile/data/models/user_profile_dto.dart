import 'package:ask_people/core/constants/app_categories.dart';
import 'package:ask_people/features/profile/domain/entities/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.email,
    required this.displayName,
    required this.interests,
    required this.createdAt,
  });

  factory UserProfileDto.fromDomain(UserProfile profile) {
    return UserProfileDto(
      id: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      interests: profile.interests.map((interest) => interest.id).toList(),
      createdAt: profile.createdAt,
    );
  }

  factory UserProfileDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    final interestIds = List<String>.from(data['interests'] as List? ?? []);

    return UserProfileDto(
      id: snapshot.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String? ?? '',
      interests: interestIds,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String? email;
  final String displayName;
  final List<String> interests;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile toDomain() {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      interests: interests
          .map(
            (id) => AppCategory.values.firstWhere(
              (category) => category.id == id,
              orElse: () => AppCategory.other,
            ),
          )
          .toList(),
      createdAt: createdAt,
    );
  }
}
