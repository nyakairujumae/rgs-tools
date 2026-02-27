import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

class DataExportService {
  static final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');
  
  /// Export user's data to CSV format
  /// Includes: tools assigned to user, tool requests, notifications
  static Future<File?> exportUserDataToCSV({
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    try {
      final csvContent = StringBuffer();
      
      // Header
      csvContent.writeln('RGS Tools - User Data Export');
      csvContent.writeln('Export Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      csvContent.writeln('User: $userName ($userEmail)');
      csvContent.writeln('');
      
      // Get user's assigned tools
      final assignedTools = await _getAssignedTools(userId);
      if (assignedTools.isNotEmpty) {
        csvContent.writeln('=== ASSIGNED TOOLS ===');
        csvContent.writeln('Tool Name,Category,Brand,Model,Serial Number,Status,Condition,Assigned Date');
        for (final tool in assignedTools) {
          final row = [
            _escapeCSV(tool['name']?.toString() ?? ''),
            _escapeCSV(tool['category']?.toString() ?? ''),
            _escapeCSV(tool['brand']?.toString() ?? ''),
            _escapeCSV(tool['model']?.toString() ?? ''),
            _escapeCSV(tool['serial_number']?.toString() ?? ''),
            _escapeCSV(tool['status']?.toString() ?? ''),
            _escapeCSV(tool['condition']?.toString() ?? ''),
            _escapeCSV(tool['updated_at']?.toString() ?? ''),
          ];
          csvContent.writeln(row.join(','));
        }
        csvContent.writeln('');
      }
      
      // Get user's notifications
      final notifications = await _getUserNotifications(userId);
      if (notifications.isNotEmpty) {
        csvContent.writeln('=== NOTIFICATIONS ===');
        csvContent.writeln('Title,Message,Type,Read Status,Date');
        for (final notification in notifications) {
          final row = [
            _escapeCSV(notification['title']?.toString() ?? ''),
            _escapeCSV(notification['message']?.toString() ?? ''),
            _escapeCSV(notification['type']?.toString() ?? ''),
            _escapeCSV(notification['is_read'] == true ? 'Read' : 'Unread'),
            _escapeCSV(notification['timestamp']?.toString() ?? ''),
          ];
          csvContent.writeln(row.join(','));
        }
        csvContent.writeln('');
      }
      
      // Save to file
      final directory = await _getDownloadsDirectory();
      final fileName = 'RGS_Tools_Data_Export_${_fileNameFormat.format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());
      
      Logger.debug('✅ CSV export created: $filePath');
      return file;
    } catch (e, stackTrace) {
      Logger.debug('❌ Error exporting data to CSV: $e');
      Logger.debug('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  static Future<List<Map<String, dynamic>>> _getAssignedTools(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('tools')
          .select()
          .eq('assigned_to', userId)
          .order('name');
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.debug('⚠️ Error fetching assigned tools: $e');
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _getUserNotifications(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('technician_notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(100); // Limit to last 100 notifications
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.debug('⚠️ Error fetching notifications: $e');
      return [];
    }
  }
  
  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
  
  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isIOS) {
      // For iOS, use application documents directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      } catch (e) {
        Logger.debug('⚠️ Failed to get application documents directory, using temp directory: $e');
        final tempDir = Directory.systemTemp;
        final fallbackDir = Directory('${tempDir.path}/RGS_Exports');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      }
    } else if (Platform.isAndroid) {
      // For Android, use app documents directory
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS) {
      // For macOS, use Downloads directory
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        return Directory('$homeDir/Downloads');
      }
    } else if (Platform.isWindows) {
      // For Windows, use Downloads directory
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return Directory('$userProfile\\Downloads');
      }
    }
    
    // Fallback: use a temp directory that definitely exists
    return Directory.systemTemp;
  }
}
