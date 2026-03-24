import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/plant.dart';
import '../../../data/models/scan.dart';
import '../../../providers/scan_stats_provider.dart';
import '../../../providers/plant_of_day_provider.dart';
import '../../widgets/bottom_nav.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(scanStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.g1,
      body: statsAsync.when(
        loading: () => const _HomeShimmer(),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(scanStatsProvider)),
        data: (stats) => stats.totalScans == 0
            ? const _EmptyHomeBody()
            : const _FilledHomeBody(),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyHomeBody extends ConsumerWidget {
  const _EmptyHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final potdAsync = ref.watch(plantOfDayProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _Header(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: _OrbitIllustration(onScan: () => context.go(AppRoutes.scan)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const _TipsStrip(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: potdAsync.when(
              loading: () => const _PotdShimmer(),
              error: (e, st) => const SizedBox.shrink(),
              data: (plant) => plant != null ? _PotdCard(plant: plant) : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Filled State ─────────────────────────────────────────────────────────────

class _FilledHomeBody extends ConsumerWidget {
  const _FilledHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(scanStatsProvider);
    final recentAsync = ref.watch(recentScansProvider);
    final potdAsync = ref.watch(plantOfDayProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _Header(),
            ),
          ),
        ),
        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: statsAsync.when(
              loading: () => const _StatsShimmer(),
              error: (e, st) => const SizedBox.shrink(),
              data: (stats) => _StatsRow(stats: stats),
            ),
          ),
        ),
        // Scan Now button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.scan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gb,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.g1),
                  const SizedBox(width: 8),
                  Text('Scan Now', style: AppTextStyles.button.copyWith(color: AppColors.g1)),
                ],
              ),
            ),
          ),
        ),
        // Recent Scans
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            child: Text('Recent Scans', style: AppTextStyles.heading1.copyWith(fontSize: 20, color: AppColors.cream)),
          ),
        ),
        recentAsync.when(
          loading: () => SliverToBoxAdapter(child: const _RecentShimmer()),
          error: (e, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (scans) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _HistoryItem(scan: scans[i]),
              ),
              childCount: scans.length,
            ),
          ),
        ),
        // Plant of Day
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: potdAsync.when(
              loading: () => const _PotdShimmer(),
              error: (e, st) => const SizedBox.shrink(),
              data: (plant) => plant != null ? _PotdCard(plant: plant) : const SizedBox.shrink(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello 🌿', style: AppTextStyles.heading1.copyWith(fontSize: 24, color: AppColors.cream)),
            Text('What plant is that?', style: AppTextStyles.bodySmall),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.g3,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: AppColors.gc, size: 22),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ScanStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'Scanned', value: '${stats.totalScans}')),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Species', value: '${stats.uniqueSpecies}')),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Saved', value: '${stats.saved}')),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.g2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.g3),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.display.copyWith(fontSize: 28, color: AppColors.gc)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _OrbitIllustration extends StatefulWidget {
  final VoidCallback onScan;
  const _OrbitIllustration({required this.onScan});

  @override
  State<_OrbitIllustration> createState() => _OrbitIllustrationState();
}

class _OrbitIllustrationState extends State<_OrbitIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer dashed ring
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.rotate(
                  angle: _ctrl.value * 2 * math.pi,
                  child: child,
                ),
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _DashedRing(color: AppColors.g3, dashCount: 20),
                ),
              ),
              // Inner ring
              CustomPaint(
                size: const Size(140, 140),
                painter: _DashedRing(color: AppColors.ga, dashCount: 14),
              ),
              // Center
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.ga, AppColors.gb],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(child: Text('🌿', style: TextStyle(fontSize: 40))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Identify Your First Plant', style: AppTextStyles.heading1.copyWith(fontSize: 22)),
        const SizedBox(height: 10),
        Text(
          'Point your camera at any plant and\ndiscover its name, care guide and more.',
          style: AppTextStyles.bodySmall.copyWith(height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: widget.onScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gb,
            minimumSize: const Size(200, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.g1),
              const SizedBox(width: 8),
              Text('Scan a Plant', style: AppTextStyles.button.copyWith(color: AppColors.g1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipsStrip extends StatelessWidget {
  const _TipsStrip();

  static const _tips = <(String, String)>[
    ('☀️', 'Good lighting'),
    ('🌿', 'Full plant visible'),
    ('🔍', 'Clear background'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.g2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.g3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _tips
            .map((tip) => Column(
                  children: [
                    Text(tip.$1, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(tip.$2, style: AppTextStyles.caption.copyWith(color: AppColors.text2)),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _PotdCard extends StatelessWidget {
  final PlantModel plant;
  const _PotdCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.g2, AppColors.g3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.g1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(plant.emoji ?? '🌿', style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Text('Plant of the Day', style: AppTextStyles.caption.copyWith(color: AppColors.gold2)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(plant.commonName, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                Text(plant.scientificName,
                    style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold2, size: 14),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ScanModel scan;
  const _HistoryItem({required this.scan});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.ga, AppColors.g3, AppColors.gb];
    final colorIndex = scan.plantId.hashCode % colors.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.g2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.g3),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors[colorIndex],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(scan.emoji ?? '🌿', style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.commonName ?? 'Unknown', style: AppTextStyles.label),
                Text(scan.scientificName ?? '', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gc.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(scan.confidence * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(color: AppColors.gc),
                ),
              ),
              const SizedBox(height: 4),
              Text(_timeAgo(scan.scannedAt), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Shimmer / Loading / Error ────────────────────────────────────────────────

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.g2,
      highlightColor: AppColors.g3,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _ShimmerBox(width: 120, height: 22),
                    const SizedBox(height: 6),
                    _ShimmerBox(width: 160, height: 14),
                  ]),
                  _ShimmerBox(width: 40, height: 40, radius: 12),
                ],
              ),
              const SizedBox(height: 28),
              // Stats
              Row(children: [
                Expanded(child: _ShimmerBox(height: 72)),
                const SizedBox(width: 12),
                Expanded(child: _ShimmerBox(height: 72)),
                const SizedBox(width: 12),
                Expanded(child: _ShimmerBox(height: 72)),
              ]),
              const SizedBox(height: 20),
              _ShimmerBox(width: double.infinity, height: 52),
              const SizedBox(height: 28),
              _ShimmerBox(width: 120, height: 20),
              const SizedBox(height: 12),
              _ShimmerBox(width: double.infinity, height: 72),
              const SizedBox(height: 8),
              _ShimmerBox(width: double.infinity, height: 72),
              const SizedBox(height: 8),
              _ShimmerBox(width: double.infinity, height: 72),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.g2,
      highlightColor: AppColors.g3,
      child: Row(children: [
        Expanded(child: _ShimmerBox(height: 72)),
        const SizedBox(width: 12),
        Expanded(child: _ShimmerBox(height: 72)),
        const SizedBox(width: 12),
        Expanded(child: _ShimmerBox(height: 72)),
      ]),
    );
  }
}

class _RecentShimmer extends StatelessWidget {
  const _RecentShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.g2,
      highlightColor: AppColors.g3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          _ShimmerBox(width: double.infinity, height: 72),
          const SizedBox(height: 8),
          _ShimmerBox(width: double.infinity, height: 72),
          const SizedBox(height: 8),
          _ShimmerBox(width: double.infinity, height: 72),
        ]),
      ),
    );
  }
}

class _PotdShimmer extends StatelessWidget {
  const _PotdShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.g2,
      highlightColor: AppColors.g3,
      child: _ShimmerBox(width: double.infinity, height: 88),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _ShimmerBox({this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.g2,
        borderRadius: BorderRadius.circular(radius),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌵', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Something went wrong', style: AppTextStyles.label),
          TextButton(onPressed: onRetry, child: Text('Retry', style: AppTextStyles.body.copyWith(color: AppColors.gc))),
        ],
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  final Color color;
  final int dashCount;

  const _DashedRing({required this.color, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const full = math.pi * 2;
    const gap = 0.4;
    final dash = (full / dashCount) * (1 - gap);
    final gapAngle = (full / dashCount) * gap;

    for (int i = 0; i < dashCount; i++) {
      final start = i * (dash + gapAngle) - math.pi / 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => false;
}
