import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/driver_credentials.dart';
import '../../../domain/entities/vehicle.dart';
import '../../blocs/blocs.dart';
import '../../widgets/widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F0),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(AppRoutes.home);
          } else if (state is AuthDriverStep1Complete) {
            // Driver completed step 1 — show credentials form
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: _DriverCredentialsPage(userId: state.user.uid),
                ),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── White card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Start your ecological journey today.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Tabs: Passenger | Driver
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoleTab(
                            label: 'Passenger',
                            active: _tabCtrl.index == 0,
                            onTap: () => _tabCtrl.animateTo(0),
                          ),
                          const SizedBox(width: 32),
                          _RoleTab(
                            label: 'Driver',
                            active: _tabCtrl.index == 1,
                            onTap: () => _tabCtrl.animateTo(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Form (same fields for both roles in step 1)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _tabCtrl.index == 0
                            ? const _PassengerForm(key: ValueKey('passenger'))
                            : const _DriverStep1Form(key: ValueKey('driver')),
                      ),
                    ],
                  ),
                ),

                // ── Already have account
                const SizedBox(height: 20),
                const Divider(
                  color: Color(0xFFCCCCCC),
                  indent: 32,
                  endIndent: 32,
                ),
                const SizedBox(height: 16),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: '${AppStrings.alreadyHaveAccount}  ',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Trust badges
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustBadge(
                        icon: Icons.verified_outlined,
                        label: AppStrings.certifiedCarbon,
                      ),
                      const SizedBox(width: 32),
                      _TrustBadge(
                        icon: Icons.shield_outlined,
                        label: AppStrings.securePlatform,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role tab widget ───────────────────────────────────────────────────────────

class _RoleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _RoleTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: active ? 60 : 0,
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

// ── Passenger form ────────────────────────────────────────────────────────────

class _PassengerForm extends StatefulWidget {
  const _PassengerForm({super.key});
  @override
  State<_PassengerForm> createState() => _PassengerFormState();
}

class _PassengerFormState extends State<_PassengerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _agreedToTerms = false;
  bool _termsError = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    if (!_agreedToTerms) setState(() => _termsError = true);
    if (!valid || !_agreedToTerms) return;
    context.read<AuthBloc>().add(
      AuthRegisterPassengerRequested(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(AppStrings.fullNameLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _nameCtrl,
            hintText: 'Alex Rivera',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            validator: Validators.name,
          ),
          const SizedBox(height: 20),
          const _Label(AppStrings.emailLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _emailCtrl,
            hintText: 'alex@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 20),
          const _Label(AppStrings.phoneLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _phoneCtrl,
            hintText: '+33 6 12 34 56 78',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
          ),
          const SizedBox(height: 20),
          const _Label(AppStrings.passwordLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _passwordCtrl,
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            validator: Validators.password,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _TermsCheckbox(
            value: _agreedToTerms,
            hasError: _termsError,
            onChanged: (v) => setState(() {
              _agreedToTerms = v;
              if (v) _termsError = false;
            }),
          ),
          const SizedBox(height: 28),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => RideLeafButton(
              label: AppStrings.createAccountButton,
              onPressed: _submit,
              isLoading: state is AuthLoading,
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Driver step 1 form (same fields, different event) ────────────────────────

class _DriverStep1Form extends StatefulWidget {
  const _DriverStep1Form({super.key});
  @override
  State<_DriverStep1Form> createState() => _DriverStep1FormState();
}

class _DriverStep1FormState extends State<_DriverStep1Form> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _agreedToTerms = false;
  bool _termsError = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    if (!_agreedToTerms) setState(() => _termsError = true);
    if (!valid || !_agreedToTerms) return;
    context.read<AuthBloc>().add(
      AuthRegisterDriverStep1Requested(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(AppStrings.fullNameLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _nameCtrl,
            hintText: 'Alex Rivera',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            validator: Validators.name,
          ),
          const SizedBox(height: 20),
          const _Label(AppStrings.emailLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _emailCtrl,
            hintText: 'alex@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 20),
          const _Label(AppStrings.phoneLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _phoneCtrl,
            hintText: '+33 6 12 34 56 78',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
          ),
          const SizedBox(height: 20),
          const _Label(AppStrings.passwordLabel),
          const SizedBox(height: 8),
          RideLeafTextField(
            controller: _passwordCtrl,
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            validator: Validators.password,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _TermsCheckbox(
            value: _agreedToTerms,
            hasError: _termsError,
            onChanged: (v) => setState(() {
              _agreedToTerms = v;
              if (v) _termsError = false;
            }),
          ),
          const SizedBox(height: 28),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => RideLeafButton(
              label: 'Create Account',
              onPressed: _submit,
              isLoading: state is AuthLoading,
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Driver step 2: Credentials page ──────────────────────────────────────────

class _DriverCredentialsPage extends StatefulWidget {
  final String userId;
  const _DriverCredentialsPage({required this.userId});
  @override
  State<_DriverCredentialsPage> createState() => _DriverCredentialsPageState();
}

class _DriverCredentialsPageState extends State<_DriverCredentialsPage> {
  final _formKey = GlobalKey<FormState>();
  final _licenseCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _vehicleColorCtrl = TextEditingController();
  bool _agreedToTerms = false;
  bool _termsError = false;
  bool _photoSelected = false;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _licenseCtrl.dispose();
    _expiryCtrl.dispose();
    _plateCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _vehicleColorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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

  void _submit() {
    final valid = _formKey.currentState!.validate();
    if (!_agreedToTerms) setState(() => _termsError = true);
    if (!valid || !_agreedToTerms || _expiryDate == null) return;

    context.read<AuthBloc>().add(
      AuthSubmitDriverCredentials(
        DriverCredentials(
          userId: widget.userId,
          licenseNumber: _licenseCtrl.text.trim(),
          licenseExpirationDate: _expiryDate!,
          vehicle: Vehicle(
            licensePlate: _plateCtrl.text.trim().toUpperCase(),
            model: _vehicleModelCtrl.text.trim(),
            color: _vehicleColorCtrl.text.trim(),
          ),
          licensePhotoUrl: '', // Real apps: upload to Firebase Storage first
          submittedAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F0),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthDriverCredentialsSubmitted) {
            // Show success then go to login
            _showPendingDialog();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forestGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Start your ecological journey today.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Role tabs (Driver active, not tappable here)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RoleTab(
                              label: 'Passenger',
                              active: false,
                              onTap: () {},
                            ),
                            const SizedBox(width: 32),
                            _RoleTab(
                              label: 'Driver',
                              active: true,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Step header + progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                                Text(
                                  'Credentials',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                              ],
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '50%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.5,
                            minHeight: 6,
                            backgroundColor: Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.forestGreen,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── License number
                        const _Label("DRIVER'S LICENSE NUMBER"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _licenseCtrl,
                          decoration: _inputDecoration(
                            hint: 'e.g. D12345678',
                            icon: Icons.tag_rounded,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'License number is required.'
                              : null,
                        ),

                        const SizedBox(height: 20),

                        // ── License expiry
                        const _Label('LICENSE EXPIRATION DATE'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _expiryCtrl,
                              decoration: _inputDecoration(
                                hint: 'mm/dd/yyyy',
                                icon: Icons.calendar_month_outlined,
                              ),
                              validator: (v) => _expiryDate == null
                                  ? 'Please select the expiration date.'
                                  : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── License plate
                        const _Label('LICENSE PLATE NUMBER'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _plateCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _inputDecoration(
                            hint: 'ABC-1234',
                            icon: Icons.directions_car_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'License plate is required.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        const _Label('VEHICLE MODEL'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _vehicleModelCtrl,
                          decoration: _inputDecoration(
                            hint: 'Tesla Model 3',
                            icon: Icons.directions_car_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vehicle model is required.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        const _Label('VEHICLE COLOR'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _vehicleColorCtrl,
                          decoration: _inputDecoration(
                            hint: 'White',
                            icon: Icons.color_lens_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vehicle color is required.'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // ── Identity verification upload
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Identity Verification',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'REQUIRED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _photoSelected = true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _photoSelected
                                    ? AppColors.forestGreen
                                    : const Color(0xFFDDDDDD),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _photoSelected
                                        ? Icons.check_circle_outline
                                        : Icons.add_a_photo_outlined,
                                    color: _photoSelected
                                        ? AppColors.forestGreen
                                        : AppColors.textMuted,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _photoSelected
                                      ? 'Photo selected ✓'
                                      : 'Upload Driver License Photo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: _photoSelected
                                        ? AppColors.forestGreen
                                        : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'JPEG, PNG or PDF. Max size 5MB.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _TermsCheckbox(
                          value: _agreedToTerms,
                          hasError: _termsError,
                          onChanged: (v) => setState(() {
                            _agreedToTerms = v;
                            if (v) _termsError = false;
                          }),
                        ),

                        const SizedBox(height: 28),

                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) => RideLeafButton(
                            label: 'Complete Registration',
                            onPressed: _submit,
                            isLoading: state is AuthLoading,
                            icon: Icons.person_add_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(
                  color: Color(0xFFCCCCCC),
                  indent: 32,
                  endIndent: 32,
                ),
                const SizedBox(height: 16),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: '${AppStrings.alreadyHaveAccount}  ',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustBadge(
                        icon: Icons.verified_outlined,
                        label: AppStrings.certifiedCarbon,
                      ),
                      const SizedBox(width: 32),
                      _TrustBadge(
                        icon: Icons.shield_outlined,
                        label: AppStrings.securePlatform,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textMuted.withOpacity(0.6),
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
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
        borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: AppColors.orange,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verification Pending',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your driver credentials have been submitted.\nOur team will review them within 24–48 hours. You\'ll be notified once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            RideLeafButton(
              label: 'Go to Login',
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: AppColors.textDark,
    ),
  );
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final bool hasError;
  final ValueChanged<bool> onChanged;
  const _TermsCheckbox({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasError
                        ? AppColors.error
                        : value
                        ? AppColors.forestGreen
                        : const Color(0xFFCCCCCC),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: value ? AppColors.forestGreen : Colors.transparent,
                ),
                child: value
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 30),
            child: Text(
              AppStrings.termsRequired,
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: AppColors.textMuted),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
