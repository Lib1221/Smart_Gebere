import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/knowledge_article.dart';
import '../models/market_price.dart';
import 'offline_storage.dart';

/// Content Service for dynamic content updates without app release.
/// Fetches content from Firestore and caches locally for offline access.
class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // App Configuration (Remote Config)
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _appConfig = {};

  /// Fetch app configuration from Firestore
  Future<void> fetchAppConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('app').get();
      if (doc.exists && doc.data() != null) {
        _appConfig = doc.data()!;
        debugPrint('[ContentService] App config loaded: ${_appConfig.keys}');
      }
    } catch (e) {
      debugPrint('[ContentService] Error fetching app config: $e');
    }
  }

  /// Get a config value with fallback
  T getConfig<T>(String key, T fallback) {
    return _appConfig[key] as T? ?? fallback;
  }

  /// Feature flags
  bool isFeatureEnabled(String feature) {
    return _appConfig['features']?[feature] == true;
  }

  /// Get AI model name from config
  String get aiModelName => getConfig('aiModel', 'gemini-1.5-flash');

  /// Get supported languages
  List<String> get supportedLanguages =>
      List<String>.from(getConfig('supportedLanguages', ['en', 'am', 'om']));

  /// Get minimum app version for force update
  String get minAppVersion => getConfig('minAppVersion', '1.0.0');

  /// Get app update message
  String get updateMessage =>
      getConfig('updateMessage', 'Please update to the latest version.');

  /// Check if maintenance mode is enabled
  bool get isMaintenanceMode => getConfig('maintenanceMode', false);

  // ─────────────────────────────────────────────────────────────────────────
  // Knowledge Base Articles
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch latest knowledge articles from Firestore
  Future<List<KnowledgeArticle>> fetchKnowledgeArticles({bool forceRefresh = false}) async {
    // Check cache first unless force refresh
    if (!forceRefresh) {
      final cached = OfflineStorage.getAllKnowledgeArticles();
      if (cached.isNotEmpty) {
        return cached.map((a) => KnowledgeArticle.fromJson(a)).toList();
      }
    }

    try {
      final snapshot = await _firestore
          .collection('knowledge_base')
          .orderBy('updatedAt', descending: true)
          .get();

      final articles = snapshot.docs
          .map((doc) => KnowledgeArticle.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Cache locally
      for (final article in articles) {
        await OfflineStorage.cacheKnowledgeArticle(article.id, article.toJson());
      }

      return articles;
    } catch (e) {
      debugPrint('[ContentService] Error fetching articles: $e');
      // Return cached articles if available
      return OfflineStorage.getAllKnowledgeArticles()
          .map((a) => KnowledgeArticle.fromJson(a))
          .toList();
    }
  }

  /// Fetch a single article by ID
  Future<KnowledgeArticle?> fetchArticle(String id) async {
    try {
      final doc = await _firestore.collection('knowledge_base').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final article = KnowledgeArticle.fromJson({...doc.data()!, 'id': doc.id});
        await OfflineStorage.cacheKnowledgeArticle(article.id, article.toJson());
        return article;
      }
    } catch (e) {
      debugPrint('[ContentService] Error fetching article $id: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Market Prices
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch latest market prices from Firestore
  Future<List<MarketPrice>> fetchMarketPrices({String region = 'ethiopia'}) async {
    // Check cache first
    final cached = OfflineStorage.getCachedMarketPrices(region);
    if (cached != null) {
      return cached.map((p) => MarketPrice.fromJson(p)).toList();
    }

    try {
      final snapshot = await _firestore
          .collection('market_prices')
          .where('region', isEqualTo: region)
          .orderBy('recordedAt', descending: true)
          .limit(50)
          .get();

      final prices = snapshot.docs
          .map((doc) => MarketPrice.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Cache locally
      await OfflineStorage.cacheMarketPrices(
        region,
        prices.map((p) => p.toJson()).toList(),
      );

      return prices;
    } catch (e) {
      debugPrint('[ContentService] Error fetching market prices: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Announcements / Alerts
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch active announcements
  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('announcements')
          .where('active', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .orderBy('startDate', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('[ContentService] Error fetching announcements: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Crop Recommendations Templates
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch crop templates for a specific region/climate
  Future<List<Map<String, dynamic>>> fetchCropTemplates(String region) async {
    try {
      final snapshot = await _firestore
          .collection('crop_templates')
          .where('regions', arrayContains: region)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('[ContentService] Error fetching crop templates: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI Prompt Templates
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch AI prompt templates (for consistent AI responses)
  Future<Map<String, String>> fetchAIPromptTemplates() async {
    try {
      final doc = await _firestore.collection('config').doc('ai_prompts').get();
      if (doc.exists && doc.data() != null) {
        return Map<String, String>.from(doc.data()!);
      }
    } catch (e) {
      debugPrint('[ContentService] Error fetching AI prompts: $e');
    }
    return {};
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin Functions (for authorized admin users)
  // ─────────────────────────────────────────────────────────────────────────

  /// Publish a new knowledge article
  Future<void> publishArticle(KnowledgeArticle article) async {
    await _firestore
        .collection('knowledge_base')
        .doc(article.id)
        .set(article.toJson());
  }

  /// Update market prices
  Future<void> updateMarketPrice(MarketPrice price) async {
    await _firestore
        .collection('market_prices')
        .doc(price.id)
        .set(price.toJson());
  }

  /// Update app configuration
  Future<void> updateAppConfig(Map<String, dynamic> config) async {
    await _firestore.collection('config').doc('app').update(config);
    _appConfig = {..._appConfig, ...config};
  }

  /// Create announcement
  Future<void> createAnnouncement({
    required String title,
    required String message,
    required DateTime startDate,
    DateTime? endDate,
    String? imageUrl,
    String? actionUrl,
    String priority = 'normal',
  }) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'message': message,
      'startDate': startDate,
      'endDate': endDate,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'priority': priority,
      'active': true,
      'createdAt': DateTime.now(),
    });
  }
}

