import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Firebase / network server failures.
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Firebase Auth-specific failures (wrong password, email taken, etc.).
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Local cache failures.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Input validation failures (client-side, before any network call).
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
