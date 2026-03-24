import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scan.dart';

class ScanRepository {
  final _db = Supabase.instance.client;

  String? get _uid => _db.auth.currentUser?.id;

  Future<List<ScanModel>> getForCurrentUser() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _db
        .from('scans')
        .select('*, plants(common_name, scientific_name, emoji, family)')
        .eq('user_id', uid)
        .order('scanned_at', ascending: false);
    return (rows as List).map((r) => ScanModel.fromJson(r)).toList();
  }

  Future<List<ScanModel>> getRecent({int limit = 3}) async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _db
        .from('scans')
        .select('*, plants(common_name, scientific_name, emoji, family)')
        .eq('user_id', uid)
        .order('scanned_at', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => ScanModel.fromJson(r)).toList();
  }

  Future<int> getTotalScans() async {
    final uid = _uid;
    if (uid == null) return 0;
    final result = await _db
        .from('scans')
        .select('id')
        .eq('user_id', uid)
        .count(CountOption.exact);
    return result.count;
  }

  Future<int> getUniqueSpeciesCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    final rows = await _db
        .from('scans')
        .select('plant_id')
        .eq('user_id', uid);
    final ids = (rows as List).map((r) => r['plant_id']).toSet();
    return ids.length;
  }
}
