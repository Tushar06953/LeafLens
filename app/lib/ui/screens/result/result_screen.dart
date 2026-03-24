import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/plant.dart';
import '../../../providers/saved_plants_provider.dart';
import '../../../providers/local_history_provider.dart';
import '../../../providers/plant_of_day_provider.dart';

class ResultScreen extends ConsumerWidget {
  final PlantModel plant;
  const ResultScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void share() {
      Share.share(
        '🌿 I identified ${plant.commonName} (${plant.scientificName}) '
        'with LeafLens! ${(plant.confidence * 100).toStringAsFixed(0)}% confidence.',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.g1,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ResultHero(
                  plant: plant,
                  onBack: () => context.go(AppRoutes.home),
                  onShare: share,
                ),
              ),
              SliverToBoxAdapter(child: _PlantBody(plant: plant)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _SaveBar(plant: plant),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _ResultHero extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onBack;
  final VoidCallback onShare;

  const _ResultHero({
    required this.plant,
    required this.onBack,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark2, AppColors.ga],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Large faded emoji
            Positioned(
              top: 0, right: 12,
              child: Opacity(
                opacity: 0.15,
                child: Text(plant.emoji ?? '🌿',
                    style: const TextStyle(fontSize: 120)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: back + confidence + share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      Row(
                        children: [
                          _ConfidenceBadge(
                              confidence: plant.confidence),
                          IconButton(
                            onPressed: onShare,
                            icon: const Icon(Icons.share_rounded,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Plant names
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.commonName,
                          style: AppTextStyles.heading1.copyWith(
                              fontSize: 26, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.scientificName,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withAlpha(60)),
                          ),
                          child: Text(
                            plant.family.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gc,
                              letterSpacing: 1.4,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  Color get _badgeColor {
    if (confidence >= 0.85) return AppColors.gc;
    if (confidence >= 0.60) return AppColors.gold2;
    return Colors.orange.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _badgeColor.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _badgeColor.withAlpha(150)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: _badgeColor),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}% Match',
            style: TextStyle(
              color: _badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plant profile body ────────────────────────────────────────────────────────

class _PlantBody extends StatelessWidget {
  final PlantModel plant;
  const _PlantBody({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Description ─────────────────────────────────────────────
        if (plant.description.isNotEmpty) ...[
          _SectionHeader(icon: Icons.info_outline_rounded, title: 'About'),
          _SectionCard(
            child: Text(
              plant.description,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.darkText, height: 1.6),
            ),
          ),
        ],

        // ── Toxicity warning ────────────────────────────────────────
        if (plant.uses.isToxic) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Toxic — keep away from children and pets',
                      style: AppTextStyles.label.copyWith(
                          color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ── Uses ────────────────────────────────────────────────────
        if (plant.uses.medicinal != null ||
            plant.uses.culinary != null ||
            plant.uses.cosmetic != null ||
            plant.uses.industrial != null) ...[
          _SectionHeader(icon: Icons.local_pharmacy_rounded, title: 'Uses'),
          _SectionCard(
            child: Column(
              children: [
                if (plant.uses.medicinal != null) ...[
                  _UseRow(
                    icon: '💊',
                    label: 'Medicinal',
                    value: plant.uses.medicinal!,
                    accent: const Color(0xFF2A9D8F),
                    highlight: true,
                  ),
                  if (plant.uses.culinary != null ||
                      plant.uses.cosmetic != null ||
                      plant.uses.industrial != null)
                    const _Divider(),
                ],
                if (plant.uses.culinary != null) ...[
                  _UseRow(
                      icon: '🍽',
                      label: 'Culinary',
                      value: plant.uses.culinary!,
                      accent: Colors.orange.shade600),
                  if (plant.uses.cosmetic != null ||
                      plant.uses.industrial != null)
                    const _Divider(),
                ],
                if (plant.uses.cosmetic != null) ...[
                  _UseRow(
                      icon: '✨',
                      label: 'Cosmetic',
                      value: plant.uses.cosmetic!,
                      accent: Colors.purple.shade400),
                  if (plant.uses.industrial != null) const _Divider(),
                ],
                if (plant.uses.industrial != null)
                  _UseRow(
                      icon: '🏭',
                      label: 'Industrial',
                      value: plant.uses.industrial!,
                      accent: AppColors.ga),
              ],
            ),
          ),
        ],

        // ── Care ────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.water_drop_rounded, title: 'Care Guide'),
        _SectionCard(
          child: Column(
            children: [
              _CareRow(icon: '🌱', label: 'Soil',
                  value: plant.careData.soil),
              const _Divider(),
              _CareRow(icon: '☀️', label: 'Sunlight',
                  value: plant.careData.sunlight),
              const _Divider(),
              _CareRow(icon: '💧', label: 'Water',
                  value: plant.careData.water),
              const _Divider(),
              _CareRow(icon: '🧪', label: 'pH Level',
                  value: plant.careData.ph),
              const _Divider(),
              _CareRow(icon: '🌡', label: 'Temperature',
                  value: plant.careData.temperature),
            ],
          ),
        ),

        // ── Habitat & Bloom ─────────────────────────────────────────
        if (plant.habitat != null || plant.bloomSeason != null) ...[
          _SectionHeader(icon: Icons.eco_rounded, title: 'Growing Info'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (plant.habitat != null)
                  Expanded(
                    child: _InfoTile(
                        icon: '🌍',
                        label: 'Habitat',
                        value: plant.habitat!),
                  ),
                if (plant.habitat != null && plant.bloomSeason != null)
                  const SizedBox(width: 12),
                if (plant.bloomSeason != null)
                  Expanded(
                    child: _InfoTile(
                        icon: '🌸',
                        label: 'Bloom',
                        value: plant.bloomSeason!),
                  ),
              ],
            ),
          ),
        ],

        // ── Distribution ────────────────────────────────────────────
        if (plant.distributionCountries.isNotEmpty ||
            plant.regionPills.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.public_rounded, title: 'Distribution'),
          _SectionCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...plant.distributionCountries.map(
                  (c) => _Chip(label: c, color: AppColors.gb),
                ),
                ...plant.regionPills
                    .where((r) =>
                        !plant.distributionCountries.contains(r))
                    .map((r) => _Chip(label: r, color: AppColors.ga)),
              ],
            ),
          ),
        ],

        // ── Cultural significance ────────────────────────────────────
        if (plant.culturalSignificance != null) ...[
          _SectionHeader(
              icon: Icons.auto_stories_rounded,
              title: 'Cultural Significance'),
          _SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 60,
                  margin: const EdgeInsets.only(right: 14, top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text(
                    plant.culturalSignificance!,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.darkText, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── IUCN status ─────────────────────────────────────────────
        if (plant.iucnStatus != null) ...[
          _SectionHeader(
              icon: Icons.shield_outlined, title: 'Conservation'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _IucnBadge(status: plant.iucnStatus!),
          ),
        ],

        // ── Fun facts ────────────────────────────────────────────────
        if (plant.funFacts.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.lightbulb_outline_rounded, title: 'Fun Facts'),
          _SectionCard(
            child: Column(
              children: plant.funFacts.asMap().entries.map((e) {
                final isLast = e.key == plant.funFacts.length - 1;
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: AppColors.ga.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                color: AppColors.ga,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value,
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.darkText, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) const _Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Save bar ─────────────────────────────────────────────────────────────────

class _SaveBar extends ConsumerStatefulWidget {
  final PlantModel plant;
  const _SaveBar({required this.plant});

  @override
  ConsumerState<_SaveBar> createState() => _SaveBarState();
}

class _SaveBarState extends ConsumerState<_SaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool isSaved) async {
    await _scaleCtrl.forward();
    await _scaleCtrl.reverse();

    if (isSaved) {
      // Unsave
      ref.read(localSavedPlantsProvider.notifier).remove(widget.plant.id);
      try {
        await ref.read(savedPlantsActionsProvider).unsave(widget.plant.id);
      } catch (_) {}
      ref.invalidate(allPlantsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from collection'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      // Save locally first (works without Supabase)
      await ref
          .read(localSavedPlantsProvider.notifier)
          .add(widget.plant);
      // Also try Supabase (silent failure if no auth)
      try {
        await ref.read(savedPlantsActionsProvider).save(widget.plant.id);
      } catch (_) {}
      ref.invalidate(allPlantsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.bookmark_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Plant saved to your collection!'),
              ],
            ),
            backgroundColor: AppColors.ga,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedIdsAsync = ref.watch(savedPlantIdsProvider);
    final isSaved = savedIdsAsync.asData?.value.contains(widget.plant.id) ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE8E8E8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isSaved ? AppColors.g3 : AppColors.gb,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _toggle(isSaved),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              key: ValueKey(isSaved),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              isSaved ? '✓ Saved to Collection' : 'Save Plant',
                              key: ValueKey(isSaved),
                              style: AppTextStyles.button
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.g2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.g3),
            ),
            child: IconButton(
              onPressed: () {
                Share.share(
                  '🌿 I identified ${widget.plant.commonName} '
                  '(${widget.plant.scientificName}) with LeafLens!',
                );
              },
              icon: const Icon(Icons.ios_share_rounded,
                  color: AppColors.darkText, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared section widgets ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.ga.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.ga, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _UseRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color accent;
  final bool highlight;

  const _UseRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: highlight
          ? const EdgeInsets.symmetric(vertical: 4, horizontal: 10)
          : const EdgeInsets.symmetric(vertical: 4),
      decoration: highlight
          ? BoxDecoration(
              color: accent.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border(
                  left: BorderSide(color: accent, width: 3)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                      color: accent, fontWeight: FontWeight.w700,
                      fontSize: 11, letterSpacing: 0.5),
                ),
                const SizedBox(height: 3),
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

class _CareRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _CareRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.darkText, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedText)),
          ]),
          const SizedBox(height: 5),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Divider(color: Color(0xFFF0F0F0), height: 1),
    );
  }
}

class _IucnBadge extends StatelessWidget {
  final String status;
  const _IucnBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'least concern':
        return Colors.green.shade600;
      case 'near threatened':
        return Colors.lime.shade700;
      case 'vulnerable':
        return Colors.orange.shade600;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, color: _color, size: 16),
          const SizedBox(width: 7),
          Text(
            'IUCN Status: $status',
            style: AppTextStyles.caption.copyWith(
                color: _color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
