import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import '../models/admin_notification.dart';
import '../models/technician_notification.dart';
import '../utils/logger.dart';

/// Represents a queued offline mutation waiting to sync
class SyncOperation {
  final int id;
  final String tableName;
  final String operation; // 'insert', 'update', 'delete'
  final String? recordId;
  final Map<String, dynamic> data;
  final String createdAt;

  SyncOperation({
    required this.id,
    required this.tableName,
    required this.operation,
    this.recordId,
    required this.data,
    required this.createdAt,
  });
}

/// Service wrapping all SQLite cache operations.
/// Caches tools and technicians locally and queues offline mutations.
class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  // Skip SQLite on web — not supported
  bool get _isSupported => !kIsWeb;

  /// Initialize the database (call once at app start)
  Future<void> initialize() async {
    if (!_isSupported) return;
    try {
      await DatabaseHelper.instance.database;
      Logger.debug('SQLite cache initialized');
    } catch (e) {
      Logger.debug('Failed to initialize SQLite cache: $e');
    }
  }

  // ─── Tools ───────────────────────────────────────────────

  /// Bulk replace cached tools (delete-and-replace for simplicity)
  Future<void> cacheTools(List<Tool> tools) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete('tools');
        for (final tool in tools) {
          await txn.insert('tools', _toolToRow(tool));
        }
      });
      await _updateLastSyncTime('tools');
      Logger.debug('Cached ${tools.length} tools to SQLite');
    } catch (e) {
      Logger.debug('Error caching tools: $e');
    }
  }

  /// Read all cached tools
  Future<List<Tool>> getCachedTools() async {
    if (!_isSupported) return [];
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('tools', orderBy: 'name ASC');
      final tools = rows.map((row) => Tool.fromMap(row)).toList();
      Logger.debug('Read ${tools.length} cached tools from SQLite');
      return tools;
    } catch (e) {
      Logger.debug('Error reading cached tools: $e');
      return [];
    }
  }

  /// Insert or update a single tool in the cache
  Future<void> cacheSingleTool(Tool tool) async {
    if (!_isSupported || tool.id == null) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('tools', _toolToRow(tool),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      Logger.debug('Error caching single tool: $e');
    }
  }

  /// Remove a tool from the cache
  Future<void> removeCachedTool(String toolId) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('tools', where: 'id = ?', whereArgs: [toolId]);
    } catch (e) {
      Logger.debug('Error removing cached tool: $e');
    }
  }

  // ─── Technicians ─────────────────────────────────────────

  /// Bulk replace cached technicians
  Future<void> cacheTechnicians(List<Technician> technicians) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete('technicians');
        for (final tech in technicians) {
          await txn.insert('technicians', _technicianToRow(tech));
        }
      });
      await _updateLastSyncTime('technicians');
      Logger.debug('Cached ${technicians.length} technicians to SQLite');
    } catch (e) {
      Logger.debug('Error caching technicians: $e');
    }
  }

  /// Read all cached technicians
  Future<List<Technician>> getCachedTechnicians() async {
    if (!_isSupported) return [];
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('technicians', orderBy: 'name ASC');
      final technicians = rows.map((row) => Technician.fromMap(row)).toList();
      Logger.debug('Read ${technicians.length} cached technicians from SQLite');
      return technicians;
    } catch (e) {
      Logger.debug('Error reading cached technicians: $e');
      return [];
    }
  }

  // ─── Notifications (Admin) ────────────────────────────────

  /// Bulk replace cached admin notifications.
  Future<void> cacheAdminNotifications(List<AdminNotification> items) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete('admin_notifications_cache');
        for (final n in items) {
          await txn.insert('admin_notifications_cache', {
            'id': n.id,
            'title': n.title,
            'message': n.message,
            'technician_name': n.technicianName,
            'technician_email': n.technicianEmail,
            'type': n.type.toString(),
            'timestamp': n.timestamp.toIso8601String(),
            'is_read': n.isRead ? 1 : 0,
            'data': n.data != null ? jsonEncode(n.data) : null,
          });
        }
      });
      await _updateLastSyncTime('admin_notifications_cache');
      Logger.debug('Cached ${items.length} admin notifications to SQLite');
    } catch (e) {
      Logger.debug('Error caching admin notifications: $e');
    }
  }

  /// Read all cached admin notifications.
  Future<List<AdminNotification>> getCachedAdminNotifications() async {
    if (!_isSupported) return [];
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'admin_notifications_cache',
        orderBy: 'timestamp DESC',
        limit: 100,
      );
      final list = rows.map((row) {
        return AdminNotification(
          id: (row['id'] ?? '').toString(),
          title: (row['title'] ?? '').toString(),
          message: (row['message'] ?? '').toString(),
          technicianName: (row['technician_name'] ?? '').toString(),
          technicianEmail: (row['technician_email'] ?? '').toString(),
          type: NotificationType.fromString((row['type'] ?? 'general').toString()),
          timestamp: DateTime.tryParse((row['timestamp'] ?? '').toString()) ??
              DateTime.now(),
          isRead: (row['is_read'] ?? 0) == 1,
          data: row['data'] != null
              ? (jsonDecode(row['data'] as String) as Map<String, dynamic>?)
              : null,
        );
      }).toList();
      Logger.debug('Read ${list.length} cached admin notifications from SQLite');
      return list;
    } catch (e) {
      Logger.debug('Error reading cached admin notifications: $e');
      return [];
    }
  }

  // ─── Notifications (Technician) ───────────────────────────

  /// Bulk replace cached technician notifications for a user.
  Future<void> cacheTechnicianNotifications(
      String userId, List<TechnicianNotification> items) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete(
          'technician_notifications_cache',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        for (final n in items) {
          await txn.insert('technician_notifications_cache', {
            'id': n.id,
            'user_id': userId,
            'title': n.title,
            'message': n.message,
            'type': n.type.toString(),
            'timestamp': n.timestamp.toIso8601String(),
            'is_read': n.isRead ? 1 : 0,
            'data': n.data != null ? jsonEncode(n.data) : null,
          });
        }
      });
      await _updateLastSyncTime('technician_notifications_cache_$userId');
      Logger.debug(
          'Cached ${items.length} technician notifications for user $userId to SQLite');
    } catch (e) {
      Logger.debug('Error caching technician notifications: $e');
    }
  }

  /// Read cached technician notifications for a user.
  Future<List<TechnicianNotification>> getCachedTechnicianNotifications(
      String userId) async {
    if (!_isSupported) return [];
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'technician_notifications_cache',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: 100,
      );
      final list = rows.map((row) {
        return TechnicianNotification(
          id: (row['id'] ?? '').toString(),
          userId: (row['user_id'] ?? '').toString(),
          title: (row['title'] ?? '').toString(),
          message: (row['message'] ?? '').toString(),
          type: NotificationType.fromString((row['type'] ?? 'general').toString()),
          timestamp: DateTime.tryParse((row['timestamp'] ?? '').toString()) ??
              DateTime.now(),
          isRead: (row['is_read'] ?? 0) == 1,
          data: row['data'] != null
              ? (jsonDecode(row['data'] as String) as Map<String, dynamic>?)
              : null,
        );
      }).toList();
      Logger.debug(
          'Read ${list.length} cached technician notifications for user $userId from SQLite');
      return list;
    } catch (e) {
      Logger.debug('Error reading cached technician notifications: $e');
      return [];
    }
  }

  // ─── Sync queue ──────────────────────────────────────────

  /// Queue an offline mutation for later sync
  Future<void> queueOperation(
    String tableName,
    String operation,
    Map<String, dynamic> data, {
    String? recordId,
  }) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('sync_queue', {
        'table_name': tableName,
        'operation': operation,
        'record_id': recordId,
        'data': jsonEncode(data),
        'created_at': DateTime.now().toIso8601String(),
      });
      Logger.debug('Queued offline $operation on $tableName (id: $recordId)');
    } catch (e) {
      Logger.debug('Error queuing operation: $e');
    }
  }

  /// Get all pending sync operations in FIFO order
  Future<List<SyncOperation>> getPendingOperations() async {
    if (!_isSupported) return [];
    try {
      final db = await DatabaseHelper.instance.database;
      final rows =
          await db.query('sync_queue', orderBy: 'id ASC');
      return rows.map((row) {
        return SyncOperation(
          id: row['id'] as int,
          tableName: row['table_name'] as String,
          operation: row['operation'] as String,
          recordId: row['record_id'] as String?,
          data: jsonDecode(row['data'] as String) as Map<String, dynamic>,
          createdAt: row['created_at'] as String,
        );
      }).toList();
    } catch (e) {
      Logger.debug('Error reading sync queue: $e');
      return [];
    }
  }

  /// Remove a completed operation from the queue
  Future<void> clearOperation(int operationId) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [operationId]);
    } catch (e) {
      Logger.debug('Error clearing operation $operationId: $e');
    }
  }

  /// Count of pending operations (for UI badge)
  Future<int> get pendingOperationCount async {
    if (!_isSupported) return 0;
    try {
      final db = await DatabaseHelper.instance.database;
      final result =
          await db.rawQuery('SELECT COUNT(*) as cnt FROM sync_queue');
      return result.first['cnt'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── Cache metadata ──────────────────────────────────────

  /// Get the last sync time for a table
  Future<DateTime?> getLastSyncTime(String tableName) async {
    if (!_isSupported) return null;
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('cache_metadata',
          where: 'table_name = ?', whereArgs: [tableName]);
      if (rows.isEmpty) return null;
      return DateTime.tryParse(rows.first['last_sync_at'] as String);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateLastSyncTime(String tableName) async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'cache_metadata',
        {
          'table_name': tableName,
          'last_sync_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      Logger.debug('Error updating sync time: $e');
    }
  }

  // ─── Housekeeping ────────────────────────────────────────

  /// Clear all cached data (call on logout)
  Future<void> clearAllCache() async {
    if (!_isSupported) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('tools');
      await db.delete('technicians');
      await db.delete('admin_notifications_cache');
      await db.delete('technician_notifications_cache');
      await db.delete('sync_queue');
      await db.delete('cache_metadata');
      Logger.debug('All SQLite cache cleared');
    } catch (e) {
      Logger.debug('Error clearing cache: $e');
    }
  }

  // ─── Private helpers ─────────────────────────────────────

  Map<String, dynamic> _toolToRow(Tool tool) {
    return {
      'id': tool.id,
      'name': tool.name,
      'category': tool.category,
      'brand': tool.brand,
      'model': tool.model,
      'serial_number': tool.serialNumber,
      'purchase_date': tool.purchaseDate,
      'purchase_price': tool.purchasePrice,
      'current_value': tool.currentValue,
      'condition': tool.condition,
      'location': tool.location,
      'assigned_to': tool.assignedTo,
      'status': tool.status,
      'tool_type': tool.toolType,
      'image_path': tool.imagePath,
      'notes': tool.notes,
      'created_at': tool.createdAt,
      'updated_at': tool.updatedAt,
    };
  }

  Map<String, dynamic> _technicianToRow(Technician tech) {
    return {
      'id': tech.id,
      'user_id': tech.userId,
      'name': tech.name,
      'employee_id': tech.employeeId,
      'phone': tech.phone,
      'email': tech.email,
      'department': tech.department,
      'hire_date': tech.hireDate,
      'status': tech.status,
      'profile_picture_url': tech.profilePictureUrl,
      'created_at': tech.createdAt,
    };
  }
}
