/// Thrown by the data layer when a Firebase / network call fails.
class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'Server error occurred.'});
  @override
  String toString() => 'ServerException: $message';
}

/// Thrown specifically for Firebase Auth errors (wrong password, etc.).
class AuthException implements Exception {
  final String message;
  const AuthException({this.message = 'Authentication failed.'});
  @override
  String toString() => 'AuthException: $message';
}

/// Thrown when a required cache entry is missing.
class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Cache miss.'});
  @override
  String toString() => 'CacheException: $message';
}
