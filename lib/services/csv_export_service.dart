import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';

class CsvExportService {
  static final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Export all user data to CSV files
  static Future<List<File>> exportUserData({
    required List<Tool> tools,
    required List<dynamic> technicians,
    String? userId,
  }) async {
    try {
      final directory = await _getDownloadsDirectory();
      final timestamp = _fileNameFormat.format(DateTime.now());
      final files = <File>[];

      // Export tools
      final toolsFile = await _exportToolsToCsv(tools, directory, timestamp);
      files.add(toolsFile);

      // Export technicians (if admin)
      if (technicians.isNotEmpty) {
        final techniciansFile = await _exportTechniciansToCsv(technicians, directory, timestamp);
        files.add(techniciansFile);
      }

      // Export user's assigned tools (if technician)
      if (userId != null) {
        final assignedTools = tools.where((t) => t.assignedTo == userId).toList();
        if (assignedTools.isNotEmpty) {
          final assignedFile = await _exportAssignedToolsToCsv(assignedTools, directory, timestamp);
          files.add(assignedFile);
        }
      }

      debugPrint('✅ Exported ${files.length} CSV files');
      return files;
    } catch (e, stackTrace) {
      debugPrint('❌ Error exporting data to CSV: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Export tools to CSV
  static Future<File> _exportToolsToCsv(
    List<Tool> tools,
    Directory directory,
    String timestamp,
  ) async {
    final fileName = 'RGS_Tools_Export_$timestamp.csv';
    final file = File('${directory.path}/$fileName');

    final csvContent = StringBuffer();
    
    // Headers
    csvContent.writeln('Name,Category,Brand,Model,Serial Number,Status,Condition,Tool Type,Location,Purchase Date,Purchase Price,Current Value,Assigned To,Notes,Created At,Updated At');

    // Data rows
    for (final tool in tools) {
      final row = [
        _escapeCsvField(tool.name),
        _escapeCsvField(tool.category),
        _escapeCsvField(tool.brand ?? ''),
        _escapeCsvField(tool.model ?? ''),
        _escapeCsvField(tool.serialNumber ?? ''),
        _escapeCsvField(tool.status),
        _escapeCsvField(tool.condition),
        _escapeCsvField(tool.toolType),
        _escapeCsvField(tool.location ?? ''),
        _escapeCsvField(tool.purchaseDate ?? ''),
        tool.purchasePrice?.toString() ?? '',
        tool.currentValue?.toString() ?? '',
        _escapeCsvField(tool.assignedTo ?? ''),
        _escapeCsvField(tool.notes ?? ''),
        _escapeCsvField(tool.createdAt ?? ''),
        _escapeCsvField(tool.updatedAt ?? ''),
      ];
      csvContent.writeln(row.join(','));
    }

    await file.writeAsString(csvContent.toString());
    debugPrint('✅ Tools CSV exported: ${file.path}');
    return file;
  }

  /// Export technicians to CSV
  static Future<File> _exportTechniciansToCsv(
    List<dynamic> technicians,
    Directory directory,
    String timestamp,
  ) async {
    final fileName = 'RGS_Technicians_Export_$timestamp.csv';
    final file = File('${directory.path}/$fileName');

    final csvContent = StringBuffer();
    
    // Headers
    csvContent.writeln('Name,Email,Department,Phone,Role,Created At');

    // Data rows
    for (final tech in technicians) {
      String name = '';
      String email = '';
      String department = '';
      String phone = '';
      String role = 'technician';
      String createdAt = '';

      if (tech is Map) {
        name = tech['name']?.toString() ?? tech['full_name']?.toString() ?? '';
        email = tech['email']?.toString() ?? '';
        department = tech['department']?.toString() ?? '';
        phone = tech['phone']?.toString() ?? '';
        role = tech['role']?.toString() ?? 'technician';
        createdAt = tech['created_at']?.toString() ?? '';
      } else {
        try {
          name = tech.name?.toString() ?? tech.fullName?.toString() ?? '';
          email = tech.email?.toString() ?? '';
          department = tech.department?.toString() ?? '';
          phone = tech.phone?.toString() ?? '';
          role = tech.role?.toString() ?? 'technician';
          createdAt = tech.createdAt?.toString() ?? '';
        } catch (e) {
          debugPrint('⚠️ Error extracting technician data: $e');
        }
      }

      final row = [
        _escapeCsvField(name),
        _escapeCsvField(email),
        _escapeCsvField(department),
        _escapeCsvField(phone),
        _escapeCsvField(role),
        _escapeCsvField(createdAt),
      ];
      csvContent.writeln(row.join(','));
    }

    await file.writeAsString(csvContent.toString());
    debugPrint('✅ Technicians CSV exported: ${file.path}');
    return file;
  }

  /// Export assigned tools to CSV (for technicians)
  static Future<File> _exportAssignedToolsToCsv(
    List<Tool> tools,
    Directory directory,
    String timestamp,
  ) async {
    final fileName = 'RGS_My_Tools_Export_$timestamp.csv';
    final file = File('${directory.path}/$fileName');

    final csvContent = StringBuffer();
    
    // Headers
    csvContent.writeln('Name,Category,Brand,Model,Serial Number,Status,Condition,Location,Notes');

    // Data rows
    for (final tool in tools) {
      final row = [
        _escapeCsvField(tool.name),
        _escapeCsvField(tool.category),
        _escapeCsvField(tool.brand ?? ''),
        _escapeCsvField(tool.model ?? ''),
        _escapeCsvField(tool.serialNumber ?? ''),
        _escapeCsvField(tool.status),
        _escapeCsvField(tool.condition),
        _escapeCsvField(tool.location ?? ''),
        _escapeCsvField(tool.notes ?? ''),
      ];
      csvContent.writeln(row.join(','));
    }

    await file.writeAsString(csvContent.toString());
    debugPrint('✅ Assigned tools CSV exported: ${file.path}');
    return file;
  }

  /// Escape CSV field (handle commas, quotes, newlines)
  static String _escapeCsvField(String field) {
    if (field.isEmpty) return '';
    
    // If field contains comma, quote, or newline, wrap in quotes and escape quotes
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    
    return field;
  }

  /// Get downloads directory
  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isIOS) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      } catch (e) {
        debugPrint('⚠️ Failed to get application documents directory, using temp directory: $e');
        return await getTemporaryDirectory();
      }
    } else if (Platform.isAndroid) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS) {
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        return Directory('$homeDir/Downloads');
      }
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return Directory('$userProfile\\Downloads');
      }
    }
    
    // Fallback to temp directory
    return await getTemporaryDirectory();
  }
}
