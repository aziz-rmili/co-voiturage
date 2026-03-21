import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth_bloc.dart';
import '../../widgets/rideleaf_button.dart';
import '../../widgets/rideleaf_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _termsError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final formValid = _formKey.currentState!.validate();
    if (!_agreedToTerms) setState(() => _termsError = true);
    if (!formValid || !_agreedToTerms) return;

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        nom: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telephone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F0),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go(AppRoutes.home);
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Heading
                        const Text(
                          AppStrings.createAccount,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forestGreen,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          AppStrings.startJourney,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Full Name
                        const _FieldLabel(AppStrings.fullNameLabel),
                        const SizedBox(height: 8),
                        RideLeafTextField(
                          controller: _nameCtrl,
                          hintText: 'Alex Rivera',
                          prefixIcon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                          validator: Validators.name,
                        ),

                        const SizedBox(height: 20),

                        // ── Email
                        const _FieldLabel(AppStrings.emailLabel),
                        const SizedBox(height: 8),
                        RideLeafTextField(
                          controller: _emailCtrl,
                          hintText: 'alex@example.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),

                        const SizedBox(height: 20),

                        // ── Phone
                        const _FieldLabel(AppStrings.phoneLabel),
                        const SizedBox(height: 8),
                        RideLeafTextField(
                          controller: _phoneCtrl,
                          hintText: '+33 6 12 34 56 78',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),

                        const SizedBox(height: 20),

                        // ── Password
                        const _FieldLabel(AppStrings.passwordLabel),
                        const SizedBox(height: 8),
                        RideLeafTextField(
                          controller: _passwordCtrl,
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          validator: Validators.password,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Terms checkbox
                        GestureDetector(
                          onTap: () => setState(() {
                            _agreedToTerms = !_agreedToTerms;
                            if (_agreedToTerms) _termsError = false;
                          }),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CustomCheckbox(
                                    value: _agreedToTerms,
                                    hasError: _termsError,
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_termsError) ...[
                                const SizedBox(height: 4),
                                const Padding(
                                  padding: EdgeInsets.only(left: 30),
                                  child: Text(
                                    AppStrings.termsRequired,
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── CTA
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
                  ),
                ),

                // ── Already have account (outside card)
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

// ── Local widgets ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
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

class _CustomCheckbox extends StatelessWidget {
  final bool value;
  final bool hasError;
  const _CustomCheckbox({required this.value, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
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
}
