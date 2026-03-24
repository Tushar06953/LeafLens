import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scan_stats_provider.dart';
import 'local_history_provider.dart';

// ─── Saved plant IDs ──────────────────────────────────────────────────────────
/// Merges local + Supabase saved plant IDs.
final savedPlantIdsProvider = FutureProvider<List<String>>((ref) async {
  // Watch local saved so the provider updates when local state changes
  final localSaved = ref.watch(localSavedPlantsProvider);
  final localIds = localSaved.map((p) => p.id).toList();

  List<String> remoteIds = [];
  try {
    final repo = ref.read(savedPlantsRepoProvider);
    remoteIds = await repo.getSavedPlantIds();
  } catch (_) {}

  return {...localIds, ...remoteIds}.toList();
});

// ─── Save / unsave action ─────────────────────────────────────────────────────
/// TODO: After save/unsave, invalidate savedPlantIdsProvider and scanStatsProvider
/// so UI updates automatically.
final savedPlantsActionsProvider = Provider((ref) => _SavedPlantsActions(ref));

class _SavedPlantsActions {
  final Ref _ref;
  _SavedPlantsActions(this._ref);

  Future<void> save(String plantId) async {
    final repo = _ref.read(savedPlantsRepoProvider);
    await repo.save(plantId);
    _ref.invalidate(savedPlantIdsProvider);
    _ref.invalidate(scanStatsProvider);
  }

  Future<void> unsave(String plantId) async {
    final repo = _ref.read(savedPlantsRepoProvider);
    await repo.unsave(plantId);
    _ref.invalidate(savedPlantIdsProvider);
    _ref.invalidate(scanStatsProvider);
  }

  Future<bool> isSaved(String plantId) async {
    final repo = _ref.read(savedPlantsRepoProvider);
    return repo.isSaved(plantId);
  }
}
