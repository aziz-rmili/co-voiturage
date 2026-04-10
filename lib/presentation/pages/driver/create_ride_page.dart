import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/ride_repository.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/rideleaf_button.dart';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key});
  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  _PlaceResult? _departure;
  _PlaceResult? _arrival;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 30);
  int _seats = 3;
  double _pricePerSeat = 12.50;
  final _notesCtrl = TextEditingController();
  bool _isPublishing = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _potentialEarnings => _pricePerSeat * _seats;
  double get _co2Saved => _seats * 2.4;
  DateTime get _dateTime =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.forestGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.forestGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _publish() async {
    if (_departure == null) {
      _snack('Please choose a departure location.');
      return;
    }
    if (_arrival == null) {
      _snack('Please choose a destination.');
      return;
    }
    setState(() => _isPublishing = true);
    final auth = context.read<AuthBloc>().state;
    final uid = auth is AuthAuthenticated ? auth.user.uid : '';
    final ride = Ride(
      id: '',
      driverId: uid,
      departure: GeoPoint(_departure!.lat, _departure!.lng),
      arrival: GeoPoint(_arrival!.lat, _arrival!.lng),
      departureAddress: _departure!.displayName,
      arrivalAddress: _arrival!.displayName,
      dateHour: _dateTime,
      availableSeats: _seats,
      pricePerPassenger: _pricePerSeat,
      pendingPassengerIds: const [],
      confirmedPassengerIds: const [],
      status: RideStatus.scheduled,
      note: _notesCtrl.text.trim(),
    );
    try {
      await context.read<RideRepository>().createRide(ride);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip published! 🌿'),
            backgroundColor: AppColors.forestGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        _snack(e.toString());
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isToday =
        _date.day == DateTime.now().day && _date.month == DateTime.now().month;
    final peakLabel = _time.hour < 10
        ? 'Morning Peak'
        : _time.hour < 14
        ? 'Midday'
        : _time.hour < 18
        ? 'Afternoon'
        : 'Evening';

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
          'New Journey',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textMuted,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Details',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // ── Departure + Destination
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _LocationField(
                    label: 'DEPARTURE',
                    icon: Icons.my_location_rounded,
                    iconColor: AppColors.forestGreen,
                    placeholder: 'Where are you leaving from?',
                    value: _departure?.displayName,
                    onPicked: (p) => setState(() => _departure = p),
                  ),
                  const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: Color(0xFFF0F0F0),
                  ),
                  _LocationField(
                    label: 'DESTINATION',
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.orange,
                    placeholder: 'Where are you headed?',
                    value: _arrival?.displayName,
                    onPicked: (p) => setState(() => _arrival = p),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Date + Time
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: _InfoCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.forestGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATE',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isToday
                                    ? 'Today'
                                    : DateFormat('MMM d').format(_date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy').format(_date),
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: _InfoCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.forestGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIME',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _time.format(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                peakLabel,
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
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Available Seats
            _InfoCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Seats',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Max 4 passengers',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SeatButton(
                    icon: Icons.remove,
                    onTap: () => setState(() {
                      if (_seats > 1) _seats--;
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_seats',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  _SeatButton(
                    icon: Icons.add,
                    filled: true,
                    onTap: () => setState(() {
                      if (_seats < 4) _seats++;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Price + Earnings
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'PRICE PER SEAT',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'POTENTIAL EARNINGS',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_pricePerSeat.toStringAsFixed(2)}DT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_potentialEarnings.toStringAsFixed(2)}DT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _pricePerSeat,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (v) => setState(() => _pricePerSeat = v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Notes
            const Text(
              'Notes (Optionnel)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share any extra details about the trip...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Environmental Contribution
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: AppColors.forestGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Environmental Contribution\n',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const TextSpan(
                            text: 'This trip will save approximately ',
                          ),
                          TextSpan(
                            text: '${_co2Saved.toStringAsFixed(1)}kg of CO2',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          const TextSpan(text: ' emissions.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: RideLeafButton(
          label: 'Publish Trip',
          onPressed: _publish,
          isLoading: _isPublishing,
          icon: Icons.check_rounded,
        ),
      ),
    );
  }
}

// ── Shared card wrapper ───────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
      ],
    ),
    child: child,
  );
}

// ── Location field ────────────────────────────────────────────────────────────
class _LocationField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String placeholder;
  final String? value;
  final ValueChanged<_PlaceResult> onPicked;
  const _LocationField({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.placeholder,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final r = await showModalBottomSheet<_PlaceResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LocationSearchSheet(label: label),
      );
      if (r != null) onPicked(r);
    },
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value ?? placeholder,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: value != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: value != null
                        ? AppColors.textDark
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Location search sheet with Nominatim ──────────────────────────────────────
class _LocationSearchSheet extends StatefulWidget {
  final String label;
  const _LocationSearchSheet({required this.label});
  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _ctrl = TextEditingController();
  List<_PlaceResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&countrycodes=tn&limit=8&addressdetails=1',
      );
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'RideLeafApp/1.0 (contact@rideleaf.app)',
          'Accept-Language': 'en',
        },
      );
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        setState(() {
          _results = list.map((item) {
            final addr = item['address'] as Map<String, dynamic>? ?? {};
            final city =
                addr['city'] ??
                addr['town'] ??
                addr['village'] ??
                addr['suburb'] ??
                addr['county'] ??
                '';
            final state = addr['state'] ?? '';
            final road = addr['road'] ?? '';
            final shortName = road.isNotEmpty
                ? '$road${city.isNotEmpty ? ", $city" : ""}'
                : (city.isNotEmpty
                      ? (state.isNotEmpty && city != state
                            ? '$city, $state'
                            : city)
                      : (item['display_name'] as String)
                            .split(',')
                            .take(2)
                            .join(',')
                            .trim());
            return _PlaceResult(
              displayName: shortName,
              fullName: item['display_name'] as String,
              lat: double.parse(item['lat'] as String),
              lng: double.parse(item['lon'] as String),
            );
          }).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(v));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.92,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (ctx, scrollCtrl) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose ${widget.label == "DEPARTURE" ? "departure" : "destination"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'e.g. Nabeul, Avenue Habib Bourguiba, Tunis...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Text(
                      _ctrl.text.isEmpty
                          ? 'Start typing a place name...'
                          : 'No results found.',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final p = _results[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.forestGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          p.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          p.fullName
                              .split(',')
                              .skip(1)
                              .take(2)
                              .join(',')
                              .trim(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(ctx).pop(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

class _PlaceResult {
  final String displayName;
  final String fullName;
  final double lat;
  final double lng;
  const _PlaceResult({
    required this.displayName,
    required this.fullName,
    required this.lat,
    required this.lng,
  });
}

class _SeatButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _SeatButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: filled ? AppColors.forestGreen : Colors.transparent,
        shape: BoxShape.circle,
        border: filled
            ? null
            : Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
      ),
      child: Icon(
        icon,
        color: filled ? Colors.white : AppColors.textDark,
        size: 20,
      ),
    ),
  );
}

