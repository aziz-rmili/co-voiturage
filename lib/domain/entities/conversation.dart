import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? rideId; // linked ride if any

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.rideId,
  });

  @override
  List<Object?> get props => [
    id,
    participantIds,
    lastMessage,
    lastMessageTime,
    unreadCount,
    rideId,
  ];
}
