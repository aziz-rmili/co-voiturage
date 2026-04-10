import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../injection/service_locator.dart';
import '../../blocs/blocs.dart';
import '../../widgets/shared_widgets.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchCtrl = TextEditingController();
  bool _loaded = false;
  final Map<String, String> _userNames = {};

  Future<void> _resolveParticipantNames(List<Conversation> convos) async {
    final currentUserId = _currentUserId(context);
    final otherIds = convos
        .expand((conv) => conv.participantIds)
        .where((id) => id != currentUserId && !_userNames.containsKey(id))
        .toSet()
        .toList();

    if (otherIds.isEmpty) return;

    try {
      final users = await sl<UserRepository>().getUsersByIds(otherIds);
      if (!mounted) return;
      setState(() {
        for (final user in users) {
          _userNames[user.uid] = user.name;
        }
      });
    } catch (_) {
      // ignore lookup failures; fall back to IDs
    }
  }

  void _load(String uid) {
    if (_loaded) return;
    _loaded = true;
    context.read<MessagesBloc>().add(MessagesLoadRequested(uid));
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) _load(auth.user.uid);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _currentUserId(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated ? auth.user.uid : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: RideLeafAppBar(
        onNotificationTap: () => context.push(AppRoutes.notifications),
        avatarUrl: '',
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is AuthAuthenticated) _load(authState.user.uid);
            },
          ),
          BlocListener<MessagesBloc, MessagesState>(
            listener: (context, state) {
              if (state is MessagesLoaded) {
                _resolveParticipantNames(state.conversations);
              }
            },
          ),
        ],
        child: Column(
          children: [
            // ── Search
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<MessagesBloc, MessagesState>(
                builder: (context, state) {
                  if (state is MessagesLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.forestGreen,
                      ),
                    );
                  }
                  if (state is MessagesError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  var convs = state is MessagesLoaded
                      ? state.conversations
                      : <Conversation>[];

                  // Apply search filter
                  final q = _searchCtrl.text.toLowerCase();
                  if (q.isNotEmpty) {
                    convs = convs
                        .where(
                          (c) =>
                              c.lastMessage.toLowerCase().contains(q) ||
                              c.participantIds.any(
                                (id) =>
                                    id.toLowerCase().contains(q) ||
                                    (_userNames[id]?.toLowerCase().contains(
                                          q,
                                        ) ??
                                        false),
                              ),
                        )
                        .toList();
                  }

                  if (convs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.textMuted,
                            size: 52,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No conversations yet.\nBook a ride and message the driver!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final currentUserId = _currentUserId(context);

                  return CustomScrollView(
                    slivers: [
                      // ── Active contacts row
                      SliverToBoxAdapter(
                        child: _ActiveContactsRow(
                          conversations: convs,
                          currentUserId: currentUserId,
                          userNames: _userNames,
                        ),
                      ),

                      // ── Conversation tiles
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final conv = convs[i];
                            final otherId = conv.participantIds.firstWhere(
                              (id) => id != currentUserId,
                              orElse: () => '?',
                            );
                            final otherName = _userNames[otherId];
                            return _ConversationTile(
                              conversation: conv,
                              currentUserId: currentUserId,
                              otherName: otherName,
                              onTap: () => context.push(
                                AppRoutes.chat,
                                extra: {
                                  'currentUserId': currentUserId,
                                  'otherUserId': otherId,
                                  'otherUserName': otherName,
                                  'rideId': conv.rideId,
                                  'conversationId': conv.id,
                                },
                              ),
                            );
                          }, childCount: convs.length),
                        ),
                      ),

                      // ── Stats
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                          child: Row(
                            children: [
                              BlocBuilder<HomeBloc, HomeState>(
                                builder: (context, homeState) {
                                  final co2Value = homeState is HomeLoaded
                                      ? homeState.co2SavedKg.toStringAsFixed(1)
                                      : '0.0';
                                  return Expanded(
                                    child: StatCard(
                                      label: 'CO2 Saved',
                                      value: co2Value,
                                      unit: 'kg',
                                      dark: true,
                                      icon: Icons.eco_rounded,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  label: 'Connections',
                                  value: convs.length.toString().padLeft(
                                    2,
                                    '0',
                                  ),
                                  dark: false,
                                  icon: Icons.group_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveContactsRow extends StatelessWidget {
  final List<Conversation> conversations;
  final String currentUserId;
  final Map<String, String> userNames;
  const _ActiveContactsRow({
    required this.conversations,
    required this.currentUserId,
    required this.userNames,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: conversations.length,
        itemBuilder: (_, i) {
          final otherId = conversations[i].participantIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '?',
          );
          final displayName = userNames[otherId] ?? otherId;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.forestGreen.withOpacity(0.15),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final String? otherName;
  final VoidCallback onTap;
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    this.otherName,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'YESTERDAY';
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[dt.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final otherId = conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '?',
    );
    final displayName = otherName ?? otherId;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final hasUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.forestGreen.withOpacity(0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage.isEmpty
                        ? 'Start the conversation'
                        : conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation.lastMessageTime),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
