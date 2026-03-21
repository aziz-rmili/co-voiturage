import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/driver_location.dart';
import '../../blocs/map_bloc.dart';
import '../../widgets/shared_widgets.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MapBloc>().add(const MapInitialized());
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
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          final isLoaded = state is MapLoaded;
          final userLat = isLoaded ? state.userLat : 36.8065;
          final userLng = isLoaded ? state.userLng : 10.1815;
          final drivers = isLoaded ? state.nearbyDrivers : <DriverLocation>[];
          final selected = isLoaded ? state.selectedDriver : null;

          return Stack(
            children: [
              // ── Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(userLat, userLng),
                  initialZoom: 13,
                  onTap: (_, __) =>
                      context.read<MapBloc>().add(const MapDriverDeselected()),
                ),
                children: [
                  // OSM tile layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rideleaf.app',
                  ),

                  // User location marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(userLat, userLng),
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Driver markers
                  MarkerLayer(
                    markers: drivers
                        .map(
                          (d) => Marker(
                            point: LatLng(d.latitude, d.longitude),
                            width: 60,
                            height: 60,
                            child: GestureDetector(
                              onTap: () => context.read<MapBloc>().add(
                                MapDriverSelected(d),
                              ),
                              child: _DriverMarker(
                                driver: d,
                                isSelected: selected?.driverId == d.driverId,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  // Selected driver callout
                  if (selected != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            selected.latitude + 0.003,
                            selected.longitude,
                          ),
                          width: 220,
                          height: 70,
                          child: _DriverCallout(driver: selected),
                        ),
                      ],
                    ),
                ],
              ),

              // ── Search bar overlay
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Where to?',
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

              // ── Bottom sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _NearbyTripsSheet(
                  driverCount: drivers.length,
                  onBook: (rideId) =>
                      context.push('${AppRoutes.tripDetail}/$rideId'),
                ),
              ),

              // ── Loading overlay
              if (state is MapLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}

// ── Driver marker ─────────────────────────────────────────────────────────────

class _DriverMarker extends StatelessWidget {
  final DriverLocation driver;
  final bool isSelected;

  const _DriverMarker({required this.driver, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.orange : AppColors.forestGreen,
          width: isSelected ? 3 : 2,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withOpacity(0.3),
            blurRadius: isSelected ? 16 : 8,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: const Color(0xFFD4EDDA),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.forestGreen,
            size: 28,
          ),
        ),
      ),
    );
  }
}

// ── Driver callout bubble ─────────────────────────────────────────────────────

class _DriverCallout extends StatelessWidget {
  final DriverLocation driver;
  const _DriverCallout({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'To ${driver.destination ?? 'Unknown'}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${driver.departureTime ?? '--:--'} • ${driver.seatsLeft} SEATS LEFT',
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nearby trips bottom sheet ─────────────────────────────────────────────────

class _NearbyTripsSheet extends StatelessWidget {
  final int driverCount;
  final void Function(String rideId) onBook;

  const _NearbyTripsSheet({required this.driverCount, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NEARBY TRIPS',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${driverCount > 0 ? driverCount : 3} Drivers found\nnearby',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Filter',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ride card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'STARTS 8:45 AM',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nabeul - Sousse',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 6),
                      _Co2Badge(text: 'CO2 SAVED: 7.6KG'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '16 DT',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Text(
                      'PER SEAT',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => onBook('seed_ride_1'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brownOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Co2Badge extends StatelessWidget {
  final String text;
  const _Co2Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.forestGreen,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
