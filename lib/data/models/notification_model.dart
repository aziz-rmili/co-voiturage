import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    required super.timestamp,
    super.isRead,
    super.requiresAction,
    super.relatedId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      type: _parseType(d['type']),
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      isRead: d['isRead'] as bool? ?? false,
      requiresAction: d['requiresAction'] as bool? ?? false,
      relatedId: d['relatedId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.name,
    'title': title,
    'body': body,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
    'requiresAction': requiresAction,
    'relatedId': relatedId,
  };

  static NotificationType _parseType(dynamic v) {
    switch (v as String?) {
      case 'tripConfirmed':
        return NotificationType.tripConfirmed;
      case 'bookingRequested':
        return NotificationType.bookingRequested;
      case 'bookingApproved':
        return NotificationType.bookingApproved;
      case 'bookingRejected':
        return NotificationType.bookingRejected;
      case 'paymentReceived':
        return NotificationType.paymentReceived;
      case 'systemUpdate':
        return NotificationType.systemUpdate;
      case 'accountVerified':
        return NotificationType.accountVerified;
      case 'tripCancelled':
        return NotificationType.tripCancelled;
      case 'newMessage':
        return NotificationType.newMessage;
      default:
        return NotificationType.systemUpdate;
    }
  }
}
