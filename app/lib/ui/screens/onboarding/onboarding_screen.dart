import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/storage_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      emoji: '🌿',
      title: 'Identify Any Plant',
      description:
          'Point your camera at any leaf, flower, or bark and get an instant species identification powered by AI.',
    ),
    _OnboardingSlide(
      emoji: '📖',
      title: 'Learn Everything',
      description:
          'Discover soil requirements, medicinal uses, culinary properties, conservation status, and fascinating facts.',
    ),
    _OnboardingSlide(
      emoji: '💾',
      title: 'Build Your Collection',
      description:
          'Save your favourites, browse your history, and explore a community-built encyclopedia of thousands of plants.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.hasSeenOnboarding, true);
    if (mounted) context.go(AppRoutes.splash);
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.g1, AppColors.g2],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Skip button
              Positioned(
                top: 16,
                right: 20,
                child: TextButton(
                  onPressed: _complete,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.label.copyWith(color: AppColors.text2),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 40),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                slide.emoji,
                                style: const TextStyle(fontSize: 88),
                              ),
                              const SizedBox(height: 32),
                              // Dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_slides.length, (i) {
                                  final isActive = i == _currentPage;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: isActive ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.gb : AppColors.text3,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                slide.title,
                                style: AppTextStyles.heading1,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                slide.description,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.text2,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gb,
                        foregroundColor: AppColors.darkText,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Start Exploring' : 'Next',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
