import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/repositories/message_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

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

// ── States ────────────────────────────────────────────────────────────────────

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

class MessagesError extends MessagesState {
  final String message;
  const MessagesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository _messageRepository;

  MessagesBloc({required MessageRepository messageRepository})
    : _messageRepository = messageRepository,
      super(MessagesInitial()) {
    on<MessagesLoadRequested>(_onLoad);
    on<MessagesChatOpened>(_onChatOpened);
    on<MessageSent>(_onMessageSent);
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
}
