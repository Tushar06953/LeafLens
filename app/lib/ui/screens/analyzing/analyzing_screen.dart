import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/identify_service.dart';

// Step status
enum _StepStatus { waiting, inProgress, done }

class _Step {
  final String label;
  final _StepStatus status;
  const _Step(this.label, this.status);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnalyzingScreen extends ConsumerStatefulWidget {
  final List<String> images;
  final String mode;

  const AnalyzingScreen({
    super.key,
    required this.images,
    required this.mode,
  });

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late List<Animation<double>> _pulseAnims;

  List<_Step> _steps = [
    const _Step('Processing image', _StepStatus.inProgress),
    const _Step('Identifying species', _StepStatus.waiting),
    const _Step('Fetching plant data', _StepStatus.waiting),
    const _Step('Building plant profile', _StepStatus.waiting),
  ];

  IdentifyException? _error;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: false);

    _pulseAnims = List.generate(3, (i) {
      return Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(
          parent: _pulseCtrl,
          curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeOut),
        ),
      );
    });

    _runIdentification();
  }

  Future<void> _runIdentification() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _setStep(0, _StepStatus.done);
    _setStep(1, _StepStatus.inProgress);

    try {
      final files = widget.images.map((p) => File(p)).toList();
      final plant = await IdentifyService.identify(files, widget.mode);

      _setStep(1, _StepStatus.done);
      _setStep(2, _StepStatus.inProgress);
      await Future.delayed(const Duration(milliseconds: 400));
      _setStep(2, _StepStatus.done);
      _setStep(3, _StepStatus.inProgress);
      await Future.delayed(const Duration(milliseconds: 300));
      _setStep(3, _StepStatus.done);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        context.go(AppRoutes.result, extra: plant);
      }
    } catch (e) {
      setState(() {
        _error = e is IdentifyException
            ? e
            : IdentifyException(code: 'connection_error', message: e.toString());
      });
    }
  }

  void _setStep(int index, _StepStatus status) {
    if (!mounted) return;
    setState(() {
      _steps = List.from(_steps)
        ..[index] = _Step(_steps[index].label, status);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [AppColors.g2, AppColors.g1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _error != null
                  ? _ErrorView(
                      error: _error!,
                      onRetry: () => context.go(AppRoutes.scan),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PulsingRings(
                          anims: _pulseAnims,
                          controller: _pulseCtrl,
                        ),
                        const SizedBox(height: 40),
                        Text('Analysing...', style: AppTextStyles.heading1),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we identify your plant',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.text2),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        ..._steps.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _StepCard(step: e.value),
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing rings ─────────────────────────────────────────────────────────────

class _PulsingRings extends StatelessWidget {
  final List<Animation<double>> anims;
  final AnimationController controller;

  const _PulsingRings({required this.anims, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Transform.scale(
                scale: anims[2].value,
                child: Opacity(
                  opacity: (1.0 - anims[2].value + 0.7).clamp(0.0, 0.3),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.gc.withOpacity(0.3), width: 1.5),
                    ),
                  ),
                ),
              ),
              // Middle ring
              Transform.scale(
                scale: anims[1].value,
                child: Opacity(
                  opacity: (1.0 - anims[1].value + 0.7).clamp(0.0, 0.5),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.gc.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                ),
              ),
              // Inner ring
              Transform.scale(
                scale: anims[0].value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.ga, AppColors.gb],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gb.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 36)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Step card ─────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final _Step step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final isDone = step.status == _StepStatus.done;
    final isActive = step.status == _StepStatus.inProgress;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.ga.withOpacity(0.2)
            : isActive
                ? AppColors.gold.withOpacity(0.15)
                : AppColors.g2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? AppColors.gc.withOpacity(0.4)
              : isActive
                  ? AppColors.gold2.withOpacity(0.4)
                  : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: isDone
                ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gc,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  )
                : isActive
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold2,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.text3),
                        ),
                      ),
          ),
          const SizedBox(width: 12),
          Text(
            step.label,
            style: AppTextStyles.label.copyWith(
              color: isDone
                  ? AppColors.gc
                  : isActive
                      ? AppColors.gold2
                      : AppColors.text3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final IdentifyException error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isLowConfidence = error.code == 'low_confidence';
    final displayMessage = isLowConfidence
        ? 'Could not identify — try multi-angle for better results.'
        : error.message;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isLowConfidence ? '🔍' : '😔',
            style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        Text(
          isLowConfidence ? 'Plant Not Recognised' : 'Identification Failed',
          style: AppTextStyles.heading2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          displayMessage,
          style: AppTextStyles.body.copyWith(color: AppColors.text2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gb,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onRetry,
            child: Text('Try Again', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }
}
