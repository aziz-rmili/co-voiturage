import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ── Top AppBar ────────────────────────────────────────────────────────────────

class RideLeafAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showBack;
  final Widget? trailing;
  final VoidCallback? onNotificationTap;
  final String? avatarUrl;

  const RideLeafAppBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.showBack = false,
    this.trailing,
    this.onNotificationTap,
    this.avatarUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: showBack
          ? Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.forestGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title ?? '',
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            )
          : showLogo
          ? RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Ride',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'Leaf',
                    style: TextStyle(
                      color: AppColors.forestGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          : null,
      actions: [
        if (onNotificationTap != null)
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textDark,
              size: 24,
            ),
            onPressed: onNotificationTap,
          ),
        if (avatarUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!) as ImageProvider
                  : null,
              backgroundColor: AppColors.forestGreen.withOpacity(0.2),
              child: avatarUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: AppColors.forestGreen,
                      size: 18,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

// ── Bottom Nav Bar ────────────────────────────────────────────────────────────

class RideLeafBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const RideLeafBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECE9), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.search_rounded,
                label: 'SEARCH',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.directions_car_outlined,
                label: 'MY TRIPS',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.map_outlined,
                label: 'MAP',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'MESSAGES',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'PROFILE',
                active: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.forestGreen : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final bool dark;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.dark = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.forestGreen : const Color(0xFFD4EDDA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: dark ? Colors.white70 : AppColors.forestGreen,
              size: 20,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: dark ? Colors.white60 : AppColors.forestGreen,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: dark ? Colors.white : AppColors.forestGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      color: dark ? Colors.white70 : AppColors.forestGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ride Route Card ───────────────────────────────────────────────────────────

class RideRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final String driverName;
  final double driverRating;
  final int driverTrips;
  final double price;
  final String currency;
  final VoidCallback onBook;
  final String? avatarUrl;

  const RideRouteCard({
    super.key,
    required this.from,
    required this.to,
    required this.driverName,
    required this.driverRating,
    required this.driverTrips,
    required this.price,
    this.currency = 'DT',
    required this.onBook,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.forestGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppColors.textMuted.withOpacity(0.3),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.orange, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      to,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${price.toStringAsFixed(0)} $currency',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: (avatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(avatarUrl!) as ImageProvider
                    : null,
                backgroundColor: AppColors.forestGreen.withOpacity(0.15),
                child: (avatarUrl?.isEmpty ?? true)
                    ? const Icon(
                        Icons.person,
                        color: AppColors.forestGreen,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$driverRating • $driverTrips trips',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onBook,
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
                    'Book Seat',
                    style: TextStyle(
                      color: AppColors.orange,
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
