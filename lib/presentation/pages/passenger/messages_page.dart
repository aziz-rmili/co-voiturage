import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/conversation.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/messages_bloc.dart';
import '../../widgets/shared_widgets.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<MessagesBloc>().add(MessagesLoadRequested(auth.user.uid));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: RideLeafAppBar(
        onNotificationTap: () => context.push(AppRoutes.notifications),
        avatarUrl: '',
      ),
      body: Column(
        children: [
          // ── Search bar
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
                // Always show seed conversations as fallback for demo
                final convs = state is MessagesLoaded
                    ? state.conversations
                    : <Conversation>[];

                return CustomScrollView(
                  slivers: [
                    // ── Avatar row (active contacts)
                    SliverToBoxAdapter(
                      child: _ActiveContactsRow(conversations: convs),
                    ),

                    // ── Conversation list
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          _buildConversationTiles(context, convs),
                        ),
                      ),
                    ),

                    // ── Bottom stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: 'KG CO2 Saved',
                                value: '12.4',
                                dark: true,
                                icon: Icons.eco_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                label: 'New Connections',
                                value: '08',
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
    );
  }

  List<Widget> _buildConversationTiles(
    BuildContext context,
    List<Conversation> convs,
  ) {
    // Seed data for demo display
    final seeds = [
      _SeedConv(
        name: 'Amir saad',
        preview: "Perfect, I'll wait for y...",
        time: '10:45 AM',
        hasUnread: true,
      ),
      _SeedConv(
        name: 'Mayssem M',
        preview: 'Thanks for the ride! T...',
        time: 'YESTERDAY',
        hasUnread: false,
      ),
      _SeedConv(
        name: 'Aysser BR',
        preview: 'Can we move the dep...',
        time: 'TUE',
        hasUnread: false,
      ),
      _SeedConv(
        name: 'Yossra BS',
        preview: 'Is there still room for ...',
        time: 'MON',
        hasUnread: true,
      ),
    ];

    return seeds
        .map(
          (s) => _ConversationTile(
            name: s.name,
            preview: s.preview,
            time: s.time,
            hasUnread: s.hasUnread,
            onTap: () {},
          ),
        )
        .toList();
  }
}

class _SeedConv {
  final String name;
  final String preview;
  final String time;
  final bool hasUnread;

  _SeedConv({
    required this.name,
    required this.preview,
    required this.time,
    required this.hasUnread,
  });
}

// ── Active contacts horizontal row ────────────────────────────────────────────

class _ActiveContactsRow extends StatelessWidget {
  final List<Conversation> conversations;

  const _ActiveContactsRow({required this.conversations});

  @override
  Widget build(BuildContext context) {
    final names = ['Amir', 'Mayssem', 'Aysser', 'Yossra', 'Sami'];
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: names.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.forestGreen.withOpacity(0.15),
                child: Text(
                  names[i][0],
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
        ),
      ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final String name;
  final String preview;
  final String time;
  final bool hasUnread;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.preview,
    required this.time,
    required this.hasUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    name[0],
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
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
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
                  time,
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
