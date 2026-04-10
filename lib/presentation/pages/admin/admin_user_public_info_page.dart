import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/app_user.dart';
import '../../widgets/shared_widgets.dart';

class AdminUserPublicInfoPage extends StatelessWidget {
  final AppUser user;

  const AdminUserPublicInfoPage({super.key, required this.user});

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.driver:
        return 'Driver';
      case UserRole.passenger:
        return 'Passenger';
    }
  }

  String _verificationLabel(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.unverified:
        return 'Unverified';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: const RideLeafAppBar(
        title: 'User Profile',
        showBack: true,
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _roleLabel(user.role),
                    style: const TextStyle(
                      color: AppColors.forestGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Email', user.email),
                  _buildInfoRow(
                    'Phone',
                    user.phone.isNotEmpty ? user.phone : 'Not provided',
                  ),
                  _buildInfoRow(
                    'Banned',
                    user.isCurrentlyBanned ? 'Yes' : 'No',
                  ),
                  _buildInfoRow(
                    'Verification',
                    _verificationLabel(user.verification),
                  ),
                  _buildInfoRow('Reports', user.reportCount.toString()),
                  _buildInfoRow(
                    'CO2 Saved',
                    '${user.co2SavedKg.toStringAsFixed(1)} kg',
                  ),
                  _buildInfoRow(
                    'Distance',
                    '${user.distanceSharedKm.toStringAsFixed(1)} km',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
