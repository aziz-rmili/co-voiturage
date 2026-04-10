import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/message_repository.dart';

abstract class MessagesEvent extends Equatable {
  const MessagesEvent();
  @override
  List<Object?> get props => [];
}

class MessagesLoadRequested extends MessagesEvent {
  final String userId;
  const MessagesLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MessagesChatOpened extends MessagesEvent {
  final String conversationId;
  final String userId;
  const MessagesChatOpened({
    required this.conversationId,
    required this.userId,
  });
  @override
  List<Object?> get props => [conversationId, userId];
}

class MessageSent extends MessagesEvent {
  final Message message;
  const MessageSent(this.message);
  @override
  List<Object?> get props => [message];
}

/// Creates a conversation lazily on first message send.
class MessagesGetOrCreateConversation extends MessagesEvent {
  final String currentUserId;
  final String otherUserId;
  final String? rideId;
  final String firstMessage;
  const MessagesGetOrCreateConversation({
    required this.currentUserId,
    required this.otherUserId,
    this.rideId,
    required this.firstMessage,
  });
  @override
  List<Object?> get props => [currentUserId, otherUserId, rideId, firstMessage];
}

abstract class MessagesState extends Equatable {
  const MessagesState();
  @override
  List<Object?> get props => [];
}

class MessagesInitial extends MessagesState {}

class MessagesLoading extends MessagesState {}

class MessagesLoaded extends MessagesState {
  final List<Conversation> conversations;
  const MessagesLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class ChatLoaded extends MessagesState {
  final List<Message> messages;
  final String conversationId;
  const ChatLoaded({required this.messages, required this.conversationId});
  @override
  List<Object?> get props => [messages, conversationId];
}

/// Emitted after a conversation is created so the chat page can subscribe.
class ConversationCreated extends MessagesState {
  final String conversationId;
  const ConversationCreated(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class MessagesError extends MessagesState {
  final String message;
  const MessagesError(this.message);
  @override
  List<Object?> get props => [message];
}

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository _messageRepository;

  MessagesBloc({required MessageRepository messageRepository})
    : _messageRepository = messageRepository,
      super(MessagesInitial()) {
    on<MessagesLoadRequested>(_onLoad);
    on<MessagesChatOpened>(_onChatOpened);
    on<MessageSent>(_onMessageSent);
    on<MessagesGetOrCreateConversation>(_onGetOrCreate);
  }

  Future<void> _onLoad(
    MessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    emit(MessagesLoading());
    await emit.forEach(
      _messageRepository.getConversations(event.userId),
      onData: (convs) => MessagesLoaded(convs),
      onError: (e, _) => MessagesError(e.toString()),
    );
  }

  Future<void> _onChatOpened(
    MessagesChatOpened event,
    Emitter<MessagesState> emit,
  ) async {
    await _messageRepository.markAsRead(event.conversationId, event.userId);
    await emit.forEach(
      _messageRepository.getMessages(event.conversationId),
      onData: (msgs) =>
          ChatLoaded(messages: msgs, conversationId: event.conversationId),
      onError: (e, _) => MessagesError(e.toString()),
    );
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      await _messageRepository.sendMessage(event.message);
    } catch (e) {
      emit(MessagesError(e.toString()));
    }
  }

  Future<void> _onGetOrCreate(
    MessagesGetOrCreateConversation event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final conv = await _messageRepository.getOrCreateConversation(
        currentUserId: event.currentUserId,
        otherUserId: event.otherUserId,
        rideId: event.rideId,
      );
      // Emit conversation ID so chat page can subscribe
      emit(ConversationCreated(conv.id));

      // Send the first message
      await _messageRepository.sendMessage(
        Message(
          id: '',
          conversationId: conv.id,
          senderId: event.currentUserId,
          receiverId: event.otherUserId,
          text: event.firstMessage,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(MessagesError(e.toString()));
    }
  }
}
