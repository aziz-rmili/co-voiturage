import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remote;
  MessageRepositoryImpl({required MessageRemoteDataSource remote})
    : _remote = remote;

  @override
  Stream<List<Conversation>> getConversations(String userId) =>
      _remote.getConversations(userId).handleError(_handleError);

  @override
  Stream<List<Message>> getMessages(String conversationId) =>
      _remote.getMessages(conversationId).handleError(_handleError);

  @override
  Future<void> sendMessage(Message message) async {
    try {
      await _remote.sendMessage(
        MessageModel(
          id: message.id,
          conversationId: message.conversationId,
          senderId: message.senderId,
          receiverId: message.receiverId,
          text: message.text,
          timestamp: message.timestamp,
          isRead: message.isRead,
        ),
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _remote.markAsRead(conversationId, userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    String? rideId,
  }) async {
    try {
      return await _remote.getOrCreateConversation(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        rideId: rideId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  void _handleError(dynamic e) {
    if (e is ServerException) throw ServerFailure(message: e.message);
    throw ServerFailure(message: e.toString());
  }
}
