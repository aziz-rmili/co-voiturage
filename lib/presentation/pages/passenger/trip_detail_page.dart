import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../injection/service_locator.dart';
import '../../blocs/blocs.dart';
import '../../widgets/rideleaf_button.dart';
import '../../widgets/shared_widgets.dart';

class TripDetailPage extends StatefulWidget {
  final String rideId;
  const TripDetailPage({super.key, required this.rideId});
  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  String? _currentUserId;
  final Map<String, String> _passengerNames = {};

  Future<void> _resolvePassengerNames(List<String> ids) async {
    final idsToFetch = ids
        .where((id) => id.isNotEmpty && !_passengerNames.containsKey(id))
        .toSet()
        .toList();
    if (idsToFetch.isEmpty) return;

    try {
      final users = await sl<UserRepository>().getUsersByIds(idsToFetch);
      if (!mounted) return;
      setState(() {
        for (final user in users) {
          _passengerNames[user.uid] = user.name;
        }
      });
    } catch (_) {
      // ignore lookup failures and continue displaying IDs
    }
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) _currentUserId = auth.user.uid;
    context.read<TripDetailBloc>().add(TripDetailLoadRequested(widget.rideId));
  }

  void _book() {
    if (_currentUserId == null) return;
    context.read<TripDetailBloc>().add(
      TripDetailBookRequested(_currentUserId!),
    );
  }

  void _cancelBooking() {
    if (_currentUserId == null) return;
    context.read<TripDetailBloc>().add(
      TripDetailCancelBooking(_currentUserId!),
    );
  }

  void _openChat(Ride ride, {String? otherUserName}) {
    _openChatWithUser(
      otherUserId: ride.driverId,
      otherUserName: otherUserName,
      rideId: ride.id,
    );
  }

  void _openChatWithUser({
    required String otherUserId,
    String? otherUserName,
    String? rideId,
  }) {
    if (_currentUserId == null) return;
    context.push(
      AppRoutes.chat,
      extra: {
        'currentUserId': _currentUserId!,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'rideId': rideId,
      },
    );
  }

  void _reportRide(
    String rideId,
    String driverId,
    String reason,
    String? details,
  ) {
    if (_currentUserId == null) return;
    context.read<TripDetailBloc>().add(
      TripDetailSubmitReportRequested(
        rideId: rideId,
        reporterId: _currentUserId!,
        driverId: driverId,
        reason: reason,
        details: details,
      ),
    );
  }

  Future<void> _showReportRideSheet(Ride ride) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _ReportRideSheet(
          onSubmit: (reason, details) {
            _reportRide(ride.id, ride.driverId, reason, details);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: RideLeafAppBar(
        showBack: true,
        showLogo: false,
        title: 'Trip Details',
        onNotificationTap: () => context.push(AppRoutes.notifications),
        avatarUrl: '',
      ),
      body: BlocConsumer<TripDetailBloc, TripDetailState>(
        listener: (context, state) {
          if (state is TripDetailLoaded) {
            _resolvePassengerNames([
              ...state.ride.pendingPassengerIds,
              ...state.ride.confirmedPassengerIds,
            ]);
            if (state.message != null) {
              final isSuccess = state.message == 'Trip reported successfully.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: isSuccess
                      ? AppColors.success
                      : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          if (state is TripDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TripDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            );
          }
          if (state is TripDetailError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          if (state is! TripDetailLoaded) return const SizedBox.shrink();

          final ride = state.ride;
          final driver = state.driver;
          final isDriver = _currentUserId == ride.driverId;
          final isPending = ride.pendingPassengerIds.contains(_currentUserId);
          final isConfirmed = ride.confirmedPassengerIds.contains(
            _currentUserId,
          );
          final hasBooked = isPending || isConfirmed;
          final isPastTrip = ride.dateHour.toUtc().isBefore(
            DateTime.now().toUtc(),
          );

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Driver + price card
                    Row(
                      children: [
                        Container(
                          height: 152,
                          width: 238,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.forestGreen
                                    .withOpacity(0.15),
                                backgroundImage:
                                    (driver?.photoUrl.isNotEmpty ?? false)
                                    ? NetworkImage(driver!.photoUrl)
                                    : null,
                                child: (driver?.photoUrl.isEmpty ?? true)
                                    ? Text(
                                        driver?.name.isNotEmpty == true
                                            ? driver!.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.forestGreen,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 24,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver?.name ?? 'Unknown Driver',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.orange,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${driver?.averageRating.toStringAsFixed(1) ?? '—'}',
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    driver?.verification.name.toUpperCase() ==
                                            'VERIFIED'
                                        ? '✓ VERIFIED DRIVER'
                                        : 'DRIVER',
                                    style: const TextStyle(
                                      color: AppColors.forestGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          height: 152,
                          width: 104,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'PRICE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '${ride.pricePerPassenger.toStringAsFixed(0)}DT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'per seat',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Booking status banner — only ONE shown at a time
                    if (isConfirmed)
                      _StatusBanner(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.forestGreen,
                        bg: AppColors.forestGreen.withOpacity(0.1),
                        title: 'Booking Confirmed!',
                        subtitle:
                            'Your seat is locked in. See you on the ride!',
                      )
                    else if (isPending)
                      _StatusBanner(
                        icon: Icons.access_time_rounded,
                        color: AppColors.orange,
                        bg: AppColors.orange.withOpacity(0.1),
                        title: 'Booking Pending',
                        subtitle:
                            'Waiting for the driver to confirm your seat.',
                      ),

                    // ── Route card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _RouteStop(
                            typeLabel:
                                'DEPARTURE • ${DateFormat('HH:mm').format(ride.dateHour)}',
                            city: ride.departureAddress.isNotEmpty
                                ? ride.departureAddress
                                : 'Departure',
                            isDeparture: true,
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 1,
                            height: 20,
                            color: AppColors.textMuted.withOpacity(0.3),
                          ),
                          _RouteStop(
                            typeLabel: 'ARRIVAL',
                            city: ride.arrivalAddress.isNotEmpty
                                ? ride.arrivalAddress
                                : 'Arrival',
                            isDeparture: false,
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFF0F0F0)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SEATS LEFT',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ride.seatsLeft}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.eco_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${(ride.availableSeats * 2.4).toStringAsFixed(1)} kg CO2',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Date card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.forestGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DEPARTURE DATE',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d • HH:mm',
                                ).format(ride.dateHour),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Preferences (from driver's profile)
                    if (driver != null &&
                        driver.ridePreferenceTags.isNotEmpty) ...[
                      const Text(
                        'TRIP PREFERENCES',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: driver.ridePreferenceTags
                            .map(
                              (pref) => _PreferenceChip(
                                icon: _iconForPref(pref),
                                label: _labelForPref(pref),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (ride.note.trim().isNotEmpty) ...[
                      const Text(
                        'DRIVER NOTE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEDEDED)),
                        ),
                        child: Text(
                          ride.note,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Driver view: pending passengers list
                    if (isDriver && ride.pendingPassengerIds.isNotEmpty) ...[
                      const Text(
                        'PENDING PASSENGERS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ride.pendingPassengerIds.map((pid) {
                        final passengerName = _passengerNames[pid];
                        return _PendingPassengerTile(
                          passengerId: pid,
                          passengerName: passengerName,
                          onConfirm: () => context.read<TripDetailBloc>().add(
                            TripDetailConfirmPassenger(pid),
                          ),
                          onReject: () => context.read<TripDetailBloc>().add(
                            TripDetailRejectPassenger(pid),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],

                    // ── Confirmed passengers
                    if (ride.confirmedPassengerIds.isNotEmpty) ...[
                      const Text(
                        'CONFIRMED PASSENGERS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ride.confirmedPassengerIds.map((id) {
                          final displayName = _passengerNames[id] ?? id;
                          return GestureDetector(
                            onTap: () => _openChatWithUser(
                              otherUserId: id,
                              otherUserName: displayName,
                              rideId: ride.id,
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.forestGreen
                                  .withOpacity(0.15),
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // ── Bottom action bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Row(
                    children: [
                      if (!isDriver) ...[
                        GestureDetector(
                          onTap: () =>
                              _openChat(ride, otherUserName: driver?.name),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: isDriver
                            ? const SizedBox.shrink()
                            : isPastTrip && isConfirmed
                            ? RideLeafButton(
                                label: 'Report Trip',
                                onPressed: () => _showReportRideSheet(ride),
                                isLoading: state.isReporting,
                                icon: Icons.flag_rounded,
                                backgroundColor: AppColors.error,
                              )
                            : hasBooked
                            ? _CancelButton(
                                onCancel: _cancelBooking,
                                isLoading: state.isBooking,
                              )
                            : RideLeafButton(
                                label: 'Book Now',
                                onPressed: ride.isFull ? null : _book,
                                isLoading: state.isBooking,
                                icon: Icons.arrow_forward_rounded,
                                backgroundColor: ride.isFull
                                    ? AppColors.textMuted
                                    : null,
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
    );
  }

  IconData _iconForPref(String p) {
    switch (p) {
      case 'no_smoking':
        return Icons.smoke_free_rounded;
      case 'pets_welcome':
        return Icons.pets_outlined;
      case 'medium_bag':
        return Icons.luggage_outlined;
      case 'small_bag_only':
        return Icons.work_outline_rounded;
      case 'large_items':
        return Icons.luggage_rounded;
      case 'quiet_trip':
        return Icons.volume_off_rounded;
      case 'chatty':
        return Icons.chat_bubble_outline_rounded;
      case 'max_2_back':
        return Icons.airline_seat_recline_normal_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _labelForPref(String p) {
    switch (p) {
      case 'no_smoking':
        return 'No Smoking';
      case 'pets_welcome':
        return 'Pets Welcome';
      case 'medium_bag':
        return 'Medium Bag';
      case 'small_bag_only':
        return 'Small bag only';
      case 'large_items':
        return 'Large items';
      case 'quiet_trip':
        return 'Quiet ride';
      case 'chatty':
        return 'Chatty';
      case 'max_2_back':
        return 'Max 2 in back';
      default:
        return p;
    }
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Route stop ────────────────────────────────────────────────────────────────

class _RouteStop extends StatelessWidget {
  final String typeLabel;
  final String city;
  final bool isDeparture;
  const _RouteStop({
    required this.typeLabel,
    required this.city,
    required this.isDeparture,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.forestGreen, width: 2),
          shape: BoxShape.circle,
        ),
        child: isDeparture
            ? null
            : Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.forestGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
      ),
      const SizedBox(width: 14),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            typeLabel,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            city,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    ],
  );
}

// ── Preference chip ───────────────────────────────────────────────────────────

class _PreferenceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PreferenceChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    ),
  );
}

// ── Pending passenger tile (driver view) ──────────────────────────────────────

class _PendingPassengerTile extends StatelessWidget {
  final String passengerId;
  final String? passengerName;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  const _PendingPassengerTile({
    required this.passengerId,
    this.passengerName,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = passengerName ?? passengerId;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.orange.withOpacity(0.15),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  'Pending confirmation',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.forestGreen,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReject,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRideSheet extends StatefulWidget {
  final void Function(String reason, String? details) onSubmit;

  const _ReportRideSheet({required this.onSubmit});

  @override
  State<_ReportRideSheet> createState() => _ReportRideSheetState();
}

class _ReportRideSheetState extends State<_ReportRideSheet> {
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedReason;

  static const _reasons = [
    'Driver was late',
    'Unsatisfactory vehicle',
    'Unsafe behavior',
    'Unexpected route',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 48,
              child: Divider(
                height: 4,
                thickness: 4,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Report this trip',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a reason and add details if needed.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _reasons.map((reason) {
              final selected = reason == _selectedReason;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedReason = reason;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.forestGreen
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.forestGreen
                          : AppColors.textMuted.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _detailsController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Describe the issue (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: RideLeafButton(
              label: 'Submit Report',
              onPressed: _selectedReason == null
                  ? null
                  : () {
                      widget.onSubmit(
                        _selectedReason!,
                        _detailsController.text.trim().isEmpty
                            ? null
                            : _detailsController.text.trim(),
                      );
                      Navigator.of(context).pop();
                    },
              icon: Icons.flag_rounded,
              backgroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cancel button ─────────────────────────────────────────────────────────────

class _CancelButton extends StatelessWidget {
  final VoidCallback onCancel;
  final bool isLoading;
  const _CancelButton({required this.onCancel, required this.isLoading});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: OutlinedButton(
      onPressed: isLoading ? null : onCancel,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.error, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.error,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  'Cancel Booking',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    ),
  );
}
