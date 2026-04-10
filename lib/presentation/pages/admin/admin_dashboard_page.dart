import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/ride_report.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../injection/service_locator.dart';
import '../../widgets/shared_widgets.dart';
import '../../blocs/blocs.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBloc>().add(const AdminStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: const RideLeafAppBar(
        title: 'Admin Dashboard',
        showLogo: false,
        showBack: true,
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminLoaded) {
            return _buildContent(context, state);
          }
          return const Center(child: Text('Unable to load admin dashboard.'));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminLoaded state) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated || !authState.user.isAdmin) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Administrator access is required to view this page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildStatsSection(state),
            const SizedBox(height: 20),
            _buildAdminActionsSection(context),
            const SizedBox(height: 20),
            _buildApprovalSection(context, state),
            const SizedBox(height: 20),
            _buildReportsSection(context, state),
            const SizedBox(height: 20),
            _buildDisputesSection(context, state),
          ],
        );
      },
    );
  }

  Widget _buildAdminActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Actions',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.adminTrips),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Manage trips',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.createRide),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Create trip',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(AdminLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Statistics',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DashboardCard(
              label: 'Revenue',
              value: '${state.totalRevenue.toStringAsFixed(2)}DT',
              icon: Icons.attach_money_rounded,
            ),
            _DashboardCard(
              label: 'Total Rides',
              value: state.totalRides.toString(),
              icon: Icons.directions_car_rounded,
            ),
            _DashboardCard(
              label: 'Completed',
              value: state.completedRides.toString(),
              icon: Icons.check_circle_outline_rounded,
            ),
            _DashboardCard(
              label: 'Pending Approvals',
              value: state.pendingApprovals.toString(),
              icon: Icons.hourglass_bottom_rounded,
            ),
            _DashboardCard(
              label: 'Disputes',
              value: state.disputeCount.toString(),
              icon: Icons.gavel_rounded,
            ),
            _DashboardCard(
              label: 'Commission',
              value: '${state.totalCommission.toStringAsFixed(2)}DT',
              icon: Icons.account_balance_wallet_rounded,
            ),
            _DashboardCard(
              label: 'Reported Drivers',
              value: state.reportedDriverCount.toString(),
              icon: Icons.report_problem_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApprovalSection(BuildContext context, AdminLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Driver Requests',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (state.pendingDrivers.isEmpty)
          const Text(
            'No pending driver verifications at the moment.',
            style: TextStyle(color: AppColors.textMuted),
          )
        else
          Column(
            children: state.pendingDrivers.map((driver) {
              return _AdminDriverTile(
                driver: driver,
                isBanned: driver.isCurrentlyBanned,
                onViewProfile: () =>
                    context.push(AppRoutes.adminUserInfo, extra: driver),
                onApprove: () {
                  context.read<AdminBloc>().add(
                    AdminApproveDriverRequested(userId: driver.uid),
                  );
                },
                onBanTemporary: () {
                  context.read<AdminBloc>().add(
                    AdminBanDriverRequested(
                      userId: driver.uid,
                      until: DateTime.now().toUtc().add(
                        const Duration(days: 7),
                      ),
                    ),
                  );
                },
                onBanPermanent: () {
                  context.read<AdminBloc>().add(
                    AdminBanDriverRequested(
                      userId: driver.uid,
                      indefinite: true,
                    ),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildReportsSection(BuildContext context, AdminLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reported Drivers',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (state.reportedDrivers.isEmpty)
          const Text(
            'No reported drivers currently.',
            style: TextStyle(color: AppColors.textMuted),
          )
        else
          Column(
            children: state.reportedDrivers.map((driver) {
              return _AdminDriverTile(
                driver: driver,
                reportCount: driver.reportCount,
                isBanned: driver.isCurrentlyBanned,
                onViewProfile: () =>
                    context.push(AppRoutes.adminUserInfo, extra: driver),
                onBanTemporary: () {
                  context.read<AdminBloc>().add(
                    AdminBanDriverRequested(
                      userId: driver.uid,
                      until: DateTime.now().toUtc().add(
                        const Duration(days: 7),
                      ),
                    ),
                  );
                },
                onBanPermanent: () {
                  context.read<AdminBloc>().add(
                    AdminBanDriverRequested(
                      userId: driver.uid,
                      indefinite: true,
                    ),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDisputesSection(BuildContext context, AdminLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disputes & Complaints',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (state.reportedRideReports.isEmpty)
          const Text(
            'No active ride disputes at the moment.',
            style: TextStyle(color: AppColors.textMuted),
          )
        else
          Column(
            children: state.reportedRideReports.map((report) {
              return _AdminReportTile(
                report: report,
                onResolve: () {
                  context.read<AdminBloc>().add(
                    AdminResolveReportRequested(reportId: report.id),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DashboardCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 28,
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
          Icon(icon, size: 24, color: AppColors.orange),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDriverTile extends StatelessWidget {
  final AppUser driver;
  final int? reportCount;
  final bool isBanned;
  final VoidCallback? onApprove;
  final VoidCallback? onViewProfile;
  final VoidCallback? onBanTemporary;
  final VoidCallback? onBanPermanent;

  const _AdminDriverTile({
    required this.driver,
    this.reportCount,
    this.isBanned = false,
    this.onApprove,
    this.onViewProfile,
    this.onBanTemporary,
    this.onBanPermanent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.forestGreen.withOpacity(0.15),
                child: Text(
                  driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.email,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reportCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Reports: $reportCount',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onViewProfile != null)
                ElevatedButton(
                  onPressed: onViewProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              if (onApprove != null)
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              if (onBanTemporary != null)
                OutlinedButton(
                  onPressed: isBanned ? null : onBanTemporary,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isBanned
                        ? AppColors.textMuted
                        : AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Ban 7 days'),
                ),
              if (onBanPermanent != null)
                OutlinedButton(
                  onPressed: isBanned ? null : onBanPermanent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isBanned
                        ? AppColors.textMuted
                        : AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Ban permanently'),
                ),
            ],
          ),
          if (isBanned)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Already banned',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminReportTile extends StatelessWidget {
  final RideReport report;
  final VoidCallback onResolve;

  const _AdminReportTile({required this.report, required this.onResolve});

  Future<String> _resolveUserName(String uid) async {
    final user = await sl<UserRepository>().getUserById(uid);
    if (user == null) return uid;
    return user.name.isNotEmpty ? user.name : uid;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.error.withOpacity(0.15),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reason,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<List<String>>(
                      future: Future.wait([
                        _resolveUserName(report.reporterId),
                        _resolveUserName(report.driverId),
                      ]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Text(
                            'Ride loading user info...',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          );
                        }

                        final names = snapshot.data ?? [];
                        final reporterName = names.isNotEmpty
                            ? names[0]
                            : report.reporterId;
                        final driverName = names.length > 1
                            ? names[1]
                            : report.driverId;
                        return Text(
                          'Ride ${report.rideId} • Reporter $reporterName • Driver $driverName',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report.details != null && report.details!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              report.details!,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onResolve,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Resolve',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
