import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  Stream<List<Conversation>> getConversations(String userId);
  Stream<List<Message>> getMessages(String conversationId);
  Future<void> sendMessage(Message message);
  Future<void> markAsRead(String conversationId, String userId);
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    String? rideId,
  });
}
