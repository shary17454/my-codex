import 'package:equatable/equatable.dart';

class AppFailure extends Equatable {
  const AppFailure({
    required this.message,
    this.code,
    this.cause,
  });

  final String message;
  final String? code;
  final Object? cause;

  @override
  List<Object?> get props => [message, code, cause];
}
