import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/plant.dart';
import '../data/models/scan.dart';
import '../data/repositories/plant_repo.dart';
import 'scan_stats_provider.dart';
import 'local_history_provider.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final plantRepoProvider = Provider<PlantRepository>((ref) => PlantRepository());

// ─── Plant of the Day ─────────────────────────────────────────────────────────
final plantOfDayProvider = FutureProvider<PlantModel?>((ref) async {
  final repo = ref.read(plantRepoProvider);
  return repo.getPlantOfDay();
});

// ─── All plants (Encyclopedia) ────────────────────────────────────────────────
/// Merges Supabase/seed plants with locally saved plants from the device.
final allPlantsProvider = FutureProvider<List<PlantModel>>((ref) async {
  // React to changes in locally saved plants
  final localSaved = ref.watch(localSavedPlantsProvider);
  final repo = ref.read(plantRepoProvider);
  final fromDb = await repo.getAll(); // includes seed fallback

  // Append locally saved plants that aren't already in the list
  final existingIds = fromDb.map((p) => p.id).toSet();
  final extra = localSaved.where((p) => !existingIds.contains(p.id)).toList();
  return [...fromDb, ...extra];
});

// ─── Recent scans ─────────────────────────────────────────────────────────────
/// TODO: Replace with real Supabase StreamProvider:
/// supabase.from('scans').stream(primaryKey: ['id']).eq('user_id', uid).order('scanned_at').limit(3)
final recentScansProvider = FutureProvider<List<ScanModel>>((ref) async {
  final repo = ref.read(scanRepoProvider);
  return repo.getRecent(limit: 3);
});

final allScansProvider = FutureProvider<List<ScanModel>>((ref) async {
  final repo = ref.read(scanRepoProvider);
  return repo.getForCurrentUser();
});
