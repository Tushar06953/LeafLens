import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/scan_repo.dart';
import '../data/repositories/saved_plants_repo.dart';

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
/// TODO: When real Supabase is wired, switch this to a StreamProvider
/// watching the scans table so stats update in real time.
final scanStatsProvider = FutureProvider<ScanStats>((ref) async {
  final scanRepo = ref.read(scanRepoProvider);
  final savedRepo = ref.read(savedPlantsRepoProvider);

  final results = await Future.wait([
    scanRepo.getTotalScans(),
    scanRepo.getUniqueSpeciesCount(),
    savedRepo.getSavedCount(),
  ]);

  return ScanStats(
    totalScans: results[0],
    uniqueSpecies: results[1],
    saved: results[2],
  );
});
