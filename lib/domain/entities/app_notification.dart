import 'package:equatable/equatable.dart';

enum NotificationType {
  tripConfirmed,
  bookingRequested,
  bookingApproved,
  bookingRejected,
  paymentReceived,
  systemUpdate,
  accountVerified,
  tripCancelled,
  newMessage,
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final bool requiresAction;
  final String? relatedId; // rideId or conversationId

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.requiresAction = false,
    this.relatedId,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    body,
    timestamp,
    isRead,
    requiresAction,
  ];
}
