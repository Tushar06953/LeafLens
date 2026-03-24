import 'package:supabase_flutter/supabase_flutter.dart';

class SavedPlantsRepository {
  final _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  Future<List<String>> getSavedPlantIds() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _db
        .from('saved_plants')
        .select('plant_id')
        .eq('user_id', uid);
    return (rows as List).map((r) => r['plant_id'] as String).toList();
  }

  Future<int> getSavedCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    final result = await _db
        .from('saved_plants')
        .select('plant_id')
        .eq('user_id', uid)
        .count(CountOption.exact);
    return result.count;
  }

  Future<void> save(String plantId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('saved_plants').upsert({
      'user_id': uid,
      'plant_id': plantId,
    }, onConflict: 'user_id, plant_id');
  }

  Future<void> unsave(String plantId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .from('saved_plants')
        .delete()
        .eq('user_id', uid)
        .eq('plant_id', plantId);
  }

  Future<bool> isSaved(String plantId) async {
    final uid = _uid;
    if (uid == null) return false;
    final result = await _db
        .from('saved_plants')
        .select('plant_id')
        .eq('user_id', uid)
        .eq('plant_id', plantId)
        .count(CountOption.exact);
    return result.count > 0;
  }
}
