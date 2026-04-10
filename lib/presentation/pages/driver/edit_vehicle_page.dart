import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/vehicle.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/rideleaf_button.dart';
import '../../widgets/rideleaf_text_field.dart';

class EditVehiclePage extends StatefulWidget {
  const EditVehiclePage({super.key});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;
  DateTime? _expiryDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final vehicles = authState.user.vehicles;
      if (vehicles.isNotEmpty) {
        final vehicle = vehicles.first;
        _licenseNumberCtrl.text = vehicle.licenseNumber;
        _expiryDate = vehicle.licenseExpirationDate.year == 1970
            ? null
            : vehicle.licenseExpirationDate;
        _expiryCtrl.text = vehicle.licenseExpirationDate.year == 1970
            ? ''
            : '${vehicle.licenseExpirationDate.month.toString().padLeft(2, '0')}/${vehicle.licenseExpirationDate.day.toString().padLeft(2, '0')}/${vehicle.licenseExpirationDate.year}';
        _plateCtrl.text = vehicle.licensePlate;
        _modelCtrl.text = vehicle.model;
        _colorCtrl.text = vehicle.color;
      }
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _licenseNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final fallbackDate = now.add(const Duration(days: 365));
    final initialDate = (_expiryDate == null || _expiryDate!.year == 1970)
        ? fallbackDate
        : _expiryDate!;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.forestGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _expiryCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<bool> _confirmEdit() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Confirm Vehicle Update'),
            content: const Text(
              'Updating your vehicle data will temporarily suspend your driver role. '
              'Your account will be changed to passenger until an admin verifies the updated information.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await _confirmEdit();
    if (!confirmed) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSaving = true);
    final plate = _plateCtrl.text.trim().toUpperCase();
    try {
      await context.read<UserRepository>().updateVehicles(
        uid: authState.user.uid,
        vehicles: [
          Vehicle(
            licensePlate: plate,
            model: _modelCtrl.text.trim(),
            color: _colorCtrl.text.trim(),
            licenseNumber: _licenseNumberCtrl.text.trim(),
            licenseExpirationDate: _expiryDate ?? DateTime.now(),
          ),
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle details saved successfully.'),
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
          'Edit Vehicle Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Edit your registered vehicle details.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'License Plate',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                RideLeafTextField(
                  controller: _plateCtrl,
                  hintText: 'ABC-1234',
                  prefixIcon: Icons.directions_car_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your license plate.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Driver License Number',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                RideLeafTextField(
                  controller: _licenseNumberCtrl,
                  hintText: 'D12345678',
                  prefixIcon: Icons.tag_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your license number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'License Expiration Date',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _expiryCtrl,
                        decoration: InputDecoration(
                          hintText: 'mm/dd/yyyy',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withOpacity(0.6),
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F3F1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.forestGreen,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        validator: (v) => _expiryDate == null
                            ? 'Please select the license expiration date.'
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Vehicle Model',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                RideLeafTextField(
                  controller: _modelCtrl,
                  hintText: 'Tesla Model 3',
                  prefixIcon: Icons.directions_car_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your vehicle model.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Vehicle Color',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                RideLeafTextField(
                  controller: _colorCtrl,
                  hintText: 'White',
                  prefixIcon: Icons.color_lens_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your vehicle color.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                RideLeafButton(
                  label: 'Save Vehicle',
                  onPressed: _isSaving ? null : _save,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
