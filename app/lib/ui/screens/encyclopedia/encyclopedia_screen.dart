import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/plant.dart';
import '../../../providers/plant_of_day_provider.dart';
import '../../../providers/local_history_provider.dart';
import '../../widgets/bottom_nav.dart';

// ─── Local state ──────────────────────────────────────────────────────────────

final _encSearchProvider = StateProvider<String>((ref) => '');
final _encFilterProvider = StateProvider<String>((ref) => 'All');

const _filters = ['All', 'Medicinal', 'Edible', 'Indoor', 'Rare'];

// ─── Screen ───────────────────────────────────────────────────────────────────

class EncyclopediaScreen extends ConsumerWidget {
  const EncyclopediaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(allPlantsProvider);
    final potdAsync = ref.watch(plantOfDayProvider);
    final savedPlants = ref.watch(localSavedPlantsProvider);

    return BackButtonListener(
      onBackButtonPressed: () async {
        context.go(AppRoutes.home);
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.warm,
        body: plantsAsync.when(
          loading: () => const _EncShimmer(),
          error: (e, _) =>
              _ErrorState(onRetry: () => ref.invalidate(allPlantsProvider)),
          data: (plants) => _EncBody(
            plants: plants,
            savedPlants: savedPlants,
            potdAsync: potdAsync,
          ),
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      ),
    );
  }
}

class _EncBody extends ConsumerWidget {
  final List<PlantModel> plants;
  final List<PlantModel> savedPlants;
  final AsyncValue<PlantModel?> potdAsync;

  const _EncBody({
    required this.plants,
    required this.savedPlants,
    required this.potdAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_encSearchProvider).toLowerCase();
    final filter = ref.watch(_encFilterProvider);

    final filtered = plants.where((p) {
      final matchQ = query.isEmpty ||
          p.commonName.toLowerCase().contains(query) ||
          p.scientificName.toLowerCase().contains(query) ||
          p.family.toLowerCase().contains(query);
      final matchF = filter == 'All' ||
          (filter == 'Medicinal' && p.uses.medicinal != null) ||
          (filter == 'Edible' && p.uses.culinary != null) ||
          (filter == 'Indoor' &&
              (p.habitat?.toLowerCase().contains('indoor') ?? false)) ||
          (filter == 'Rare' &&
              (p.iucnStatus?.toLowerCase().contains('endangered') ?? false));
      return matchQ && matchF;
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Encyclopedia',
                style: AppTextStyles.heading1
                    .copyWith(color: AppColors.darkText),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) =>
                    ref.read(_encSearchProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'Search plants...',
                  hintStyle: AppTextStyles.body
                      .copyWith(color: AppColors.mutedText),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.mutedText),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: AppTextStyles.body
                    .copyWith(color: AppColors.darkText),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final isActive = filter == f;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(_encFilterProvider.notifier).state = f,
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
                        f,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.mutedText,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Featured POTD card
          SliverToBoxAdapter(
            child: potdAsync.when(
              loading: () => const _PotdShimmer(),
              error: (_, __) => const SizedBox.shrink(),
              data: (plant) => plant != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _FeaturedCard(plant: plant),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Saved by You section ──────────────────────────────────
          if (savedPlants.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bookmark_rounded,
                          color: AppColors.gold, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Saved by You',
                      style: AppTextStyles.heading3.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${savedPlants.length}',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PlantCard(plant: savedPlants[i], index: i),
                  childCount: savedPlants.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'All Plants',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // Grid count header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${filtered.length} plants',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Plant grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'No plants found',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _PlantCard(
                          plant: filtered[i], index: i),
                      childCount: filtered.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ─── Featured POTD card ───────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final PlantModel plant;
  const _FeaturedCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.plantDetail, extra: plant),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.g2, AppColors.ga],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.g2.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: 0,
              child: Opacity(
                opacity: 0.2,
                child: Text(plant.emoji ?? '🌿',
                    style: const TextStyle(fontSize: 80)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gold2.withOpacity(0.4)),
                  ),
                  child: Text(
                    '🌟 Plant of the Day',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold2,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.commonName,
                      style:
                          AppTextStyles.heading1.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      plant.scientificName,
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.text2,
                          fontStyle: FontStyle.italic,
                          fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to explore →',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.gc),
                    ),
                    Text(plant.emoji ?? '🌿',
                        style: const TextStyle(fontSize: 28)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plant card ───────────────────────────────────────────────────────────────

class _PlantCard extends StatelessWidget {
  final PlantModel plant;
  final int index;
  const _PlantCard({required this.plant, required this.index});

  static const _bgColors = [
    Color(0xFFE8F5ED),
    Color(0xFFFDF8F0),
    Color(0xFFE6F0EA),
    Color(0xFFF5EDE8),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[index % _bgColors.length];

    return GestureDetector(
      onTap: () => context.push(AppRoutes.plantDetail, extra: plant),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji box
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  plant.emoji ?? '🌿',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              plant.commonName,
              style: AppTextStyles.label.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              plant.scientificName,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (plant.uses.medicinal != null)
              _SmallTag(label: 'Medicinal', color: const Color(0xFF2A9D8F))
            else if (plant.uses.culinary != null)
              _SmallTag(label: 'Edible', color: Colors.green.shade600)
            else if (plant.uses.isToxic)
              _SmallTag(label: 'Toxic', color: Colors.red.shade400)
            else
              _SmallTag(label: plant.family, color: AppColors.ga),
          ],
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Shimmer / Error ──────────────────────────────────────────────────────────

class _PotdShimmer extends StatelessWidget {
  const _PotdShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _EncShimmer extends StatelessWidget {
  const _EncShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _B(width: 200, height: 28),
              const SizedBox(height: 16),
              _B(width: double.infinity, height: 46, r: 14),
              const SizedBox(height: 12),
              Row(children: [
                _B(width: 60, height: 32, r: 16),
                const SizedBox(width: 8),
                _B(width: 80, height: 32, r: 16),
              ]),
              const SizedBox(height: 16),
              _B(width: double.infinity, height: 160, r: 20),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: List.generate(
                      6,
                      (_) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _B extends StatelessWidget {
  final double? width;
  final double height;
  final double r;
  const _B({this.width, required this.height, this.r = 12});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );
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

