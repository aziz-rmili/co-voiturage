import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;
  NotificationRepositoryImpl({required NotificationRemoteDataSource remote})
    : _remote = remote;

  @override
  Stream<List<AppNotification>> getNotifications(String userId) =>
      _remote.getNotifications(userId);

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _remote.markAsRead(notificationId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _remote.markAllAsRead(userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Stream<int> getUnreadCount(String userId) => _remote.getUnreadCount(userId);
}
