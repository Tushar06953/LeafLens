import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _outerRingController;
  late AnimationController _innerRingController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _outerRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _innerRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: false);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _outerRingController.dispose();
    _innerRingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleGetStarted() {
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [AppColors.dark2, AppColors.dark1],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Animated rings
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer dashed ring — spins clockwise
                      AnimatedBuilder(
                        animation: _outerRingController,
                        builder: (_, child) => Transform.rotate(
                          angle: _outerRingController.value * 2 * math.pi,
                          child: child,
                        ),
                        child: CustomPaint(
                          size: const Size(130, 130),
                          painter: _DashedCirclePainter(
                            color: AppColors.gb,
                            dashCount: 28,
                            gapFraction: 0.38,
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                      // Inner circle — counter-spins
                      AnimatedBuilder(
                        animation: _innerRingController,
                        builder: (_, child) => Transform.rotate(
                          angle: -_innerRingController.value * 2 * math.pi,
                          child: child,
                        ),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.ga, AppColors.gb],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gb.withAlpha(80),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // App name
                Text(
                  'LeafLens',
                  style: AppTextStyles.display.copyWith(color: AppColors.cream),
                ),
                const SizedBox(height: 8),
                Text(
                  'Identify · Learn · Save',
                  style: AppTextStyles.tagline.copyWith(color: AppColors.gc),
                ),
                const Spacer(flex: 3),
                // Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: _handleGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gb,
                      foregroundColor: AppColors.darkText,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: AppTextStyles.button.copyWith(color: AppColors.darkText),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double gapFraction;
  final double strokeWidth;

  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
    required this.gapFraction,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    const fullAngle = math.pi * 2;
    final dashAngle = (fullAngle / dashCount) * (1 - gapFraction);
    final gapAngle = (fullAngle / dashCount) * gapFraction;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle) - math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}
