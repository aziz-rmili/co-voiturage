import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/ride.dart';
import '../../blocs/blocs.dart';
import '../../widgets/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  static const double _lat = 36.8065;
  static const double _lng = 10.1815;
  bool _initiated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initiated) return;
    _initiated = true;
    final auth = context.read<AuthBloc>().state;
    final uid = auth is AuthAuthenticated ? auth.user.uid : '';
    context.read<HomeBloc>().add(
      HomeLoadRequested(userLat: _lat, userLng: _lng, userId: uid),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final avatarUrl = authState is AuthAuthenticated
        ? authState.user.photoUrl
        : '';

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: RideLeafAppBar(
        onNotificationTap: () => context.push(AppRoutes.notifications),
        avatarUrl: avatarUrl,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final isLoaded = state is HomeLoaded;
          // Use filteredRides getter — applies both search and date filter
          final rides = isLoaded ? state.filteredRides : <Ride>[];
          final drivers = isLoaded ? state.drivers : <String, AppUser>{};

          return CustomScrollView(
            slivers: [
              // ── Hero
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Reduce Your\n',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'Carbon Trail.',
                          style: TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Search — filters by arrival address
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          context.read<HomeBloc>().add(HomeSearchChanged(v)),
                      decoration: const InputDecoration(
                        hintText: 'Where are you going?',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Date filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Today',
                        active: isLoaded && state.dateFilter == 'today',
                        onTap: () => context.read<HomeBloc>().add(
                          const HomeDateFilterChanged('today'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Tomorrow',
                        active: isLoaded && state.dateFilter == 'tomorrow',
                        onTap: () => context.read<HomeBloc>().add(
                          const HomeDateFilterChanged('tomorrow'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Group',
                        icon: Icons.group_outlined,
                        active: isLoaded && state.dateFilter == 'group',
                        onTap: () => context.read<HomeBloc>().add(
                          const HomeDateFilterChanged('group'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: isLoaded
                      ? Row(
                          children: [
                            // Card 1: User's real CO2 saved
                            Expanded(
                              child: StatCard(
                                label: 'CO2 Saved',
                                value: state.co2SavedKg == 0
                                    ? '0.0'
                                    : state.co2SavedKg.toStringAsFixed(1),
                                unit: 'kg',
                                dark: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Card 2: Active scheduled rides in the system
                            Expanded(
                              child: StatCard(
                                label: 'Active Trips',
                                value: state.activeTrips.toString(),
                                dark: false,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                ),
              ),

              // ── Popular routes header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Popular Routes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      GestureDetector(
                        // Push AllRidesPage — shows every ride with full search/filter
                        onTap: () => context.push(AppRoutes.allRides),
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Ride list
              if (state is HomeLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                )
              else if (rides.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final ride = rides[i];
                      final driver = drivers[ride.driverId];
                      return RideRouteCard(
                        from: ride.departureAddress.isNotEmpty
                            ? ride.departureAddress
                            : 'Departure',
                        to: ride.arrivalAddress.isNotEmpty
                            ? ride.arrivalAddress
                            : 'Arrival',
                        driverName: driver?.name ?? '...',
                        driverRating: driver?.averageRating ?? 0.0,
                        driverTrips: ride.passengersIds.length,
                        price: ride.pricePerPassenger,
                        onBook: () =>
                            context.push('${AppRoutes.tripDetail}/${ride.id}'),
                      );
                    }, childCount: rides.length),
                  ),
                )
              else if (state is HomeLoaded)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            color: AppColors.textMuted,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No rides match your search.\nTry a different date or destination.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Map banner — switches to map TAB (tab index 2), not a new route
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: GestureDetector(
                    onTap: () {
                      // Switch to Map tab inside MainShell — avoids the Provider error
                      MainShell.switchTab(context, 2);
                    },
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E4D35), Color(0xFF2D6E4E)],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'NEARBY DRIVERS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Explore the map',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.map_outlined,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (ctx) {
          final auth = ctx.watch<AuthBloc>().state;
          final canCreateRide =
              auth is AuthAuthenticated &&
              (auth.user.isVerifiedDriver || auth.user.isAdmin);
          if (!canCreateRide) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => ctx.push(AppRoutes.createRide),
            backgroundColor: AppColors.brownOrange,
            child: const Icon(Icons.add, color: AppColors.orange),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
