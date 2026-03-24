import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/scan_repo.dart';
import '../data/repositories/saved_plants_repo.dart';
import 'local_history_provider.dart';

class ScanStats {
  final int totalScans;
  final int uniqueSpecies;
  final int saved;

  const ScanStats({
    required this.totalScans,
    required this.uniqueSpecies,
    required this.saved,
  });
}

// ─── Repository providers ─────────────────────────────────────────────────────

final scanRepoProvider = Provider<ScanRepository>((ref) => ScanRepository());

final savedPlantsRepoProvider = Provider<SavedPlantsRepository>((ref) => SavedPlantsRepository());

// ─── Stats provider ───────────────────────────────────────────────────────────
/// Reads from local history so stats update immediately after each scan.
final scanStatsProvider = Provider<ScanStats>((ref) {
  final history = ref.watch(localHistoryProvider);
  final saved = ref.watch(localSavedPlantsProvider);
  final uniqueSpecies = history.map((e) => e.plant.id).toSet().length;
  return ScanStats(
    totalScans: history.length,
    uniqueSpecies: uniqueSpecies,
    saved: saved.length,
  );
});
