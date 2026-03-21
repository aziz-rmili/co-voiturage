import 'dart:async';
import 'package:devmob_covoitlocal/core/constants/app_colors.dart';
import 'package:devmob_covoitlocal/presentation/pages/pages.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _taglineFade;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    _progressValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Navigate to login after splash
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo + brand (centered vertically in upper 2/3)
            Expanded(
              flex: 3,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo icon
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: const _RideLeafLogo(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // App name
                      FadeTransition(
                        opacity: _textFade,
                        child: const Text(
                          'RideLeaf',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      FadeTransition(
                        opacity: _textFade,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _dividerLine(),
                            const SizedBox(width: 12),
                            const Text(
                              'THE ECOLOGICAL CONCIERGE',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _dividerLine(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tagline + progress (bottom 1/3)
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedBuilder(
                    animation: _taglineFade,
                    builder: (_, __) => FadeTransition(
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
                  ),
                  const SizedBox(height: 40),

                  // Progress bar
                  AnimatedBuilder(
                    animation: _progressValue,
                    builder: (_, __) => Padding(
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
                  ),
                  const SizedBox(height: 16),

                  // Version info
                  const Text(
                    'VERSION 1.0.0  •  ECO-CERTIFIED',
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
          ],
        ),
      ),
    );
  }

  Widget _dividerLine() =>
      Container(width: 28, height: 1, color: Colors.white30);
}

/// The white rounded-square logo with leaf + orange lightning badge
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
          // White card
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

          // Orange lightning badge
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
