import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      return await _remoteDataSource.getCurrentUser();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.loginWithEmail(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.registerWithEmail(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    try {
      return await _remoteDataSource.loginWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _remoteDataSource.authStateChanges;
}
