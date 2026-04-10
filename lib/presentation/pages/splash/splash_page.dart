import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _taglineFade;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _logoFade = _interval(0.0, 0.35);
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _textFade = _interval(0.3, 0.55);
    _taglineFade = _interval(0.5, 0.75);
    _progressValue = Tween<double>(begin: 0, end: 0.35).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _ctrl.forward();
    // AuthStarted is fired by AppRouter when providing the BLoC — no need here.
  }

  Animation<double> _interval(double begin, double end) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Wait for the animation to finish before navigating
        if (state is AuthAuthenticated) {
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (mounted) context.go(AppRoutes.home);
          });
        } else if (state is AuthUnauthenticated) {
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (mounted) context.go(AppRoutes.login);
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.forestGreen,
        body: SafeArea(
          child: Column(
            children: [
              // ── Logo + brand (upper 3/5)
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: const _RideLeafLogo(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _textFade,
                          child: const Text(
                            AppStrings.appName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _textFade,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _line(),
                              const SizedBox(width: 12),
                              Text(
                                AppStrings.tagline.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _line(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Tagline + progress (lower 2/5)
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FadeTransition(
                        opacity: _taglineFade,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              Text(
                                'Your Daily Commute,',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Greener.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressValue.value,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.orange,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        AppStrings.version,
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line() => Container(width: 28, height: 1, color: Colors.white30);
}

class _RideLeafLogo extends StatelessWidget {
  const _RideLeafLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.eco_rounded,
                color: AppColors.forestGreen,
                size: 52,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
