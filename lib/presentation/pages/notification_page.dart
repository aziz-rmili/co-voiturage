import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/app_notification.dart';
import '../../presentation/blocs/auth_bloc.dart';
import '../../presentation/blocs/notifications_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<NotificationsBloc>().add(
        NotificationsLoadRequested(auth.user.uid),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.forestGreen,
            size: 20,
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.textDark,
            size: 24,
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.forestGreen.withOpacity(0.2),
            child: const Icon(
              Icons.person,
              color: AppColors.forestGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── New Activity header
                const Text(
                  'New Activity',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 48,
                  color: AppColors.orange,
                ),

                const SizedBox(height: 20),

                // ── Recent notifications
                ..._buildRecentCards(state),

                const SizedBox(height: 24),

                // ── Earlier
                const Text(
                  'EARLIER',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                ..._buildEarlierCards(state),

                // ── See more
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      backgroundColor: const Color(0xFFEEEEEE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'See more',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── CO2 milestone card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUSTAINABILITY MILESTONE',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state is NotificationsLoaded
                            ? 'You saved\n${state.co2SavedKg.toStringAsFixed(0)}kg of CO2\nthis week.'
                            : 'You saved\n12kg of CO2\nthis week.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // ── Bottom nav (notifications shows its own simple nav)
      bottomNavigationBar: _SimpleBottomNav(
        currentIndex: -1, // not a main tab
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/search');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }

  List<Widget> _buildRecentCards(NotificationsState state) {
    if (state is NotificationsLoaded && state.recent.isNotEmpty) {
      return state.recent
          .map((n) => _NotificationCard(notification: n))
          .toList();
    }

    // Seed data
    return [
      _SeedNotifCard(
        icon: Icons.directions_car_rounded,
        iconBg: const Color(0xFFD4EDDA),
        iconColor: AppColors.forestGreen,
        title: 'Trip confirmed',
        body: 'Your seat for the ride to downtown is locked in. Ready to go?',
        time: '2 MINS AGO',
        requiresAction: true,
      ),
      _SeedNotifCard(
        icon: Icons.account_balance_wallet_outlined,
        iconBg: const Color(0xFFD4EDDA),
        iconColor: AppColors.forestGreen,
        title: 'Payment received',
        body: 'Transaction for your carpool session with Sarah was successful.',
        time: '15 MINS AGO',
        requiresAction: false,
      ),
    ];
  }

  List<Widget> _buildEarlierCards(NotificationsState state) {
    if (state is NotificationsLoaded && state.earlier.isNotEmpty) {
      return state.earlier
          .map((n) => _NotificationCard(notification: n))
          .toList();
    }
    return [
      _SeedNotifCard(
        icon: Icons.notifications_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: AppColors.textMuted,
        title: 'System Update',
        body: 'Your CO2 savings report for July is now ready.',
        time: 'Yesterday',
        requiresAction: false,
        compact: true,
      ),
      _SeedNotifCard(
        icon: Icons.settings_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: AppColors.textMuted,
        title: 'Account verified',
        body: 'Profile validation is complete.',
        time: '3d ago',
        requiresAction: false,
        compact: true,
      ),
    ];
  }
}

// ── Notification card from domain entity ─────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return _SeedNotifCard(
      icon: _iconForType(notification.type),
      iconBg: const Color(0xFFD4EDDA),
      iconColor: AppColors.forestGreen,
      title: notification.title,
      body: notification.body,
      time: _formatTime(notification.timestamp),
      requiresAction: notification.requiresAction,
    );
  }

  IconData _iconForType(NotificationType t) {
    switch (t) {
      case NotificationType.tripConfirmed:
        return Icons.directions_car_rounded;
      case NotificationType.paymentReceived:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.accountVerified:
        return Icons.verified_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} MINS AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    return '${diff.inDays}d ago';
  }
}

// ── Seed notification card ────────────────────────────────────────────────────

class _SeedNotifCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool requiresAction;
  final bool compact;

  const _SeedNotifCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.requiresAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (requiresAction) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ACTION REQUIRED',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple 4-tab bottom nav (for notifications page) ──────────────────────────

class _SimpleBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SimpleBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECE9), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(Icons.home_outlined, 'HOME', 0),
              _item(Icons.search_rounded, 'SEARCH', 1),
              _item(Icons.notifications_rounded, 'ALERTS', 2, active: true),
              _item(Icons.person_outline_rounded, 'PROFILE', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int idx, {bool active = false}) {
    final c = active || currentIndex == idx
        ? AppColors.forestGreen
        : AppColors.textMuted;
    return GestureDetector(
      onTap: () => onTap(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
