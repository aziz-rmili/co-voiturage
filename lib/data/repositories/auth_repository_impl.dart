import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/driver_credentials.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remote = remoteDataSource;

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      return await _remote.getCurrentUser();
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
      return await _remote.loginWithEmail(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<AppUser> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      return await _remote.registerPassenger(
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
  Future<AppUser> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      return await _remote.registerDriver(
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
  Future<void> submitDriverCredentials(DriverCredentials credentials) async {
    try {
      await _remote.submitDriverCredentials(credentials);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _remote.sendPasswordResetEmail(email: email);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<AppUser> loginWithGoogle() async {
    try {
      return await _remote.loginWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _remote.authStateChanges;
}
