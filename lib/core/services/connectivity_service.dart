import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'offline_storage.dart';

// Conditional imports for platform-specific connectivity
import 'connectivity_stub.dart'
    if (dart.library.io) 'connectivity_io.dart'
    if (dart.library.html) 'connectivity_web.dart' as platform;

/// Connectivity service that monitors network status and syncs data when online.
class ConnectivityService with ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  StreamSubscription<bool>? _subscription;
  
  bool _isOnline = true;
  bool _isSyncing = false;
  
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  /// Initialize connectivity monitoring
  Future<void> init() async {
    try {
      // Check initial status
      _isOnline = await platform.checkConnectivity();
      debugPrint('[Connectivity] Initial status: $_isOnline');
      
      // Listen for changes
      _subscription = platform.onConnectivityChanged().listen((isOnline) {
        final wasOnline = _isOnline;
        _isOnline = isOnline;
        
        debugPrint('[Connectivity] Status changed: $_isOnline (was: $wasOnline)');
        
        if (_isOnline && !wasOnline) {
          // Came back online - trigger sync
          syncPendingData();
        }
        
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[Connectivity] Error initializing: $e');
      // Assume online if we can't check
      _isOnline = true;
    }
  }

  /// Sync all pending data to Firestore when online
  Future<void> syncPendingData() async {
    if (!_isOnline || _isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    debugPrint('[Connectivity] Starting sync of pending data...');
    
    try {
      final queue = OfflineStorage.getSyncQueue();
      
      for (final item in queue) {
        final type = item['type'] as String?;
        final data = item['data'] as Map<String, dynamic>?;
        
        if (type == null || data == null) continue;
        
        try {
          await _syncItem(type, data);
          // Remove from queue after successful sync
          final id = '${type}_${DateTime.parse(item['createdAt']).millisecondsSinceEpoch}';
          await OfflineStorage.removeFromSyncQueue(id);
        } catch (e) {
          debugPrint('[Connectivity] Failed to sync $type: $e');
        }
      }
      
      debugPrint('[Connectivity] Sync complete');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncItem(String type, Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;
    
    switch (type) {
      case 'farm_record':
        await firestore
            .collection('farmers')
            .doc(data['userId'])
            .collection('records')
            .doc(data['id'])
            .set(data);
        break;
      case 'disease_result':
        await firestore
            .collection('farmers')
            .doc(data['userId'])
            .collection('disease_results')
            .add(data);
        break;
      case 'farm_profile':
        await firestore
            .collection('farmers')
            .doc(data['userId'])
            .set(data, SetOptions(merge: true));
        break;
      default:
        debugPrint('[Connectivity] Unknown sync type: $type');
    }
  }

  /// Dispose subscription
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
