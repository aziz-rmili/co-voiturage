import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/repositories/notification_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationsEvent {
  final String userId;
  const NotificationsLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class NotificationMarkRead extends NotificationsEvent {
  final String notificationId;
  const NotificationMarkRead(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class NotificationsMarkAllRead extends NotificationsEvent {
  final String userId;
  const NotificationsMarkAllRead(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> recent;
  final List<AppNotification> earlier;
  final double co2SavedKg;

  const NotificationsLoaded({
    required this.recent,
    required this.earlier,
    required this.co2SavedKg,
  });

  @override
  List<Object?> get props => [recent, earlier, co2SavedKg];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _repo;

  NotificationsBloc({required NotificationRepository notificationRepository})
    : _repo = notificationRepository,
      super(NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationsMarkAllRead>(_onMarkAll);
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    await emit.forEach(
      _repo.getNotifications(event.userId),
      onData: (notifications) {
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        final recent = notifications
            .where((n) => n.timestamp.isAfter(cutoff))
            .toList();
        final earlier = notifications
            .where((n) => !n.timestamp.isAfter(cutoff))
            .toList();
        return NotificationsLoaded(
          recent: recent,
          earlier: earlier,
          co2SavedKg: 12.0,
        );
      },
      onError: (e, _) => NotificationsError(e.toString()),
    );
  }

  Future<void> _onMarkRead(
    NotificationMarkRead event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repo.markAsRead(event.notificationId);
  }

  Future<void> _onMarkAll(
    NotificationsMarkAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repo.markAllAsRead(event.userId);
  }
}
