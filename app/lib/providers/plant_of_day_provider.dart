import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/plant.dart';
import '../data/models/scan.dart';
import '../data/repositories/plant_repo.dart';
import 'scan_stats_provider.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final plantRepoProvider = Provider<PlantRepository>((ref) => PlantRepository());

// ─── Plant of the Day ─────────────────────────────────────────────────────────
/// TODO: Replace with real Supabase query:
/// supabase.from('plants').select().eq('potd_date', today).single()
/// Fallback to random plant if no potd_date matches today.
final plantOfDayProvider = FutureProvider<PlantModel?>((ref) async {
  final repo = ref.read(plantRepoProvider);
  return repo.getPlantOfDay();
});

// ─── All plants (Encyclopedia) ────────────────────────────────────────────────
/// TODO: Replace with real Supabase query:
/// supabase.from('plants').select().order('common_name')
final allPlantsProvider = FutureProvider<List<PlantModel>>((ref) async {
  final repo = ref.read(plantRepoProvider);
  return repo.getAll();
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
