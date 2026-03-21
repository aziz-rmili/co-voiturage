import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.participantIds,
    required super.lastMessage,
    required super.lastMessageTime,
    super.unreadCount,
    super.rideId,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participantIds: List<String>.from(d['participantIds'] ?? []),
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageTime: (d['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: (d['unreadCount'] as Map<String, dynamic>?) != null
          ? 0 // caller resolves per-user
          : 0,
      rideId: d['rideId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'participantIds': participantIds,
    'lastMessage': lastMessage,
    'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    'unreadCount': {}, // keyed by userId
    'rideId': rideId,
  };
}
