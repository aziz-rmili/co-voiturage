import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/blocs.dart';
import '../../widgets/shared_widgets.dart';

class AllRidesPage extends StatefulWidget {
  const AllRidesPage({super.key});
  @override
  State<AllRidesPage> createState() => _AllRidesPageState();
}

class _AllRidesPageState extends State<AllRidesPage> {
  final _searchCtrl = TextEditingController();
  static const double _lat = 36.8065;
  static const double _lng = 10.1815;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthBloc>().state;
      final uid = auth is AuthAuthenticated ? auth.user.uid : '';
      // Switch filter to 'all' so every ride shows by default
      context.read<HomeBloc>()
        ..add(HomeLoadRequested(userLat: _lat, userLng: _lng, userId: uid))
        ..add(const HomeDateFilterChanged('all'));
    });
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
          'All Rides',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            );
          }
          if (state is! HomeLoaded) return const SizedBox.shrink();

          final rides = state.filteredRides;
          final drivers = state.drivers;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            context.read<HomeBloc>().add(HomeSearchChanged(v)),
                        decoration: const InputDecoration(
                          hintText: 'Search by arrival city...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Chip(
                            label: 'All',
                            active: state.dateFilter == 'all',
                            onTap: () => context.read<HomeBloc>().add(
                              const HomeDateFilterChanged('all'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            label: 'Today',
                            active: state.dateFilter == 'today',
                            onTap: () => context.read<HomeBloc>().add(
                              const HomeDateFilterChanged('today'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            label: 'Tomorrow',
                            active: state.dateFilter == 'tomorrow',
                            onTap: () => context.read<HomeBloc>().add(
                              const HomeDateFilterChanged('tomorrow'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            label: 'Group',
                            icon: Icons.group_outlined,
                            active: state.dateFilter == 'group',
                            onTap: () => context.read<HomeBloc>().add(
                              const HomeDateFilterChanged('group'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${rides.length} ride${rides.length != 1 ? 's' : ''} found',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: rides.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              color: AppColors.textMuted,
                              size: 52,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No rides match your search.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: rides.length,
                        itemBuilder: (context, i) {
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
                            onBook: () => context.push(
                              '${AppRoutes.tripDetail}/${ride.id}',
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  const _Chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: active ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
