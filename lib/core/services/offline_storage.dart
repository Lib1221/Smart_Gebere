import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Offline-first storage service using Hive.
/// Provides local caching with sync queue for when connectivity returns.
class OfflineStorage {
  static const String _cropSuggestionsBox = 'crop_suggestions';
  static const String _diseaseResultsBox = 'disease_results';
  static const String _weatherCacheBox = 'weather_cache';
  static const String _farmProfileBox = 'farm_profile';
  static const String _marketPricesBox = 'market_prices';
  static const String _farmRecordsBox = 'farm_records';
  static const String _knowledgeBaseBox = 'knowledge_base';
  static const String _syncQueueBox = 'sync_queue';
  static const String _userPrefsBox = 'user_prefs';

  static bool _initialized = false;

  /// Initialize Hive for Flutter
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    
    // Open all boxes
    await Future.wait([
      Hive.openBox<String>(_cropSuggestionsBox),
      Hive.openBox<String>(_diseaseResultsBox),
      Hive.openBox<String>(_weatherCacheBox),
      Hive.openBox<String>(_farmProfileBox),
      Hive.openBox<String>(_marketPricesBox),
      Hive.openBox<String>(_farmRecordsBox),
      Hive.openBox<String>(_knowledgeBaseBox),
      Hive.openBox<String>(_syncQueueBox),
      Hive.openBox<String>(_userPrefsBox),
    ]);
    
    _initialized = true;
    debugPrint('[OfflineStorage] Initialized all Hive boxes');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Generic CRUD
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> save(String boxName, String key, Map<String, dynamic> data) async {
    final box = Hive.box<String>(boxName);
    await box.put(key, jsonEncode(data));
  }

  static Map<String, dynamic>? get(String boxName, String key) {
    final box = Hive.box<String>(boxName);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> getAll(String boxName) {
    final box = Hive.box<String>(boxName);
    final results = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        try {
          results.add(jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
    return results;
  }

  static Future<void> delete(String boxName, String key) async {
    final box = Hive.box<String>(boxName);
    await box.delete(key);
  }

  static Future<void> clearBox(String boxName) async {
    final box = Hive.box<String>(boxName);
    await box.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Crop Suggestions Cache
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cacheCropSuggestions(String locationKey, List<Map<String, dynamic>> crops) async {
    await save(_cropSuggestionsBox, locationKey, {
      'crops': crops,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>>? getCachedCropSuggestions(String locationKey, {Duration maxAge = const Duration(hours: 24)}) {
    final data = get(_cropSuggestionsBox, locationKey);
    if (data == null) return null;
    
    final cachedAt = DateTime.tryParse(data['cachedAt'] ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > maxAge) {
      return null; // Expired
    }
    
    return (data['crops'] as List?)?.cast<Map<String, dynamic>>();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Disease Results Cache
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cacheDiseaseResult(String id, Map<String, dynamic> result) async {
    await save(_diseaseResultsBox, id, {
      ...result,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> getAllDiseaseResults() {
    return getAll(_diseaseResultsBox);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Weather Cache
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cacheWeather(String locationKey, Map<String, dynamic> weather) async {
    await save(_weatherCacheBox, locationKey, {
      ...weather,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  static Map<String, dynamic>? getCachedWeather(String locationKey, {Duration maxAge = const Duration(hours: 3)}) {
    final data = get(_weatherCacheBox, locationKey);
    if (data == null) return null;
    
    final cachedAt = DateTime.tryParse(data['cachedAt'] ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > maxAge) {
      return null;
    }
    
    return data;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Farm Profile
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> saveFarmProfile(Map<String, dynamic> profile) async {
    await save(_farmProfileBox, 'current', profile);
  }

  static Map<String, dynamic>? getFarmProfile() {
    return get(_farmProfileBox, 'current');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Market Prices
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cacheMarketPrices(String region, List<Map<String, dynamic>> prices) async {
    await save(_marketPricesBox, region, {
      'prices': prices,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>>? getCachedMarketPrices(String region, {Duration maxAge = const Duration(hours: 12)}) {
    final data = get(_marketPricesBox, region);
    if (data == null) return null;
    
    final cachedAt = DateTime.tryParse(data['cachedAt'] ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > maxAge) {
      return null;
    }
    
    return (data['prices'] as List?)?.cast<Map<String, dynamic>>();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Farm Records
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> saveFarmRecord(String id, Map<String, dynamic> record) async {
    await save(_farmRecordsBox, id, record);
  }

  static List<Map<String, dynamic>> getAllFarmRecords() {
    return getAll(_farmRecordsBox);
  }

  static Future<void> deleteFarmRecord(String id) async {
    await delete(_farmRecordsBox, id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Knowledge Base
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> cacheKnowledgeArticle(String id, Map<String, dynamic> article) async {
    await save(_knowledgeBaseBox, id, article);
  }

  static List<Map<String, dynamic>> getAllKnowledgeArticles() {
    return getAll(_knowledgeBaseBox);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sync Queue (for offline-created data to sync when online)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> addToSyncQueue(String type, Map<String, dynamic> data) async {
    final id = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    await save(_syncQueueBox, id, {
      'type': type,
      'data': data,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    return getAll(_syncQueueBox);
  }

  static Future<void> removeFromSyncQueue(String id) async {
    await delete(_syncQueueBox, id);
  }

  static Future<void> clearSyncQueue() async {
    await clearBox(_syncQueueBox);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // User Preferences
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> setUserPref(String key, dynamic value) async {
    await save(_userPrefsBox, key, {'value': value});
  }

  static T? getUserPref<T>(String key) {
    final data = get(_userPrefsBox, key);
    return data?['value'] as T?;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Box names for external access
  // ─────────────────────────────────────────────────────────────────────────

  static String get cropSuggestionsBox => _cropSuggestionsBox;
  static String get diseaseResultsBox => _diseaseResultsBox;
  static String get weatherCacheBox => _weatherCacheBox;
  static String get farmProfileBox => _farmProfileBox;
  static String get marketPricesBox => _marketPricesBox;
  static String get farmRecordsBox => _farmRecordsBox;
  static String get knowledgeBaseBox => _knowledgeBaseBox;
  static String get syncQueueBox => _syncQueueBox;
}

