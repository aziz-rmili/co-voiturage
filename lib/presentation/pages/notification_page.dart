import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/app_notification.dart';
import '../../presentation/blocs/blocs.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loaded = false;

  void _load(String uid) {
    if (_loaded) return;
    _loaded = true;
    context.read<NotificationsBloc>().add(NotificationsLoadRequested(uid));
  }

  @override
  void initState() {
    super.initState();
    // Try immediately — works if AuthBloc is already authenticated
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) _load(auth.user.uid);
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
      body: BlocListener<AuthBloc, AuthState>(
        // If AuthBloc emits authenticated while page is open, trigger load
        listener: (context, authState) {
          if (authState is AuthAuthenticated) _load(authState.user.uid);
        },
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading ||
                state is NotificationsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              );
            }
            if (state is NotificationsError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              );
            }
            if (state is! NotificationsLoaded) return const SizedBox.shrink();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header
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

                  // ── Recent
                  if (state.recent.isEmpty && state.earlier.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.textMuted,
                              size: 52,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No notifications yet.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    ...state.recent.map(
                      (n) => _NotificationCard(
                        notification: n,
                        onTap: () {
                          context.read<NotificationsBloc>().add(
                            NotificationMarkRead(n.id),
                          );
                          if (n.relatedId != null &&
                              n.type == NotificationType.bookingRequested) {
                            context.push('${AppRoutes.tripDetail}/${n.relatedId}');
                          }
                        },
                      ),
                    ),

                    if (state.earlier.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                      ...state.earlier.map(
                        (n) => _NotificationCard(
                          notification: n,
                          onTap: () {
                            context.read<NotificationsBloc>().add(
                              NotificationMarkRead(n.id),
                            );
                            if (n.relatedId != null &&
                                n.type == NotificationType.bookingRequested) {
                              context.push('${AppRoutes.tripDetail}/${n.relatedId}');
                            }
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final auth = context.read<AuthBloc>().state;
                          if (auth is AuthAuthenticated) {
                            context.read<NotificationsBloc>().add(
                              NotificationsMarkAllRead(auth.user.uid),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFFEEEEEE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Mark all as read',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── CO2 milestone
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
                          'You saved\n${state.co2SavedKg.toStringAsFixed(0)}kg of CO2\nthis week.',
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
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationCard({required this.notification, required this.onTap});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.tripConfirmed:
        return Icons.directions_car_rounded;
      case NotificationType.bookingRequested:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.bookingApproved:
        return Icons.check_circle_outline_rounded;
      case NotificationType.bookingRejected:
        return Icons.cancel_outlined;
      case NotificationType.paymentReceived:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.accountVerified:
        return Icons.verified_outlined;
      case NotificationType.tripCancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconBg {
    switch (notification.type) {
      case NotificationType.tripConfirmed:
      case NotificationType.bookingRequested:
      case NotificationType.bookingApproved:
      case NotificationType.bookingRejected:
      case NotificationType.paymentReceived:
      case NotificationType.accountVerified:
        return const Color(0xFFD4EDDA);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.tripConfirmed:
      case NotificationType.bookingRequested:
      case NotificationType.bookingApproved:
      case NotificationType.bookingRejected:
      case NotificationType.paymentReceived:
      case NotificationType.accountVerified:
        return AppColors.forestGreen;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} MINS AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(
                  color: AppColors.forestGreen.withOpacity(0.2),
                  width: 1,
                ),
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
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.timestamp),
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
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (notification.requiresAction) ...[
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
      ),
    );
  }
}
