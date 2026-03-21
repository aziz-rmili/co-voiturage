import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/exceptions.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class MessageRemoteDataSource {
  Stream<List<ConversationModel>> getConversations(String userId);
  Stream<List<MessageModel>> getMessages(String conversationId);
  Future<void> sendMessage(MessageModel message);
  Future<void> markAsRead(String conversationId, String userId);
  Future<ConversationModel> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    String? rideId,
  });
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final FirebaseFirestore _firestore;

  MessageRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  @override
  Stream<List<ConversationModel>> getConversations(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ConversationModel.fromFirestore(d)).toList(),
        );
  }

  @override
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      final batch = _firestore.batch();
      final msgRef = _conversations
          .doc(message.conversationId)
          .collection('messages')
          .doc();
      batch.set(msgRef, message.toMap());
      batch.update(_conversations.doc(message.conversationId), {
        'lastMessage': message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'unreadCount.${message.receiverId}': FieldValue.increment(1),
      });
      await batch.commit();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _conversations.doc(conversationId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    String? rideId,
  }) async {
    try {
      final participants = [currentUserId, otherUserId]..sort();
      final query = await _conversations
          .where('participantIds', isEqualTo: participants)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return ConversationModel.fromFirestore(query.docs.first);
      }

      final newConv = ConversationModel(
        id: '',
        participantIds: participants,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        rideId: rideId,
      );
      final ref = await _conversations.add(newConv.toMap());
      final doc = await ref.get();
      return ConversationModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
