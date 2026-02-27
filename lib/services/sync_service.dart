import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_cache_service.dart';
import 'supabase_service.dart';
import 'connectivity_service.dart';
import '../utils/logger.dart';

/// Processes the offline sync queue when connectivity resumes.
/// Listens to ConnectivityService and replays queued mutations in FIFO order.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalCacheService _cache = LocalCacheService();
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  /// Number of pending operations (updated after each sync attempt)
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Initialize: listen for connectivity changes and sync if already online
  Future<void> initialize() async {
    if (kIsWeb) return; // No offline cache on web

    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.connectivityStream.listen((isOnline) {
      if (isOnline) {
        Logger.debug('Network restored — starting sync');
        syncPendingOperations();
      }
    });

    // Sync on startup if online
    if (_connectivity.isOnline) {
      await syncPendingOperations();
    } else {
      await _refreshPendingCount();
    }
  }

  /// Process all queued operations in FIFO order
  Future<void> syncPendingOperations() async {
    if (_isSyncing || kIsWeb) return;
    _isSyncing = true;

    try {
      final operations = await _cache.getPendingOperations();
      if (operations.isEmpty) {
        _isSyncing = false;
        await _refreshPendingCount();
        return;
      }

      Logger.debug('Syncing ${operations.length} queued operations...');

      for (final op in operations) {
        try {
          await _executeOperation(op);
          await _cache.clearOperation(op.id);
          Logger.debug('Synced: ${op.operation} on ${op.tableName} (${op.recordId})');
        } catch (e) {
          Logger.debug('Sync failed for op ${op.id}: $e — will retry later');
          // Stop processing on first failure to preserve order
          break;
        }
      }
    } catch (e) {
      Logger.debug('Sync error: $e');
    } finally {
      _isSyncing = false;
      await _refreshPendingCount();
    }
  }

  Future<void> _executeOperation(SyncOperation op) async {
    final client = SupabaseService.client;

    switch (op.operation) {
      case 'insert':
        // Remove local-only fields before sending to Supabase
        final data = Map<String, dynamic>.from(op.data);
        data.remove('id'); // Let Supabase generate the UUID
        await client.from(op.tableName).insert(data);
        break;

      case 'update':
        if (op.recordId == null) throw Exception('No recordId for update');
        final data = Map<String, dynamic>.from(op.data);
        data.remove('id');
        await client
            .from(op.tableName)
            .update(data)
            .eq('id', op.recordId!);
        break;

      case 'delete':
        if (op.recordId == null) throw Exception('No recordId for delete');
        await client
            .from(op.tableName)
            .delete()
            .eq('id', op.recordId!);
        break;

      default:
        Logger.debug('Unknown sync operation: ${op.operation}');
    }
  }

  Future<void> _refreshPendingCount() async {
    pendingCount.value = await _cache.pendingOperationCount;
  }

  void dispose() {
    _connectivitySub?.cancel();
    pendingCount.dispose();
  }
}
