import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/models/plant.dart';
import '../../../providers/saved_plants_provider.dart';

class PlantDetailScreen extends ConsumerStatefulWidget {
  final PlantModel plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  ConsumerState<PlantDetailScreen> createState() =>
      _PlantDetailScreenState();
}

class _PlantDetailScreenState extends ConsumerState<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final savedIdsAsync = ref.watch(savedPlantIdsProvider);
    final isSaved =
        savedIdsAsync.asData?.value.contains(plant.id) ?? false;
    final actions = ref.read(savedPlantsActionsProvider);

    return Scaffold(
      backgroundColor: AppColors.warm,
      body: Column(
        children: [
          // Hero
          _DetailHero(
            plant: plant,
            isFavorited: isSaved,
            onBack: () => context.pop(),
            onFavorite: () async {
              if (isSaved) {
                await actions.unsave(plant.id);
              } else {
                await actions.save(plant.id);
              }
            },
          ),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelStyle: AppTextStyles.label
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  AppTextStyles.label.copyWith(fontSize: 12),
              labelColor: AppColors.ga,
              unselectedLabelColor: AppColors.mutedText,
              indicatorColor: AppColors.ga,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Care'),
                Tab(text: 'Uses'),
                Tab(text: 'Facts'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _DetailOverviewTab(plant: plant),
                _CareTab(care: plant.careData),
                _UsesTab(uses: plant.uses),
                _FactsTab(plant: plant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _DetailHero extends StatelessWidget {
  final PlantModel plant;
  final bool isFavorited;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  const _DetailHero({
    required this.plant,
    required this.isFavorited,
    required this.onBack,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.g2, AppColors.ga],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Large emoji background
            Positioned(
              top: -12,
              right: 12,
              child: Opacity(
                opacity: 0.18,
                child: Text(
                  plant.emoji ?? '🌿',
                  style: const TextStyle(fontSize: 110),
                ),
              ),
            ),

            // Top buttons
            Positioned(
              top: 4,
              left: 4,
              right: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Share.share(
                            '🌿 Check out ${plant.commonName} (${plant.scientificName}) on LeafLens!',
                          );
                        },
                        icon: const Icon(Icons.share_rounded,
                            color: Colors.white),
                      ),
                      IconButton(
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorited
                              ? Colors.red.shade300
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plant.commonName,
                    style: AppTextStyles.heading1.copyWith(fontSize: 24),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plant.scientificName,
                    style: AppTextStyles.body.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.text2,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant.family.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.gc,
                        letterSpacing: 1.2,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Overview tab (expanded) ──────────────────────────────────────────────────

class _DetailOverviewTab extends StatelessWidget {
  final PlantModel plant;
  const _DetailOverviewTab({required this.plant});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plant.regionPills.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: plant.regionPills
                  .map((r) => _Pill(label: r, color: AppColors.ga))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Full Wikipedia description
          if (plant.description.isNotEmpty) ...[
            Text(
              plant.description,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.darkText, height: 1.6),
            ),
            const SizedBox(height: 20),
          ],

          // Data cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _DataCard(
                  icon: '🌍',
                  label: 'Habitat',
                  value: plant.habitat ?? 'Unknown'),
              _DataCard(
                  icon: '📏',
                  label: 'Height',
                  value: plant.height ?? 'Unknown'),
              _DataCard(
                  icon: '🌸',
                  label: 'Bloom Season',
                  value: plant.bloomSeason ?? 'Unknown'),
              _DataCard(
                  icon: '🌡',
                  label: 'Climate',
                  value: plant.climate ?? 'Unknown'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Care tab ─────────────────────────────────────────────────────────────────

class _CareTab extends StatelessWidget {
  final CareData care;
  const _CareTab({required this.care});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _CareCard(icon: '🌱', label: 'Soil', value: care.soil),
          const SizedBox(height: 12),
          _CareCard(icon: '☀️', label: 'Sunlight', value: care.sunlight),
          const SizedBox(height: 12),
          _CareCard(icon: '💧', label: 'Water', value: care.water),
          const SizedBox(height: 12),
          _CareCard(icon: '🧪', label: 'pH Level', value: care.ph),
          const SizedBox(height: 12),
          _CareCard(
              icon: '🌡', label: 'Temperature', value: care.temperature),
        ],
      ),
    );
  }
}

// ─── Uses tab ─────────────────────────────────────────────────────────────────

class _UsesTab extends StatelessWidget {
  final UsesData uses;
  const _UsesTab({required this.uses});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (uses.isToxic)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toxic — keep away from children and pets',
                      style: AppTextStyles.body.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          if (uses.medicinal != null) ...[
            _UsesCard(
                icon: '💊', label: 'Medicinal', value: uses.medicinal!),
            const SizedBox(height: 12),
          ],
          if (uses.culinary != null) ...[
            _UsesCard(
                icon: '🍽', label: 'Culinary', value: uses.culinary!),
            const SizedBox(height: 12),
          ],
          if (uses.cosmetic != null) ...[
            _UsesCard(
                icon: '✨', label: 'Cosmetic', value: uses.cosmetic!),
            const SizedBox(height: 12),
          ],
          if (uses.industrial != null)
            _UsesCard(
                icon: '🏭',
                label: 'Industrial',
                value: uses.industrial!),
          if (uses.medicinal == null &&
              uses.culinary == null &&
              uses.cosmetic == null &&
              uses.industrial == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No specific uses documented',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.mutedText),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Facts tab ────────────────────────────────────────────────────────────────

class _FactsTab extends StatelessWidget {
  final PlantModel plant;
  const _FactsTab({required this.plant});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plant.iucnStatus != null) ...[
            _IucnBadge(status: plant.iucnStatus!),
            const SizedBox(height: 16),
          ],
          if (plant.distributionCountries.isNotEmpty) ...[
            Text('Distribution',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: plant.distributionCountries
                  .map((c) => _Pill(label: c, color: AppColors.gb))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (plant.culturalSignificance != null) ...[
            Text('Cultural Significance',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.ga.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.ga.withOpacity(0.2)),
              ),
              child: Text(
                plant.culturalSignificance!,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.darkText, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (plant.funFacts.isNotEmpty) ...[
            Text('Fun Facts',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...plant.funFacts.map(
              (fact) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌿 ',
                        style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        fact,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.darkText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _DataCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          ]),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
                fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _CareCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedText)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsesCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _UsesCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.ga,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.darkText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IucnBadge extends StatelessWidget {
  final String status;
  const _IucnBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'least concern':
        return Colors.green;
      case 'near threatened':
        return Colors.lime.shade700;
      case 'vulnerable':
        return Colors.orange;
      case 'endangered':
        return Colors.deepOrange;
      case 'critically endangered':
        return Colors.red;
      default:
        return AppColors.ga;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: _color, size: 14),
          const SizedBox(width: 6),
          Text(
            'IUCN: $status',
            style: AppTextStyles.caption.copyWith(
                color: _color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
