import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/router/app_router.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.g2,
        border: Border(top: BorderSide(color: AppColors.g3)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', isActive: currentIndex == 0, onTap: () => context.go(AppRoutes.home)),
              _NavItem(icon: Icons.camera_alt_rounded, label: 'Scan', isActive: currentIndex == 1, onTap: () => context.go(AppRoutes.scan)),
              _NavItem(icon: Icons.menu_book_rounded, label: 'Encyclopedia', isActive: currentIndex == 2, onTap: () => context.go(AppRoutes.encyclopedia)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', isActive: currentIndex == 3, onTap: () => context.go(AppRoutes.profile)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppColors.gc : AppColors.text3, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppColors.gc : AppColors.text3,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
