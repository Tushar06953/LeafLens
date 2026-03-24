import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant.dart';

class PlantRepository {
  final _db = Supabase.instance.client;

  Future<PlantModel?> getById(String id) async {
    final row = await _db
        .from('plants')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return PlantModel.fromJson(row);
  }

  Future<List<PlantModel>> getAll() async {
    final rows = await _db
        .from('plants')
        .select()
        .order('common_name');
    return (rows as List).map((r) => PlantModel.fromJson(r)).toList();
  }

  Future<PlantModel?> getPlantOfDay() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final row = await _db
        .from('plants')
        .select()
        .eq('potd_date', today)
        .maybeSingle();
    if (row != null) return PlantModel.fromJson(row);

    // Fallback: most recently added plant
    final rows = await _db
        .from('plants')
        .select()
        .order('created_at', ascending: false)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return PlantModel.fromJson(rows.first);
  }

  Future<List<PlantModel>> search(String query) async {
    final rows = await _db
        .from('plants')
        .select()
        .or('common_name.ilike.%$query%,scientific_name.ilike.%$query%,family.ilike.%$query%')
        .order('common_name')
        .limit(50);
    return (rows as List).map((r) => PlantModel.fromJson(r)).toList();
  }
}
