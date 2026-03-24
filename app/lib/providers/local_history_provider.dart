import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/plant.dart';

// ─── History entry ─────────────────────────────────────────────────────────

class HistoryEntry {
  final PlantModel plant;
  final DateTime scannedAt;

  const HistoryEntry({required this.plant, required this.scannedAt});

  Map<String, dynamic> toJson() => {
        'plant': plant.toJson(),
        'scanned_at': scannedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        plant: PlantModel.fromJson(json['plant'] as Map<String, dynamic>),
        scannedAt: DateTime.parse(json['scanned_at'] as String),
      );
}

// ─── History notifier ──────────────────────────────────────────────────────

class _HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  static const _key = 'local_scan_history_v2';

  _HistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = json.decode(raw) as List;
      state = decoded
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, json.encode(state.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> add(PlantModel plant) async {
    final entry = HistoryEntry(plant: plant, scannedAt: DateTime.now());
    // Most recent first, dedup by id
    state = [entry, ...state.where((e) => e.plant.id != plant.id)];
    await _persist();
  }

  Future<void> remove(String plantId) async {
    state = state.where((e) => e.plant.id != plantId).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ─── Saved plants notifier ─────────────────────────────────────────────────

class _SavedNotifier extends StateNotifier<List<PlantModel>> {
  static const _key = 'local_saved_plants_v2';

  _SavedNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = json.decode(raw) as List;
      state = decoded
          .map((e) => PlantModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, json.encode(state.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> add(PlantModel plant) async {
    if (state.any((p) => p.id == plant.id)) return; // no duplicates
    state = [...state, plant];
    await _persist();
  }

  Future<void> remove(String plantId) async {
    state = state.where((p) => p.id != plantId).toList();
    await _persist();
  }

  bool contains(String plantId) => state.any((p) => p.id == plantId);
}

// ─── Providers ─────────────────────────────────────────────────────────────

final localHistoryProvider =
    StateNotifierProvider<_HistoryNotifier, List<HistoryEntry>>(
  (ref) => _HistoryNotifier(),
);

final localSavedPlantsProvider =
    StateNotifierProvider<_SavedNotifier, List<PlantModel>>(
  (ref) => _SavedNotifier(),
);
