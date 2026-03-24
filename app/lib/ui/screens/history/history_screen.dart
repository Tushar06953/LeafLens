import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/scan.dart';
import '../../../providers/plant_of_day_provider.dart';

// ─── Local state ──────────────────────────────────────────────────────────────

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _activeCategoryProvider = StateProvider<String>((ref) => 'All');

const _categories = ['All', 'Medicinal', 'Edible', 'Toxic', 'Saved'];

// ─── Screen ───────────────────────────────────────────────────────────────────

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(allScansProvider);

    return Scaffold(
      backgroundColor: AppColors.warm,
      body: scansAsync.when(
        loading: () => const _HistoryShimmer(),
        error: (e, _) => _ErrorState(
            onRetry: () => ref.invalidate(allScansProvider)),
        data: (scans) => _HistoryBody(scans: scans),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 0),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  final List<ScanModel> scans;
  const _HistoryBody({required this.scans});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchQueryProvider).toLowerCase();
    final category = ref.watch(_activeCategoryProvider);

    final filtered = scans.where((s) {
      final matchQuery = query.isEmpty ||
          (s.commonName?.toLowerCase().contains(query) ?? false) ||
          (s.scientificName?.toLowerCase().contains(query) ?? false);
      final matchCat = category == 'All' ||
          (s.category?.toLowerCase() == category.toLowerCase());
      return matchQuery && matchCat;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('History', style: AppTextStyles.heading1.copyWith(color: AppColors.darkText)),
                Text(
                  '${scans.length} scans',
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer(builder: (ctx, ref, _) {
              return TextField(
                onChanged: (v) =>
                    ref.read(_searchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'Search plants...',
                  hintStyle: AppTextStyles.body
                      .copyWith(color: AppColors.mutedText),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.mutedText),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: AppTextStyles.body
                    .copyWith(color: AppColors.darkText),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 36,
            child: Consumer(builder: (ctx, ref, _) {
              final active = ref.watch(_activeCategoryProvider);
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isActive = cat == active;
                  return GestureDetector(
                    onTap: () => ref
                        .read(_activeCategoryProvider.notifier)
                        .state = cat,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.ga : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.ga
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive ? Colors.white : AppColors.mutedText,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState()
                : _GroupedList(scans: filtered),
          ),
        ],
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  final List<ScanModel> scans;
  const _GroupedList({required this.scans});

  String _groupLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return 'This Week';
    return 'Older';
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<ScanModel>>{};
    for (final s in scans) {
      final label = _groupLabel(s.scannedAt);
      groups.putIfAbsent(label, () => []).add(s);
    }

    final order = ['Today', 'Yesterday', 'This Week', 'Older'];
    final sortedKeys =
        order.where((k) => groups.containsKey(k)).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: sortedKeys.fold<int>(
          0, (sum, k) => sum + 1 + groups[k]!.length),
      itemBuilder: (ctx, index) {
        int cursor = 0;
        for (final key in sortedKeys) {
          if (index == cursor) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
              child: Text(
                key,
                style: AppTextStyles.label.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600),
              ),
            );
          }
          cursor++;
          final items = groups[key]!;
          if (index < cursor + items.length) {
            final scan = items[index - cursor];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryItem(scan: scan),
            );
          }
          cursor += items.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ScanModel scan;
  const _HistoryItem({required this.scan});

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _categoryColor(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'medicinal':
        return const Color(0xFF2A9D8F);
      case 'edible':
        return Colors.green.shade600;
      case 'toxic':
        return Colors.red.shade400;
      default:
        return AppColors.ga;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to plant detail — using dummy plant from scan
        // In real app, fetch plant by scan.plantId first
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.ga.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  scan.emoji ?? '🌿',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.commonName ?? 'Unknown Plant',
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${scan.scientificName ?? ''} · ${_timeLabel(scan.scannedAt)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(scan.confidence * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.ga, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (scan.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _categoryColor(scan.category)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      scan.category!,
                      style: AppTextStyles.caption.copyWith(
                          color: _categoryColor(scan.category),
                          fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No scans yet',
              style: AppTextStyles.heading2
                  .copyWith(color: AppColors.darkText)),
          const SizedBox(height: 8),
          Text(
            'Go identify a plant to see it here!',
            style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🌵', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Something went wrong',
            style: AppTextStyles.label
                .copyWith(color: AppColors.darkText)),
        TextButton(
          onPressed: onRetry,
          child: Text('Retry',
              style: AppTextStyles.body.copyWith(color: AppColors.gc)),
        ),
      ]),
    );
  }
}

class _HistoryShimmer extends StatelessWidget {
  const _HistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _SBox(width: 120, height: 28),
            const SizedBox(height: 20),
            _SBox(width: double.infinity, height: 46, radius: 14),
            const SizedBox(height: 16),
            Row(children: [
              _SBox(width: 60, height: 32, radius: 16),
              const SizedBox(width: 8),
              _SBox(width: 80, height: 32, radius: 16),
              const SizedBox(width: 8),
              _SBox(width: 60, height: 32, radius: 16),
            ]),
            const SizedBox(height: 20),
            ...List.generate(
                4,
                (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SBox(
                          width: double.infinity, height: 72),
                    )),
          ]),
        ),
      ),
    );
  }
}

class _SBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _SBox({this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isActive ? AppColors.gc : AppColors.text3, size: 24),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: isActive ? AppColors.gc : AppColors.text3, fontSize: 10)),
        ]),
      ),
    );
  }
}
