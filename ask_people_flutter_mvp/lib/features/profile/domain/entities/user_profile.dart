import 'package:ask_people/core/constants/app_categories.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.interests,
    required this.createdAt,
  });

  final String id;
  final String? email;
  final String displayName;
  final List<AppCategory> interests;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, email, displayName, interests, createdAt];
}
