import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/scan_stats_provider.dart';
import '../../../providers/plant_of_day_provider.dart';

// ─── Region provider ──────────────────────────────────────────────────────────

final selectedRegionProvider =
    StateNotifierProvider<_RegionNotifier, String?>((ref) => _RegionNotifier());

class _RegionNotifier extends StateNotifier<String?> {
  _RegionNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(StorageKeys.selectedRegion);
  }

  Future<void> setRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.selectedRegion, region);
    state = region;
  }
}

// ─── Indian regions data ──────────────────────────────────────────────────────

const _indianRegions = {
  'Northern India 🏔': [
    'Jammu & Kashmir',
    'Ladakh',
    'Himachal Pradesh',
    'Uttarakhand',
    'Punjab',
    'Haryana',
    'Delhi',
    'Uttar Pradesh',
  ],
  'Western India 🌵': [
    'Rajasthan',
    'Gujarat',
    'Maharashtra',
    'Goa',
    'Dadra & Nagar Haveli',
    'Daman & Diu',
  ],
  'Central India 🌾': [
    'Madhya Pradesh',
    'Chhattisgarh',
  ],
  'Southern India 🌴': [
    'Karnataka',
    'Kerala',
    'Tamil Nadu',
    'Andhra Pradesh',
    'Telangana',
    'Puducherry',
    'Lakshadweep',
  ],
  'Eastern India 🌊': [
    'West Bengal',
    'Odisha',
    'Bihar',
    'Jharkhand',
  ],
  'Northeast India 🍃': [
    'Assam',
    'Meghalaya',
    'Manipur',
    'Mizoram',
    'Nagaland',
    'Tripura',
    'Arunachal Pradesh',
    'Sikkim',
  ],
  'Island Territories 🏝': [
    'Andaman & Nicobar Islands',
  ],
  'Ecological Zones 🌿': [
    'Western Ghats',
    'Eastern Ghats',
    'Himalayan Foothills',
    'Deccan Plateau',
    'Indo-Gangetic Plains',
    'Thar Desert',
    'Sundarbans',
    'Coastal Regions',
  ],
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final statsAsync = ref.watch(scanStatsProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);

    final user = auth.user;
    final displayName = user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        'Plant Lover';
    final email = user?.email ?? '';
    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

    // Member since
    final createdAt = user?.createdAt;
    final memberSince = createdAt != null
        ? _formatMemberSince(createdAt)
        : null;

    return Scaffold(
      backgroundColor: AppColors.warm,
      body: CustomScrollView(
        slivers: [
          // ── Hero ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHero(
              displayName: displayName,
              email: email,
              avatarLetter: avatarLetter,
              selectedRegion: selectedRegion,
              memberSince: memberSince,
            ),
          ),

          // ── Stats ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: statsAsync.when(
                loading: () => const _StatsShimmer(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => _StatsRow(stats: stats),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Region banner ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _RegionBanner(
                selectedRegion: selectedRegion,
                onTap: () => _showRegionSheet(context, ref),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Section label ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'ACCOUNT',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
            ),
          ),

          // ── Menu ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _MenuRow(
                      icon: Icons.bookmark_rounded,
                      iconColor: AppColors.ga,
                      label: 'My Saved Plants',
                      subtitle: 'View your plant collection',
                      onTap: () => _showSavedPlantsSheet(context, ref),
                    ),
                    _Divider(),
                    _MenuRow(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFE07A35),
                      label: 'My Region',
                      subtitle: selectedRegion ?? 'Not set — tap to choose',
                      onTap: () => _showRegionSheet(context, ref),
                    ),
                    _Divider(),
                    _MenuRow(
                      icon: Icons.download_rounded,
                      iconColor: const Color(0xFF4A90D9),
                      label: 'Export History',
                      subtitle: 'Save as CSV and share',
                      onTap: () => _exportHistory(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Section label ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'APP',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  fontSize: 11,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _MenuRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.ga,
                      label: 'About LeafLens',
                      subtitle: 'Version 1.0.0 · Indian Flora Edition',
                      onTap: () => _showAboutSheet(context),
                    ),
                    _Divider(),
                    _MenuRow(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.red.shade400,
                      label: 'Sign Out',
                      subtitle: email.isNotEmpty ? email : 'Sign out of your account',
                      onTap: () => _confirmSignOut(context, ref),
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
                height: 28 + MediaQuery.of(context).padding.bottom),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 3),
    );
  }

  String _formatMemberSince(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _showSavedPlantsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text('My Saved Plants',
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.darkText)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌱',
                          style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(
                        'No saved plants yet',
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.darkText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Scan plants and tap "Save" to\nbuild your collection here.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RegionPickerSheet(
        currentRegion: ref.read(selectedRegionProvider),
        onSelect: (region) async {
          await ref.read(selectedRegionProvider.notifier).setRegion(region);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _exportHistory(BuildContext context, WidgetRef ref) async {
    final scansAsync = ref.read(allScansProvider);
    final scans = scansAsync.asData?.value ?? [];
    if (scans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No scan history to export yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final csv =
        StringBuffer('Plant Name,Scientific Name,Confidence,Mode,Date\n');
    for (final s in scans) {
      csv.writeln(
          '${s.commonName ?? ""},${s.scientificName ?? ""},${(s.confidence * 100).toStringAsFixed(0)}%,${s.scanMode},${s.scannedAt.toIso8601String()}');
    }
    await Share.share(csv.toString(),
        subject: 'LeafLens Scan History');
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.g2, AppColors.ga],
                ),
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 14),
            Text('LeafLens',
                style: AppTextStyles.heading1
                    .copyWith(color: AppColors.darkText)),
            const SizedBox(height: 4),
            Text(
              'Indian Flora Edition · v1.0.0',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.ga, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Identify, learn about, and save Indian plants.\n'
              'Covering flora from the Himalayas to the Western Ghats.',
              style: AppTextStyles.body.copyWith(
                  color: AppColors.mutedText, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ga.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Powered by Pl@ntNet · Wikipedia · GBIF',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.ga),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('🚪', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('Sign Out',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.darkText)),
        ]),
        content: Text(
          'Your scan history and saved plants will stay safe. You can sign back in anytime.',
          style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.splash);
            },
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Profile hero ──────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String displayName;
  final String email;
  final String avatarLetter;
  final String? selectedRegion;
  final String? memberSince;

  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.avatarLetter,
    required this.selectedRegion,
    required this.memberSince,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.g1, AppColors.g2, AppColors.ga],
          stops: [0, 0.5, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative India map watermark feel
            Positioned(
              top: 0,
              right: -20,
              child: Opacity(
                opacity: 0.06,
                child: const Text('🇮🇳',
                    style: TextStyle(fontSize: 160)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile',
                          style: AppTextStyles.heading1
                              .copyWith(fontSize: 20)),
                      if (selectedRegion != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📍',
                                  style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                selectedRegion!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.gb, AppColors.gc],
                      ),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.g1.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name
                  Text(
                    displayName,
                    style: AppTextStyles.heading2.copyWith(
                        fontSize: 20, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),

                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.text2, fontSize: 12),
                    ),
                  ],

                  if (memberSince != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gc.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Member since $memberSince',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.gc, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Region banner ────────────────────────────────────────────────────────────

class _RegionBanner extends StatelessWidget {
  final String? selectedRegion;
  final VoidCallback onTap;

  const _RegionBanner(
      {required this.selectedRegion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasRegion = selectedRegion != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasRegion
                ? [
                    const Color(0xFFFF6B35).withOpacity(0.08),
                    const Color(0xFF138808).withOpacity(0.08),
                  ]
                : [AppColors.warm, AppColors.warm],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasRegion
                ? const Color(0xFF138808).withOpacity(0.25)
                : const Color(0xFFE0E0E0),
          ),
          color: hasRegion ? null : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasRegion
                    ? const Color(0xFF138808).withOpacity(0.1)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🇮🇳', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasRegion ? 'Your Region' : 'Set Your Indian Region',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasRegion
                        ? selectedRegion!
                        : 'Personalise plant recommendations',
                    style: AppTextStyles.label.copyWith(
                      color: hasRegion
                          ? AppColors.darkText
                          : AppColors.mutedText,
                      fontWeight: hasRegion
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasRegion
                  ? Icons.edit_rounded
                  : Icons.chevron_right_rounded,
              color: hasRegion ? AppColors.ga : AppColors.mutedText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Region picker sheet ──────────────────────────────────────────────────────

class _RegionPickerSheet extends StatefulWidget {
  final String? currentRegion;
  final ValueChanged<String> onSelect;

  const _RegionPickerSheet({
    required this.currentRegion,
    required this.onSelect,
  });

  @override
  State<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<_RegionPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = <String, List<String>>{};
    for (final entry in _indianRegions.entries) {
      final matches = entry.value
          .where((s) =>
              _search.isEmpty ||
              s.toLowerCase().contains(_search.toLowerCase()))
          .toList();
      if (matches.isNotEmpty) {
        filtered[entry.key] = matches;
      }
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set My Region',
                            style: AppTextStyles.heading2
                                .copyWith(color: AppColors.darkText),
                          ),
                          Text(
                            'Choose your state or ecological zone',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search state or zone...',
                    hintStyle: AppTextStyles.body
                        .copyWith(color: AppColors.mutedText),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.mutedText, size: 20),
                    filled: true,
                    fillColor: AppColors.warm,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.darkText),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: filtered.entries
                  .fold<int>(0, (sum, e) => sum + 1 + e.value.length),
              itemBuilder: (_, index) {
                int cursor = 0;
                for (final entry in filtered.entries) {
                  if (index == cursor) {
                    // Zone header
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                      child: Text(
                        entry.key,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.ga,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  cursor++;
                  if (index < cursor + entry.value.length) {
                    final state = entry.value[index - cursor];
                    final isSelected = state == widget.currentRegion;
                    return _RegionTile(
                      label: state,
                      isSelected: isSelected,
                      onTap: () => widget.onSelect(state),
                    );
                  }
                  cursor += entry.value.length;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ga.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.ga.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: isSelected ? AppColors.ga : AppColors.darkText,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.ga, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ScanStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: '🔍',
            label: 'Scanned',
            value: stats.totalScans.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            icon: '🌿',
            label: 'Species',
            value: stats.uniqueSpecies.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            icon: '❤️',
            label: 'Saved',
            value: stats.saved.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatBox(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.ga,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.mutedText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Menu row ─────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: isDestructive
                          ? Colors.red.shade600
                          : AppColors.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedText, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive
                  ? Colors.red.shade200
                  : const Color(0xFFD0D0D0),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0,
      indent: 68,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

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
              _NI(icon: Icons.home_rounded, label: 'Home', active: currentIndex == 0, onTap: () => context.go(AppRoutes.home)),
              _NI(icon: Icons.camera_alt_rounded, label: 'Scan', active: currentIndex == 1, onTap: () => context.go(AppRoutes.scan)),
              _NI(icon: Icons.menu_book_rounded, label: 'Encyclopedia', active: currentIndex == 2, onTap: () => context.go(AppRoutes.encyclopedia)),
              _NI(icon: Icons.person_rounded, label: 'Profile', active: currentIndex == 3, onTap: () => context.go(AppRoutes.profile)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NI extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NI({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: active ? AppColors.gc : AppColors.text3, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: active ? AppColors.gc : AppColors.text3,
                  fontSize: 10)),
        ]),
      ),
    );
  }
}
