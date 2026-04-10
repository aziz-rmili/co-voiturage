import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/ride.dart';
import '../../blocs/blocs.dart';
import '../../widgets/shared_widgets.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});
  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<TripsBloc>().add(TripsTabChanged(_tabCtrl.index));
      }
    });
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _currentUserId = auth.user.uid;
      context.read<TripsBloc>().add(TripsLoadRequested(auth.user.uid));
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
      body: BlocBuilder<TripsBloc, TripsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // ── Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Trips',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const Text(
                        'ECO-CONSCIOUS JOURNEYS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _Tab(
                            label: 'Upcoming',
                            active: _tabCtrl.index == 0,
                            onTap: () => _tabCtrl.animateTo(0),
                          ),
                          const SizedBox(width: 24),
                          _Tab(
                            label: 'Past',
                            active: _tabCtrl.index == 1,
                            onTap: () => _tabCtrl.animateTo(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Content
              if (state is TripsLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.forestGreen,
                    ),
                  ),
                )
              else if (state is TripsError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is TripsLoaded && state.activeRides.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _TripCard(
                        ride: state.activeRides[i],
                        currentUserId: _currentUserId ?? '',
                      ),
                      childCount: state.activeRides.length,
                    ),
                  ),
                )
              else if (state is TripsLoaded && state.activeRides.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabCtrl.index == 0
                              ? Icons.directions_car_outlined
                              : Icons.history_rounded,
                          color: AppColors.textMuted,
                          size: 52,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _tabCtrl.index == 0
                              ? 'No upcoming trips.\nBook a ride to get started!'
                              : 'No past trips yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Bottom stats
              if (state is TripsLoaded)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.eco_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total CO2 saved this month: ${state.totalCo2SavedKg.toStringAsFixed(0)}kg',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4EDDA),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.card_giftcard_outlined,
                                  color: AppColors.forestGreen,
                                  size: 20,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'You earned\nthe eco-friendly pass!',
                                  style: TextStyle(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
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
}

// ── Tab ───────────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        if (active) Container(height: 2, width: 40, color: AppColors.orange),
      ],
    ),
  );
}

// ── Trip card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Ride ride;
  final String currentUserId;
  const _TripCard({required this.ride, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isDriver = ride.driverId == currentUserId;
    final isPending = ride.pendingPassengerIds.contains(currentUserId);
    final isConfirmed = ride.confirmedPassengerIds.contains(currentUserId);

    // Determine status label and color from the current user's perspective
    String statusLabel;
    Color statusColor;
    if (ride.status == RideStatus.cancelled) {
      statusLabel = 'CANCELLED';
      statusColor = AppColors.error;
    } else if (ride.status == RideStatus.completed) {
      statusLabel = 'COMPLETED';
      statusColor = AppColors.textMuted;
    } else if (isDriver) {
      // Driver sees the ride as ACTIVE once it has any passenger
      statusLabel = 'YOUR RIDE';
      statusColor = AppColors.forestGreen;
    } else if (isConfirmed) {
      statusLabel = 'CONFIRMED';
      statusColor = AppColors.brownOrange;
    } else if (isPending) {
      statusLabel = 'PENDING';
      statusColor = AppColors.orange;
    } else {
      statusLabel = 'BOOKED';
      statusColor = AppColors.textMuted;
    }

    final co2 = (ride.availableSeats * 2.4).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEE, MMM d • HH:mm').format(ride.dateHour),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                'CO2 SAVED',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '$co2 kg',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Route
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.forestGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 28,
                    color: AppColors.textMuted.withOpacity(0.3),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textMuted, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEPARTURE',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      ride.departureAddress.isNotEmpty
                          ? ride.departureAddress
                          : 'Departure',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'DESTINATION',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      ride.arrivalAddress.isNotEmpty
                          ? ride.arrivalAddress
                          : 'Arrival',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          // Seats info + details button
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SEATS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${ride.confirmedPassengerIds.length}/${ride.availableSeats} confirmed',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (ride.pendingPassengerIds.isNotEmpty)
                    Text(
                      '${ride.pendingPassengerIds.length} pending',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('${AppRoutes.tripDetail}/${ride.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4EDDA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
