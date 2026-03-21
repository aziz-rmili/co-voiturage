import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../blocs/auth_bloc.dart';
import '../../blocs/home_bloc.dart';
import '../../widgets/shared_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();

  // Tunis center as default
  static const double _lat = 36.8065;
  static const double _lng = 10.1815;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(
      const HomeLoadRequested(userLat: _lat, userLng: _lng),
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
          return CustomScrollView(
            slivers: [
              // ── Hero heading
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

              // ── Search bar
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
                  child: BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      final filter = state is HomeLoaded
                          ? state.dateFilter
                          : 'today';
                      return Row(
                        children: [
                          _FilterChip(
                            label: 'Today',
                            active: filter == 'today',
                            onTap: () => context.read<HomeBloc>().add(
                              const HomeDateFilterChanged('today'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            label: 'Tomorrow',
                            active: filter == 'tomorrow',
                            onTap: () => context.read<HomeBloc>().add(
                              const HomeDateFilterChanged('tomorrow'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _FilterChip(
                            label: 'Group',
                            active: filter == 'group',
                            icon: Icons.group_outlined,
                            onTap: () => context.read<HomeBloc>().add(
                              const HomeDateFilterChanged('group'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: state is HomeLoaded
                      ? Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: 'CO2 Saved',
                                value: state.co2SavedKg.toStringAsFixed(1),
                                unit: 'kg',
                                dark: true,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                          child: Center(child: CircularProgressIndicator()),
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
                        onTap: () => context.push(AppRoutes.map),
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
              if (state is HomeLoaded && state.popularRides.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final ride = state.popularRides[i];
                      return RideRouteCard(
                        from: ride.departureAddress.isNotEmpty
                            ? ride.departureAddress
                            : 'Departure',
                        to: ride.arrivalAddress.isNotEmpty
                            ? ride.arrivalAddress
                            : 'Arrival',
                        driverName: 'Driver',
                        driverRating: 4.9,
                        driverTrips: 128,
                        price: ride.pricePerPassenger,
                        onBook: () =>
                            context.push('${AppRoutes.tripDetail}/${ride.id}'),
                      );
                    }, childCount: state.popularRides.length),
                  ),
                )
              else if (state is HomeLoaded)
                // Seed data fallback cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      RideRouteCard(
                        from: 'Tunis',
                        to: 'Sidi Bou Said',
                        driverName: 'Ahmed M',
                        driverRating: 4.9,
                        driverTrips: 128,
                        price: 4,
                        onBook: () {},
                      ),
                      RideRouteCard(
                        from: 'Sousse',
                        to: 'Monastir',
                        driverName: 'Maher K',
                        driverRating: 5.0,
                        driverTrips: 42,
                        price: 5,
                        onBook: () {},
                      ),
                    ]),
                  ),
                ),

              // ── Map banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.map),
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/map_preview.png'),
                          fit: BoxFit.cover,
                          onError: _mapImageError,
                        ),
                        color: AppColors.forestGreen,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.forestGreen.withOpacity(0.7),
                            ],
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
              ),
            ],
          );
        },
      ),
    );
  }
}

void _mapImageError(Object e, StackTrace? st) {}

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
