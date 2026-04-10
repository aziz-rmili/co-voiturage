import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../blocs/auth_bloc.dart';

class RidePreferencesPage extends StatefulWidget {
  const RidePreferencesPage({super.key});

  @override
  State<RidePreferencesPage> createState() => _RidePreferencesPageState();
}

class _RidePreferencesPageState extends State<RidePreferencesPage> {
  bool _smokingAllowed = false;
  bool _petsAllowed = true;
  String _musicLevel = 'relaxing';
  String _luggageSize = 'standardSuitcase';
  String _conversationLevel = 'chatty';
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final prefs = authState.user.ridePreferences;
      _smokingAllowed = (prefs['smokingAllowed'] as bool?) ?? false;
      _petsAllowed = (prefs['petsAllowed'] as bool?) ?? true;
      _musicLevel = (prefs['musicLevel'] as String?) ?? 'relaxing';
      _luggageSize = (prefs['luggageSize'] as String?) ?? 'standardSuitcase';
      _conversationLevel =
          (prefs['conversationLevel'] as String?) ?? 'chatty';
    }
    _initialized = true;
  }

  Future<void> _save() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    setState(() => _isSaving = true);
    try {
      await context.read<UserRepository>().updateRidePreferences(
        uid: authState.user.uid,
        ridePreferences: {
          'smokingAllowed': _smokingAllowed,
          'petsAllowed': _petsAllowed,
          'musicLevel': _musicLevel,
          'luggageSize': _luggageSize,
          'conversationLevel': _conversationLevel,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully'),
          backgroundColor: AppColors.forestGreen,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: const Text(
          'Ride Preferences',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const Text(
            'Your Journey, Your Rules.',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tailor your carpooling experience to match your comfort.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 14),
          _Card(
            title: 'Smoking',
            subtitle: 'Preference for tobacco use',
            child: _TwoChoice(
              leftLabel: 'No',
              rightLabel: 'Yes',
              rightSelected: _smokingAllowed,
              onChanged: (v) => setState(() => _smokingAllowed = v),
            ),
          ),
          _Card(
            title: 'Pets',
            subtitle: 'Traveling with furry friends',
            child: _TwoChoice(
              leftLabel: 'No',
              rightLabel: 'Yes',
              rightSelected: _petsAllowed,
              onChanged: (v) => setState(() => _petsAllowed = v),
            ),
          ),
          _Card(
            title: 'Music Levels',
            subtitle: 'Vibe setting',
            child: _Segmented(
              values: const ['quiet', 'relaxing', 'energetic'],
              labels: const ['Quiet', 'Relaxing', 'Energetic'],
              selected: _musicLevel,
              onChanged: (v) => setState(() => _musicLevel = v),
            ),
          ),
          _Card(
            title: 'Luggage Capacity',
            subtitle: 'Space requirements',
            child: _RadioChoices(
              values: const ['smallBagOnly', 'standardSuitcase', 'largeItems'],
              labels: const ['Small bag only', 'Standard suitcase', 'Large items'],
              selected: _luggageSize,
              onChanged: (v) => setState(() => _luggageSize = v),
            ),
          ),
          _Card(
            title: 'Conversation',
            subtitle: 'Social interaction level',
            child: _Segmented(
              values: const ['quietRide', 'chatty'],
              labels: const ['Quiet ride', 'Chatty'],
              selected: _conversationLevel,
              onChanged: (v) => setState(() => _conversationLevel = v),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brownOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Preferences',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Card({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TwoChoice extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;
  const _TwoChoice({
    required this.leftLabel,
    required this.rightLabel,
    required this.rightSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _choice(leftLabel, !rightSelected, () => onChanged(false))),
          Expanded(child: _choice(rightLabel, rightSelected, () => onChanged(true))),
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.forestGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  const _Segmented({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(values.length, (i) {
        final isSelected = values[i] == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(values[i]),
            child: Container(
              margin: EdgeInsets.only(right: i == values.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.forestGreen : const Color(0xFFF0F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _RadioChoices extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;
  const _RadioChoices({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(values.length, (i) {
        final isSelected = selected == values[i];
        return GestureDetector(
          onTap: () => onChanged(values[i]),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.forestGreen : const Color(0xFFD9D9D9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labels[i],
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.forestGreen : AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
