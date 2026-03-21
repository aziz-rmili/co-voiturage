import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/ride.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/trips_bloc.dart';
import '../../widgets/shared_widgets.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      context.read<TripsBloc>().add(TripsTabChanged(_tabCtrl.index));
    });
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
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

                      // Tabs
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

              // ── Trips
              if (state is TripsLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is TripsLoaded && state.activeRides.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _TripCard(ride: state.activeRides[i]),
                      childCount: state.activeRides.length,
                    ),
                  ),
                )
              else
                // Seed data for demo
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SeedTripCard(
                        timeLabel: 'TODAY • 17:30',
                        status: 'CONFIRMED',
                        statusColor: AppColors.brownOrange,
                        from: 'Tunis',
                        to: 'Sidi Bou Said',
                        co2: '2.4 kg',
                        driverName: 'Sami N',
                        onDetails: () {},
                      ),
                      _SeedTripCard(
                        timeLabel: 'THU, OCT 24 • 08:15',
                        status: 'PENDING',
                        statusColor: AppColors.textMuted,
                        from: 'Nabeul',
                        to: 'Kelibia',
                        co2: '4.1 kg',
                        driverName: 'Salim K',
                        onDetails: () {},
                      ),
                    ]),
                  ),
                ),

              // ── Bottom stats
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
                                state is TripsLoaded
                                    ? 'Total CO2 saved this month: ${state.totalCo2SavedKg.toStringAsFixed(0)}kg'
                                    : 'Total CO2 saved this month: 42kg',
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

// ── Tab widget ────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

// ── Trip card from domain ─────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Ride ride;
  const _TripCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final statusLabel = ride.status == RideStatus.scheduled
        ? 'CONFIRMED'
        : ride.status.name.toUpperCase();
    final statusColor = ride.status == RideStatus.scheduled
        ? AppColors.brownOrange
        : AppColors.textMuted;

    return _SeedTripCard(
      timeLabel: DateFormat('EEE, MMM d • HH:mm').format(ride.dateHour),
      status: statusLabel,
      statusColor: statusColor,
      from: ride.departureAddress.isNotEmpty
          ? ride.departureAddress
          : 'Departure',
      to: ride.arrivalAddress.isNotEmpty ? ride.arrivalAddress : 'Arrival',
      co2: '${(ride.availableSeats * 1.2).toStringAsFixed(1)} kg',
      driverName: 'Driver',
      onDetails: () => context.push('${AppRoutes.tripDetail}/${ride.id}'),
    );
  }
}

// ── Seed trip card ────────────────────────────────────────────────────────────

class _SeedTripCard extends StatelessWidget {
  final String timeLabel;
  final String status;
  final Color statusColor;
  final String from;
  final String to;
  final String co2;
  final String driverName;
  final VoidCallback onDetails;

  const _SeedTripCard({
    required this.timeLabel,
    required this.status,
    required this.statusColor,
    required this.from,
    required this.to,
    required this.co2,
    required this.driverName,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
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
          // Time + status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeLabel,
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
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                co2,
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
                      from,
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
                      to,
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

          // Driver row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.forestGreen.withOpacity(0.15),
                child: Text(
                  driverName[0],
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DRIVER',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDetails,
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
