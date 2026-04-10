import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/driver_location.dart';
import '../../../domain/entities/ride.dart';
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
  final _sheetController = DraggableScrollableController();

  // Track which driver was last tapped so second tap navigates
  String? _lastTappedDriverId;

  /// Same pattern for trip markers (departure pins).
  String? _lastTappedRideId;
  bool _didCenterOnUser = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onDriverTap(MapLoaded state, DriverLocation driver) {
    _lastTappedRideId = null;
    if (_lastTappedDriverId == driver.driverId &&
        state.selectedDriver?.driverId == driver.driverId) {
      // Second tap on same driver → navigate to trip detail
      if (driver.rideId != null) {
        context.push('${AppRoutes.tripDetail}/${driver.rideId}');
      }
    } else {
      // First tap → select driver, fetch route, animate map
      _lastTappedDriverId = driver.driverId;
      context.read<MapBloc>().add(MapDriverSelected(driver));
      _mapController.move(LatLng(driver.latitude, driver.longitude), 12.5);
      // Expand sheet slightly to show callout details
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.30,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onTripMarkerTap(MapLoaded state, Ride ride) {
    _lastTappedDriverId = null;
    if (_lastTappedRideId == ride.id && state.selectedRideId == ride.id) {
      context.push('${AppRoutes.tripDetail}/${ride.id}');
    } else {
      _lastTappedRideId = ride.id;
      context.read<MapBloc>().add(MapRideSelected(ride));
      _mapController.move(
        LatLng(ride.departure.latitude, ride.departure.longitude),
        12.5,
      );
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.30,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: RideLeafAppBar(
        onNotificationTap: () => context.push(AppRoutes.notifications),
        avatarUrl: '',
      ),
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state is MapLoaded && !_didCenterOnUser) {
            _mapController.move(LatLng(state.userLat, state.userLng), 12);
            _didCenterOnUser = true;
          }
          if (state is MapLoading) {
            _didCenterOnUser = false;
          }
        },
        builder: (context, state) {
          final isLoaded = state is MapLoaded;
          final userLat = isLoaded ? state.userLat : 36.8065;
          final userLng = isLoaded ? state.userLng : 10.1815;
          final drivers = isLoaded ? state.nearbyDrivers : <DriverLocation>[];
          // Use filteredRides getter — applies search query
          final rides = isLoaded ? state.filteredRides : <Ride>[];
          final allRides = isLoaded ? state.nearbyRides : <Ride>[];
          final selected = isLoaded ? state.selectedDriver : null;
          final selectedRideId = isLoaded ? state.selectedRideId : null;
          final polyline = isLoaded ? state.routePolyline : <List<double>>[];
          final mapFilter = isLoaded ? state.mapFilter : MapFilter.defaults;
          Ride? selectedRideForPins;
          if (isLoaded && selected == null && selectedRideId != null) {
            for (final r in allRides) {
              if (r.id == selectedRideId) {
                selectedRideForPins = r;
                break;
              }
            }
          }

          return Stack(
            children: [
              // ── Full screen map
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(userLat, userLng),
                    initialZoom: 12,
                    onTap: (_, __) {
                      context.read<MapBloc>().add(const MapDriverDeselected());
                      _lastTappedDriverId = null;
                      _lastTappedRideId = null;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rideleaf.app',
                    ),

                    // ── Selected trip road route polyline
                    if (polyline.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: polyline
                                .map((p) => LatLng(p[0], p[1]))
                                .toList(),
                            strokeWidth: 5,
                            color: AppColors.forestGreen.withOpacity(0.85),
                            borderStrokeWidth: 2,
                            borderColor: Colors.white,
                          ),
                        ],
                      ),

                    // ── Departure & Arrival pins when route active
                    if (polyline.isNotEmpty &&
                        (selected != null || selectedRideForPins != null))
                      MarkerLayer(
                        markers: [
                          if (selected != null && selected.departureLat != null)
                            Marker(
                              point: LatLng(
                                selected.departureLat!,
                                selected.departureLng!,
                              ),
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            )
                          else if (selectedRideForPins != null)
                            Marker(
                              point: LatLng(
                                selectedRideForPins.departure.latitude,
                                selectedRideForPins.departure.longitude,
                              ),
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          if (selected != null && selected.arrivalLat != null)
                            Marker(
                              point: LatLng(
                                selected.arrivalLat!,
                                selected.arrivalLng!,
                              ),
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            )
                          else if (selectedRideForPins != null)
                            Marker(
                              point: LatLng(
                                selectedRideForPins.arrival.latitude,
                                selectedRideForPins.arrival.longitude,
                              ),
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),

                    // ── User location dot
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

                    // ── Trip departure markers (filtered trips)
                    if (state is MapLoaded && rides.isNotEmpty)
                      MarkerLayer(
                        markers: rides.map((ride) {
                          final isTripSel = selectedRideId == ride.id;
                          return Marker(
                            point: LatLng(
                              ride.departure.latitude,
                              ride.departure.longitude,
                            ),
                            width: 46,
                            height: 46,
                            child: GestureDetector(
                              onTap: () => _onTripMarkerTap(state, ride),
                              child: _TripDepartureMarker(
                                isSelected: isTripSel,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    // ── Driver markers (live position)
                    MarkerLayer(
                      markers: drivers.map((d) {
                        final isSel = selected?.driverId == d.driverId;
                        return Marker(
                          point: LatLng(d.latitude, d.longitude),
                          width: 64,
                          height: 64,
                          child: GestureDetector(
                            onTap: () =>
                                isLoaded ? _onDriverTap(state, d) : null,
                            child: _DriverMarker(driver: d, isSelected: isSel),
                          ),
                        );
                      }).toList(),
                    ),

                    // ── Callout bubble on first tap
                    if (selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              selected.latitude + 0.005,
                              selected.longitude,
                            ),
                            width: 240,
                            height: 85,
                            child: GestureDetector(
                              onTap: () {
                                if (selected.rideId != null) {
                                  context.push(
                                    '${AppRoutes.tripDetail}/${selected.rideId}',
                                  );
                                }
                              },
                              child: _DriverCallout(driver: selected),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ── Search bar
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
                    onChanged: (v) =>
                        context.read<MapBloc>().add(MapSearchChanged(v)),
                    decoration: InputDecoration(
                      hintText: 'Search by destination...',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                context.read<MapBloc>().add(
                                  const MapSearchChanged(''),
                                );
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textMuted,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              // ── Second-tap hint badge
              if ((selected != null && selected.rideId != null) ||
                  (selectedRideId != null && polyline.isNotEmpty))
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tap again to view trip details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Bottom sheet
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.28,
                minChildSize: 0.10,
                maxChildSize: 0.88,
                snap: true,
                snapSizes: const [0.10, 0.28, 0.55, 0.88],
                builder: (context, scrollCtrl) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: CustomScrollView(
                      controller: scrollCtrl,
                      slivers: [
                        // ── Sheet header (sticky)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SheetHeader(
                            rideCount: allRides.length,
                            filteredCount: rides.length,
                            searchQuery: isLoaded ? state.searchQuery : '',
                            radiusKm: mapFilter.radiusKm,
                            hasPreferenceFilters:
                                mapFilter.requiredPreferenceTags.isNotEmpty,
                            hasPriceCap: mapFilter.maxPricePerSeat != null,
                            onClearSearch: () {
                              _searchCtrl.clear();
                              context.read<MapBloc>().add(
                                const MapSearchChanged(''),
                              );
                            },
                            onFilter: () => _showFilterSheet(context, state),
                          ),
                        ),

                        // ── Ride cards
                        if (state is MapLoading)
                          const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.forestGreen,
                              ),
                            ),
                          )
                        else if (rides.isEmpty && allRides.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.all(32),
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
                                    'No nearby rides right now.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (rides.isEmpty && allRides.isNotEmpty)
                          SliverFillRemaining(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    color: AppColors.textMuted,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No rides to "${isLoaded ? state.searchQuery : ''}".',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final ride = rides[i];
                                final isSel = selectedRideId == ride.id;
                                return _RideSheetCard(
                                  ride: ride,
                                  isHighlighted: isSel,
                                  onTap: () {
                                    if (isSel) {
                                      context.push(
                                        '${AppRoutes.tripDetail}/${ride.id}',
                                      );
                                      return;
                                    }
                                    context.read<MapBloc>().add(
                                      MapRideSelected(ride),
                                    );
                                    _mapController.move(
                                      LatLng(
                                        ride.departure.latitude,
                                        ride.departure.longitude,
                                      ),
                                      12.5,
                                    );
                                    if (_sheetController.isAttached) {
                                      _sheetController.animateTo(
                                        0.30,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                );
                              }, childCount: rides.length),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              if (state is MapPermissionDenied)
                Positioned(
                  top: 128,
                  left: 16,
                  right: 16,
                  child: _MapNoticeBanner(
                    icon: Icons.location_off_rounded,
                    message:
                        'Location permission denied. Showing trips near default position.',
                  ),
                ),
              if (state is MapError)
                Positioned(
                  top: 128,
                  left: 16,
                  right: 16,
                  child: _MapNoticeBanner(
                    icon: Icons.warning_amber_rounded,
                    message: state.message,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context, MapState state) {
    if (state is! MapLoaded) {
      return;
    }
    final mapBloc = context.read<MapBloc>();
    final initial = state.mapFilter;
    var radius = initial.radiusKm;
    final prefs = Set<String>.from(initial.requiredPreferenceTags);
    var capPrice = initial.maxPricePerSeat != null;
    var maxPrice = initial.maxPricePerSeat ?? 50.0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter nearby trips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              radius = kDefaultMapRadiusKm;
                              prefs.clear();
                              capPrice = false;
                              maxPrice = 50;
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: AppColors.forestGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search radius: ${radius.round()} km',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    Slider(
                      value: radius.clamp(5, 100),
                      min: 5,
                      max: 100,
                      divisions: 19,
                      activeColor: AppColors.forestGreen,
                      onChanged: (v) => setModalState(() => radius = v),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trip preferences',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Show rides that include all selected tags.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterPrefChip(
                          label: 'Non-smoking',
                          icon: Icons.smoke_free_rounded,
                          selected: prefs.contains('no_smoking'),
                          onTap: () => setModalState(() {
                            if (prefs.contains('no_smoking')) {
                              prefs.remove('no_smoking');
                            } else {
                              prefs.add('no_smoking');
                            }
                          }),
                        ),
                        _FilterPrefChip(
                          label: 'Pets OK',
                          icon: Icons.pets_outlined,
                          selected: prefs.contains('pets_welcome'),
                          onTap: () => setModalState(() {
                            if (prefs.contains('pets_welcome')) {
                              prefs.remove('pets_welcome');
                            } else {
                              prefs.add('pets_welcome');
                            }
                          }),
                        ),
                        _FilterPrefChip(
                          label: 'Luggage',
                          icon: Icons.luggage_outlined,
                          selected: prefs.contains('medium_bag'),
                          onTap: () => setModalState(() {
                            if (prefs.contains('medium_bag')) {
                              prefs.remove('medium_bag');
                            } else {
                              prefs.add('medium_bag');
                            }
                          }),
                        ),
                        _FilterPrefChip(
                          label: 'Quiet',
                          icon: Icons.volume_off_outlined,
                          selected: prefs.contains('quiet_trip'),
                          onTap: () => setModalState(() {
                            if (prefs.contains('quiet_trip')) {
                              prefs.remove('quiet_trip');
                            } else {
                              prefs.add('quiet_trip');
                            }
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Max price per seat'),
                      subtitle: const Text(
                        'Hide rides above this price',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: capPrice,
                      activeThumbColor: AppColors.forestGreen,
                      onChanged: (v) => setModalState(() {
                        capPrice = v;
                        if (!v) {
                          maxPrice = 50;
                        }
                      }),
                    ),
                    if (capPrice) ...[
                      Text(
                        'Up to ${maxPrice.toStringAsFixed(0)} DT / seat',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      Slider(
                        value: maxPrice.clamp(1, 200),
                        min: 1,
                        max: 200,
                        divisions: 199,
                        activeColor: AppColors.forestGreen,
                        onChanged: (v) => setModalState(() => maxPrice = v),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          mapBloc.add(
                            MapFiltersChanged(
                              MapFilter(
                                radiusKm: radius,
                                requiredPreferenceTags: Set<String>.from(prefs),
                                maxPricePerSeat: capPrice ? maxPrice : null,
                              ),
                            ),
                          );
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text(
                          'Apply filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterPrefChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPrefChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : AppColors.textDark,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.forestGreen,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

class _MapNoticeBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  const _MapNoticeBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Persistent sheet header delegate ─────────────────────────────────────────

class _SheetHeader extends SliverPersistentHeaderDelegate {
  final int rideCount;
  final int filteredCount;
  final String searchQuery;
  final double radiusKm;
  final bool hasPreferenceFilters;
  final bool hasPriceCap;
  final VoidCallback onClearSearch;
  final VoidCallback onFilter;

  const _SheetHeader({
    required this.rideCount,
    required this.filteredCount,
    required this.searchQuery,
    required this.radiusKm,
    required this.hasPreferenceFilters,
    required this.hasPriceCap,
    required this.onClearSearch,
    required this.onFilter,
  });

  @override
  double get minExtent => 110;
  @override
  double get maxExtent => 110;
  @override
  bool shouldRebuild(_SheetHeader old) =>
      old.rideCount != rideCount ||
      old.filteredCount != filteredCount ||
      old.searchQuery != searchQuery ||
      old.radiusKm != radiusKm ||
      old.hasPreferenceFilters != hasPreferenceFilters ||
      old.hasPriceCap != hasPriceCap;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final kmLabel = radiusKm == radiusKm.roundToDouble()
        ? radiusKm.toStringAsFixed(0)
        : radiusKm.toStringAsFixed(1);
    final title = searchQuery.isNotEmpty
        ? '$filteredCount of $rideCount trips'
        : rideCount == 0
        ? 'No trips in range'
        : '$rideCount trip${rideCount != 1 ? 's' : ''} · $kmLabel km';
    final filterActive =
        (radiusKm - kDefaultMapRadiusKm).abs() > 0.01 ||
        hasPreferenceFilters ||
        hasPriceCap;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 12),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  if (searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: onClearSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.close_rounded,
                              color: AppColors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              searchQuery,
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onFilter,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Filter',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (filterActive)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trip departure marker (on map) ───────────────────────────────────────────

class _TripDepartureMarker extends StatelessWidget {
  final bool isSelected;
  const _TripDepartureMarker({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.orange : AppColors.forestGreen,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
        ],
      ),
      child: Icon(
        Icons.directions_car_rounded,
        color: isSelected ? AppColors.orange : AppColors.forestGreen,
        size: 22,
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

// ── Driver callout ────────────────────────────────────────────────────────────

class _DriverCallout extends StatelessWidget {
  final DriverLocation driver;
  const _DriverCallout({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: AppColors.forestGreen,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${driver.departure ?? '—'} → ${driver.destination ?? '—'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${driver.departureTime ?? '--:--'}  •  ${driver.seatsLeft} seats  ',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (driver.pricePerSeat != null)
                Text(
                  '${driver.pricePerSeat!.toStringAsFixed(0)} DT',
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          const Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: AppColors.textMuted,
                size: 11,
              ),
              SizedBox(width: 3),
              Text(
                'Tap again for details',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ride sheet card ───────────────────────────────────────────────────────────

class _RideSheetCard extends StatelessWidget {
  final Ride ride;
  final bool isHighlighted;
  final VoidCallback onTap;
  const _RideSheetCard({
    required this.ride,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.forestGreen.withOpacity(0.06)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.forestGreen.withOpacity(0.4),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'STARTS ${DateFormat('HH:mm').format(ride.dateHour)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ride.departureAddress.isNotEmpty ? ride.departureAddress : 'Departure'}'
                    ' → '
                    '${ride.arrivalAddress.isNotEmpty ? ride.arrivalAddress : 'Arrival'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EDDA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CO2: ${(ride.availableSeats * 2.4).toStringAsFixed(1)}kg',
                          style: const TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ride.seatsLeft} seats left',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ride.pricePerPassenger.toStringAsFixed(0)} DT',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  'PER SEAT',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Container(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
