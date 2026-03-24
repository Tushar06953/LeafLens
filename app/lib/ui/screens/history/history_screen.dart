import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/local_history_provider.dart';
import '../../widgets/bottom_nav.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(localHistoryProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.g1,
        body: SafeArea(
          child: Column(
            children: [
              _Header(count: history.length),
              Expanded(
                child: history.isEmpty
                    ? _EmptyState(onScan: () => context.go(AppRoutes.scan))
                    : _HistoryList(history: history),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 2),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('History',
                  style: AppTextStyles.heading1
                      .copyWith(color: AppColors.darkText)),
              Text(
                '$count scan${count == 1 ? '' : 's'}',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
          if (count > 0)
            TextButton.icon(
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                textStyle:
                    AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear History?'),
        content: const Text('All scan records will be deleted from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(localHistoryProvider.notifier).clear();
              Navigator.of(ctx).pop();
            },
            child: Text('Clear',
                style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}

// ─── History list ─────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<HistoryEntry> history;
  const _HistoryList({required this.history});

  String _groupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(entryDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    return 'Older';
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<HistoryEntry>>{};
    for (final e in history) {
      final label = _groupLabel(e.scannedAt);
      groups.putIfAbsent(label, () => []).add(e);
    }
    final order = ['Today', 'Yesterday', 'This Week', 'Older'];
    final sortedKeys = order.where((k) => groups.containsKey(k)).toList();

    final items = <Widget>[];

    // "Last Scan" pinned highlight — first item
    final latest = history.first;
    items.add(_LastScanBanner(entry: latest));

    for (final key in sortedKeys) {
      items.add(_DateHeader(label: key));
      for (final entry in groups[key]!) {
        items.add(_HistoryCard(entry: entry));
      }
    }
    items.add(const SizedBox(height: 16));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      children: items,
    );
  }
}

// ─── Last Scan banner ─────────────────────────────────────────────────────────

class _LastScanBanner extends StatelessWidget {
  final HistoryEntry entry;
  const _LastScanBanner({required this.entry});

  @override
  Widget build(BuildContext context) {
    final plant = entry.plant;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.plantDetail, extra: plant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.dark2, AppColors.ga],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.ga.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -8, right: 0,
              child: Opacity(
                opacity: 0.15,
                child: Text(plant.emoji ?? '🌿',
                    style: const TextStyle(fontSize: 80)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Text('Last Scan',
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _ConfBadge(confidence: plant.confidence),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  plant.commonName,
                  style: AppTextStyles.heading1
                      .copyWith(fontSize: 20, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  plant.scientificName,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: Colors.white54, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(entry.scannedAt),
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white54),
                    ),
                    const Spacer(),
                    Text(
                      'View details →',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.gc,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Date section header ──────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
            color: AppColors.mutedText, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── History card ─────────────────────────────────────────────────────────────

class _HistoryCard extends ConsumerWidget {
  final HistoryEntry entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plant = entry.plant;

    return Dismissible(
      key: Key(plant.id + entry.scannedAt.toIso8601String()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(localHistoryProvider.notifier).remove(plant.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.commonName} removed'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade400, size: 22),
            const SizedBox(height: 2),
            Text('Delete',
                style: AppTextStyles.caption
                    .copyWith(color: Colors.red.shade400)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.plantDetail, extra: plant),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x07000000),
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              // Emoji box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.g2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    plant.emoji ?? '🌿',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + scientific name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.commonName,
                      style: AppTextStyles.label.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w600),
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
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.scannedAt),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedText, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Confidence + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ConfBadge(confidence: plant.confidence),
                  const SizedBox(height: 6),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.mutedText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ─── Confidence badge ─────────────────────────────────────────────────────────

class _ConfBadge extends StatelessWidget {
  final double confidence;
  const _ConfBadge({required this.confidence});

  Color get _color {
    if (confidence >= 0.85) return AppColors.ga;
    if (confidence >= 0.60) return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withAlpha(80)),
      ),
      child: Text(
        '${(confidence * 100).toStringAsFixed(0)}%',
        style: TextStyle(
            color: _color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.g2,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 24),
            Text('No scans yet',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.darkText)),
            const SizedBox(height: 8),
            Text(
              'Scanned plants will appear here.\nTap below to identify your first plant!',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.camera_alt_rounded,
                  size: 18, color: Colors.white),
              label: Text(
                'Scan your first plant',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gb,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
