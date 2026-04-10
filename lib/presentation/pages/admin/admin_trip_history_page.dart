import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repositories/ride_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../blocs/admin_bloc.dart';
import '../../widgets/shared_widgets.dart';
import '/injection/service_locator.dart';

class AdminTripHistoryPage extends StatelessWidget {
  const AdminTripHistoryPage({super.key});

  Future<void> _deleteRide(BuildContext context, String rideId) async {
    try {
      await sl<RideRepository>().deleteRide(rideId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip deleted successfully.'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _viewUser(BuildContext context, String userId) async {
    try {
      final user = await sl<UserRepository>().getUserById(userId);
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        context.push(AppRoutes.adminUserInfo, extra: user);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showPassengers(
    BuildContext context,
    List<String> passengerIds,
  ) async {
    if (passengerIds.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No passengers to show.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<AppUser>>(
          future: sl<UserRepository>().getUsersByIds(passengerIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AlertDialog(
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final users = snapshot.data ?? [];
            return AlertDialog(
              title: const Text('Passenger profiles'),
              content: SizedBox(
                width: double.maxFinite,
                child: users.isEmpty
                    ? const Text('No public passenger data available.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final passenger = users[index];
                          return ListTile(
                            title: Text(passenger.name),
                            subtitle: Text(passenger.email),
                            trailing: TextButton(
                              onPressed: () {
                                context.pop();
                                context.push(
                                  AppRoutes.adminUserInfo,
                                  extra: passenger,
                                );
                              },
                              child: const Text('View'),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: const RideLeafAppBar(
        title: 'Trips History',
        showBack: true,
        showLogo: false,
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminLoaded) {
            final rides = state.allRides;
            if (rides.isEmpty) {
              return const Center(child: Text('No trips found.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: rides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ride = rides[index];
                return _AdminRideCard(
                  ride: ride,
                  onDelete: () => _deleteRide(context, ride.id),
                  onViewDriver: () => _viewUser(context, ride.driverId),
                  onViewPassengers: () =>
                      _showPassengers(context, ride.passengersIds),
                );
              },
            );
          }
          return const Center(child: Text('Unable to load trips.'));
        },
      ),
    );
  }
}

class _AdminRideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onDelete;
  final VoidCallback onViewDriver;
  final VoidCallback onViewPassengers;

  const _AdminRideCard({
    required this.ride,
    required this.onDelete,
    required this.onViewDriver,
    required this.onViewPassengers,
  });

  String get _statusLabel {
    switch (ride.status) {
      case RideStatus.scheduled:
        return 'Scheduled';
      case RideStatus.active:
        return 'Active';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${ride.departureAddress.isNotEmpty ? ride.departureAddress : 'Departure'} → ${ride.arrivalAddress.isNotEmpty ? ride.arrivalAddress : 'Arrival'}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            DateFormat.yMMMd().add_jm().format(ride.dateHour.toLocal()),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seats: ${ride.availableSeats} • Booked: ${ride.confirmedPassengerIds.length} • Left: ${ride.seatsLeft}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${ride.pricePerPassenger.toStringAsFixed(2)}DT',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: onViewDriver,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('View driver'),
              ),
              OutlinedButton(
                onPressed: onViewPassengers,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Passengers (${ride.passengersIds.length})'),
              ),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Delete trip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
