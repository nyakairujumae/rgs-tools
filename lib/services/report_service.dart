import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tool.dart';
import '../services/supabase_service.dart';

enum ReportType {
  comprehensive,
  toolsInventory,
  toolAssignments,
  technicianSummary,
  toolIssues,
  financialSummary,
  toolHistory,
}

class ReportService {
  static final SupabaseClient _client = SupabaseService.client;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Generate and save an Excel report
  static Future<File> generateReport({
    required ReportType reportType,
    required List<Tool> tools,
    required List<dynamic> technicians,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Remove default sheet

    switch (reportType) {
      case ReportType.comprehensive:
        await _generateComprehensiveReport(excel, tools, technicians, startDate, endDate);
        break;
      case ReportType.toolsInventory:
        await _generateToolsInventoryReport(excel, tools, technicians);
        break;
      case ReportType.toolAssignments:
        await _generateToolAssignmentsReport(excel, tools, technicians, startDate, endDate);
        break;
      case ReportType.technicianSummary:
        _generateTechnicianSummaryReport(excel, tools, technicians);
        break;
      case ReportType.toolIssues:
        await _generateToolIssuesReport(excel, startDate, endDate);
        break;
      case ReportType.financialSummary:
        _generateFinancialSummaryReport(excel, tools);
        break;
      case ReportType.toolHistory:
        await _generateToolHistoryReport(excel, tools, startDate, endDate);
        break;
    }

    // Set all sheets to landscape orientation
    _setSheetsToLandscape(excel);

    // Get directory and create file
    final directory = await _getDownloadsDirectory();
    final fileName = 'RGS_Tools_${_getReportTypeName(reportType)}_${_fileNameFormat.format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      // Set landscape orientation by modifying the Excel file
      await _setExcelLandscapeOrientation(file);
    }
    
    return file;
  }

  /// Set all sheets to landscape orientation and optimize column widths
  static void _setSheetsToLandscape(Excel excel) {
    try {
      for (var sheetName in excel.sheets.keys) {
        final sheet = excel[sheetName];
        
        // Optimize column widths for landscape viewing
        // Since we don't have direct access to maxCols, we'll set widths
        // for columns that are likely to be used (up to 25 columns)
        // Landscape allows more columns to be visible, so we can use wider columns
        for (int col = 0; col < 25; col++) {
          // Set much wider default width for landscape viewing (40 to accommodate longer text)
          // The setColumnWidth method will handle columns that exist
          try {
            sheet.setColumnWidth(col, 40.0);
          } catch (e) {
            // Column might not exist yet, continue
          }
        }
      }
    } catch (e) {
      debugPrint('Warning: Could not optimize sheets for landscape: $e');
      // Continue anyway - the Excel file will still be generated
    }
  }

  /// Set landscape orientation by modifying Excel file XML
  static Future<void> _setExcelLandscapeOrientation(File excelFile) async {
    try {
      // Read the Excel file as a ZIP archive (Excel files are ZIP archives)
      final bytes = await excelFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find and modify worksheet files
      final modifiedFiles = <String, List<int>>{};
      
      for (final file in archive.files) {
        if (file.isFile) {
          var fileContent = file.content as List<int>;
          
          // Check if this is a worksheet XML file (xl/worksheets/sheet*.xml)
          if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
            // Convert bytes to string
            String xmlContent = String.fromCharCodes(fileContent);
            
            // Check if pageSetup tag exists, if not add it
            if (!xmlContent.contains('<pageSetup')) {
              // Find the closing tag of the worksheet element and add pageSetup before it
              final worksheetEnd = xmlContent.indexOf('</worksheet>');
              if (worksheetEnd != -1) {
                final pageSetup = '\n<pageSetup orientation="landscape"/>\n';
                xmlContent = xmlContent.substring(0, worksheetEnd) + 
                            pageSetup + 
                            xmlContent.substring(worksheetEnd);
              }
            } else {
              // Replace existing pageSetup orientation with landscape
              xmlContent = xmlContent.replaceAllMapped(
                RegExp(r'<pageSetup[^>]*orientation="[^"]*"', caseSensitive: false),
                (match) => '<pageSetup orientation="landscape"',
              );
              
              // If pageSetup exists but doesn't have orientation, add it
              if (!xmlContent.contains('orientation="')) {
                xmlContent = xmlContent.replaceAllMapped(
                  RegExp(r'<pageSetup([^>]*)>', caseSensitive: false),
                  (match) => '<pageSetup${match.group(1)} orientation="landscape">',
                );
              }
            }
            
            fileContent = xmlContent.codeUnits;
          }
          
          modifiedFiles[file.name] = fileContent;
        }
      }
      
      // Create a new archive with modified files
      final outputArchive = Archive();
      for (final entry in modifiedFiles.entries) {
        outputArchive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
      }
      
      // Add any other files that weren't modified
      for (final file in archive.files) {
        if (!file.isFile || !modifiedFiles.containsKey(file.name)) {
          outputArchive.addFile(file);
        }
      }
      
      // Encode the archive back to bytes and write to file
      final zipEncoder = ZipEncoder();
      final outputBytes = zipEncoder.encode(outputArchive);
      if (outputBytes != null) {
        await excelFile.writeAsBytes(outputBytes);
      }
    } catch (e) {
      debugPrint('Warning: Could not set landscape orientation: $e');
      // Continue anyway - the file is still valid, just won't have landscape orientation
    }
  }

  /// Comprehensive report with all information
  static Future<void> _generateComprehensiveReport(
    Excel excel,
    List<Tool> tools,
    List<dynamic> technicians,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final sheet = excel['Comprehensive Report'];

    // Header
    _addHeader(sheet, 'Comprehensive Tool Tracking Report', 20);
    _addInfoRow(sheet, 'Generated', _dateFormat.format(DateTime.now()));
    if (startDate != null) _addInfoRow(sheet, 'Start Date', _dateFormat.format(startDate));
    if (endDate != null) _addInfoRow(sheet, 'End Date', _dateFormat.format(endDate));
    _addInfoRow(sheet, 'Total Tools', tools.length.toString());
    sheet.appendRow([]);

    // Tools Inventory Sheet
    _addSectionHeader(sheet, 'Tools Inventory', 16);
    await _addToolsTable(sheet, tools, technicians, includeAssignedTo: true, includeAssignmentDetails: true);
    sheet.appendRow([]);
    sheet.appendRow([]);

    // Assignments Summary
    _addSectionHeader(sheet, 'Current Tool Assignments', 16);
    await _addAssignmentsTable(sheet, tools, technicians, startDate, endDate);
    sheet.appendRow([]);
    sheet.appendRow([]);

    // Financial Summary
    _addSectionHeader(sheet, 'Financial Summary', 16);
    _addFinancialData(sheet, tools);
    sheet.appendRow([]);
    sheet.appendRow([]);

    // Tool Status Summary
    _addSectionHeader(sheet, 'Tool Status Summary', 16);
    _addStatusSummary(sheet, tools);
    sheet.appendRow([]);
    sheet.appendRow([]);

    // Tool Condition Summary
    _addSectionHeader(sheet, 'Tool Condition Summary', 16);
    _addConditionSummary(sheet, tools);
  }

  /// Tools Inventory Report
  static Future<void> _generateToolsInventoryReport(Excel excel, List<Tool> tools, List<dynamic> technicians) async {
    final sheet = excel['Tools Inventory'];
    _addHeader(sheet, 'Tools Inventory Report', 20);
    sheet.appendRow([]);
    await _addToolsTable(sheet, tools, technicians, includeAssignedTo: true, includeAssignmentDetails: true);
    sheet.appendRow([]);
    _addInfoRow(sheet, 'Total Tools', tools.length.toString());
  }

  /// Tool Assignments Report
  static Future<void> _generateToolAssignmentsReport(
    Excel excel,
    List<Tool> tools,
    List<dynamic> technicians,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final sheet = excel['Tool Assignments'];
    _addHeader(sheet, 'Tool Assignments Report', 20);
    if (startDate != null) _addInfoRow(sheet, 'Start Date', _dateFormat.format(startDate));
    if (endDate != null) _addInfoRow(sheet, 'End Date', _dateFormat.format(endDate));
    sheet.appendRow([]);
    await _addAssignmentsTable(sheet, tools, technicians, startDate, endDate);
  }

  /// Technician Summary Report
  static void _generateTechnicianSummaryReport(
    Excel excel,
    List<Tool> tools,
    List<dynamic> technicians,
  ) {
    final sheet = excel['Technician Summary'];
    _addHeader(sheet, 'Technician Summary Report', 20);
    _addInfoRow(sheet, 'Generated', _dateFormat.format(DateTime.now()));
    sheet.appendRow([]);

    // Technician data with their assigned tools
    final headers = [
      'Technician Name',
      'Employee ID',
      'Phone',
      'Email',
      'Department',
      'Status',
      'Assigned Tools Count',
      'Assigned Tools',
    ];
    _addTableHeader(sheet, headers);

    for (final technician in technicians) {
      final techId = technician.id?.toString() ?? '';
      final assignedTools = tools.where((t) => t.assignedTo == techId).toList();
      final toolNames = assignedTools.map((t) => t.name).join(', ');

      sheet.appendRow([
        technician.name ?? '',
        technician.employeeId ?? '',
        technician.phone ?? '',
        technician.email ?? '',
        technician.department ?? '',
        technician.status ?? '',
        assignedTools.length.toString(),
        toolNames,
      ]);
    }

    _formatTable(sheet, 3, headers.length);
  }

  /// Tool Issues Report
  static Future<void> _generateToolIssuesReport(
    Excel excel,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final sheet = excel['Tool Issues'];
    _addHeader(sheet, 'Tool Issues Report', 20);
    _addInfoRow(sheet, 'Generated', _dateFormat.format(DateTime.now()));
    sheet.appendRow([]);

    try {
      var query = _client.from('tool_issues').select();
      
      if (startDate != null) {
        query = query.gte('reported_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('reported_at', endDate.toIso8601String());
      }

      final issues = await query.order('reported_at', ascending: false);

      if (issues.isEmpty) {
        sheet.appendRow(['No issues found in the selected period.']);
        return;
      }

      final headers = [
        'Tool Name',
        'Issue Type',
        'Priority',
        'Status',
        'Reported By',
        'Description',
        'Location',
        'Estimated Cost',
        'Reported At',
        'Resolved At',
        'Resolution',
      ];
      _addTableHeader(sheet, headers);

      for (final issue in issues) {
        sheet.appendRow([
          issue['tool_name'] ?? '',
          issue['issue_type'] ?? '',
          issue['priority'] ?? '',
          issue['status'] ?? '',
          issue['reported_by'] ?? '',
          issue['description'] ?? '',
          issue['location'] ?? '',
          issue['estimated_cost']?.toString() ?? '',
          _formatDateTime(issue['reported_at']),
          _formatDateTime(issue['resolved_at']),
          issue['resolution'] ?? '',
        ]);
      }

      _formatTable(sheet, 3, headers.length);
    } catch (e) {
      sheet.appendRow(['Error fetching issues: $e']);
    }
  }

  /// Financial Summary Report
  static void _generateFinancialSummaryReport(Excel excel, List<Tool> tools) {
    final sheet = excel['Financial Summary'];
    _addHeader(sheet, 'Financial Summary Report', 20);
    _addInfoRow(sheet, 'Generated', _dateFormat.format(DateTime.now()));
    sheet.appendRow([]);
    _addFinancialData(sheet, tools);
  }

  /// Tool History Report
  static Future<void> _generateToolHistoryReport(
    Excel excel,
    List<Tool> tools,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final sheet = excel['Tool History'];
    _addHeader(sheet, 'Tool History Report', 20);
    _addInfoRow(sheet, 'Generated', _dateFormat.format(DateTime.now()));
    sheet.appendRow([]);

    // For now, use tool updated_at as history
    // In future, can query from a tool_history table
    final headers = [
      'Tool Name',
      'Category',
      'Brand',
      'Model',
      'Serial Number',
      'Status',
      'Current Holder',
      'Last Updated',
      'Created At',
    ];
    _addTableHeader(sheet, headers);

    final filteredTools = tools.where((tool) {
      if (startDate != null || endDate != null) {
        final updatedAt = DateTime.tryParse(tool.updatedAt ?? '');
        if (updatedAt == null) return false;
        if (startDate != null && updatedAt.isBefore(startDate)) return false;
        if (endDate != null && updatedAt.isAfter(endDate)) return false;
      }
      return true;
    }).toList();

    for (final tool in filteredTools) {
      sheet.appendRow([
        tool.name,
        tool.category,
        tool.brand ?? '',
        tool.model ?? '',
        tool.serialNumber ?? '',
        tool.status,
        tool.assignedTo ?? 'Available',
        _formatDateTime(tool.updatedAt),
        _formatDateTime(tool.createdAt),
      ]);
    }

    _formatTable(sheet, 3, headers.length);
  }

  // Helper Methods

  static void _addHeader(Sheet sheet, String title, int fontSize) {
    final headerCell = sheet.cell(CellIndex.indexByString('A1'));
    headerCell.value = title;
    headerCell.cellStyle = CellStyle(
      bold: true,
      fontSize: fontSize,
    );
  }

  static void _addInfoRow(Sheet sheet, String label, String value) {
    final rowIndex = sheet.maxRows;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = label;
    final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
    valueCell.value = value;
    valueCell.cellStyle = CellStyle(bold: true);
  }

  static void _addSectionHeader(Sheet sheet, String title, int fontSize) {
    final rowIndex = sheet.maxRows;
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    cell.value = title;
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: fontSize,
      backgroundColorHex: '#E0E0E0',
    );
  }

  static void _addTableHeader(Sheet sheet, List<String> headers) {
    final rowIndex = sheet.maxRows;
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#4472C4',
        fontColorHex: '#FFFFFF',
      );
    }
  }

  static Future<void> _addToolsTable(Sheet sheet, List<Tool> tools, List<dynamic> technicians, {bool includeAssignedTo = false, bool includeAssignmentDetails = false}) async {
    final headers = [
      'Tool Name',
      'Category',
      'Brand',
      'Model',
      'Serial Number',
      'Status',
      'Condition',
      'Location',
      'Purchase Date',
      'Purchase Price',
      'Current Value',
      'Tool Type',
    ];

    if (includeAssignedTo) {
      headers.insert(6, 'Assigned To');
      if (includeAssignmentDetails) {
        headers.insert(7, 'Assigned Date');
        headers.insert(8, 'Returned Status');
      } else {
        headers.insert(7, 'Assigned Date');
      }
    }

    _addTableHeader(sheet, headers);

    // Fetch assignment data if needed
    Map<String, Map<String, dynamic>> assignmentData = {};
    if (includeAssignmentDetails) {
      try {
        // Try to fetch from assignments table if it exists
        try {
          final assignments = await _client
              .from('assignments')
              .select()
              .order('assigned_date', ascending: false);
          
          // Get the most recent active assignment for each tool, or most recent overall if no active
          for (final assignment in assignments) {
            final toolId = assignment['tool_id']?.toString() ?? '';
            if (!assignmentData.containsKey(toolId) || assignment['status'] == 'Active') {
              assignmentData[toolId] = {
                'assigned_date': assignment['assigned_date'],
                'status': assignment['status'],
                'actual_return_date': assignment['actual_return_date'],
              };
            }
          }
        } catch (e) {
          // Assignments table doesn't exist, derive from tools table
          debugPrint('Assignments table not found, deriving from tools: $e');
          for (final tool in tools) {
            if (tool.assignedTo != null && tool.assignedTo!.isNotEmpty) {
              assignmentData[tool.id ?? ''] = {
                'assigned_date': tool.updatedAt ?? tool.createdAt ?? '',
                'status': tool.status == 'Available' ? 'Returned' : 'Active',
                'actual_return_date': tool.status == 'Available' ? tool.updatedAt : null,
              };
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching assignments: $e');
      }
    }

    for (final tool in tools) {
      final row = [
        tool.name,
        tool.category,
        tool.brand ?? '',
        tool.model ?? '',
        tool.serialNumber ?? '',
        tool.status,
      ];

      if (includeAssignedTo) {
        final technicianName = _getTechnicianName(tool.assignedTo, technicians);
        row.add(technicianName);
        
        if (includeAssignmentDetails) {
          final assignment = assignmentData[tool.id ?? ''];
          if (assignment != null) {
            row.add(_formatDateTime(assignment['assigned_date']));
            // Returned status: "Yes" if returned, "No" if active/not returned
            final isReturned = assignment['status'] == 'Returned' || 
                               assignment['actual_return_date'] != null;
            row.add(isReturned ? 'Yes' : 'No');
          } else {
            row.add('');
            row.add('No');
          }
        } else {
          row.add(''); // Assigned Date placeholder
        }
      }

      row.addAll([
        tool.condition,
        tool.location ?? '',
        tool.purchaseDate ?? '',
        tool.purchasePrice?.toString() ?? '',
        tool.currentValue?.toString() ?? '',
        tool.toolType,
      ]);

      sheet.appendRow(row);
    }

    _formatTable(sheet, sheet.maxRows - tools.length, headers.length);
  }

  static Future<void> _addAssignmentsTable(
    Sheet sheet,
    List<Tool> tools,
    List<dynamic> technicians,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      // Try to fetch from assignments table if it exists
      List<dynamic> assignments = [];
      bool assignmentsTableExists = true;
      
      try {
        var query = _client.from('assignments').select();
        
        if (startDate != null) {
          query = query.gte('assigned_date', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('assigned_date', endDate.toIso8601String());
        }

        assignments = await query.order('assigned_date', ascending: false);
      } catch (e) {
        // Assignments table doesn't exist, use tools table instead
        assignmentsTableExists = false;
        debugPrint('Assignments table not found, using tools table: $e');
      }

      final headers = [
        'Tool Name',
        'Category',
        'Technician',
        'Assigned Date',
        'Status',
        'Return Status',
      ];
      _addTableHeader(sheet, headers);

      if (assignmentsTableExists && assignments.isNotEmpty) {
        // Use assignments table data
        for (final assignment in assignments) {
          final toolId = assignment['tool_id']?.toString() ?? '';
          final techId = assignment['technician_id']?.toString() ?? '';
          final tool = tools.firstWhere((t) => t.id == toolId, orElse: () => tools.first);
          final technicianName = _getTechnicianName(techId, technicians);
          final isReturned = assignment['status'] == 'Returned' || 
                           assignment['actual_return_date'] != null;

          sheet.appendRow([
            tool.name,
            tool.category,
            technicianName,
            _formatDateTime(assignment['assigned_date']),
            assignment['status'] ?? 'Active',
            isReturned ? 'Yes' : 'No',
          ]);
        }
      } else {
        // Derive assignments from tools table
        final assignedTools = tools.where((t) => 
          t.assignedTo != null && 
          t.assignedTo!.isNotEmpty &&
          t.status != 'Available'
        ).toList();

        // Filter by date if provided
        final filteredTools = assignedTools.where((tool) {
          if (startDate != null || endDate != null) {
            final updatedAt = DateTime.tryParse(tool.updatedAt ?? '');
            if (updatedAt == null) return false;
            if (startDate != null && updatedAt.isBefore(startDate)) return false;
            if (endDate != null && updatedAt.isAfter(endDate)) return false;
          }
          return true;
        }).toList();

        if (filteredTools.isEmpty) {
          sheet.appendRow(['No assignments found in the selected period.']);
          return;
        }

        for (final tool in filteredTools) {
          final technicianName = _getTechnicianName(tool.assignedTo, technicians);
          final isReturned = tool.status == 'Available';
          
          sheet.appendRow([
            tool.name,
            tool.category,
            technicianName,
            _formatDateTime(tool.updatedAt), // Use updatedAt as proxy for assignment date
            tool.status,
            isReturned ? 'Yes' : 'No',
          ]);
        }
      }

      final rowCount = assignmentsTableExists && assignments.isNotEmpty 
          ? assignments.length 
          : tools.where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty && t.status != 'Available').length;
      _formatTable(sheet, sheet.maxRows - rowCount, headers.length);
    } catch (e) {
      sheet.appendRow(['Error fetching assignments: $e']);
      debugPrint('Error in _addAssignmentsTable: $e');
    }
  }

  static void _addFinancialData(Sheet sheet, List<Tool> tools) {
    final totalPurchasePrice = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));
    final totalCurrentValue = tools.fold(0.0, (sum, tool) => sum + (tool.currentValue ?? 0));
    final depreciation = totalPurchasePrice - totalCurrentValue;
    final depreciationPercentage = totalPurchasePrice > 0 ? (depreciation / totalPurchasePrice * 100) : 0;

    sheet.appendRow(['Metric', 'Value']);
    sheet.appendRow(['Total Purchase Value', 'AED ${totalPurchasePrice.toStringAsFixed(2)}']);
    sheet.appendRow(['Total Current Value', 'AED ${totalCurrentValue.toStringAsFixed(2)}']);
    sheet.appendRow(['Total Depreciation', 'AED ${depreciation.toStringAsFixed(2)}']);
    sheet.appendRow(['Depreciation Percentage', '${depreciationPercentage.toStringAsFixed(2)}%']);

    // Set column widths for financial summary to ensure text fits
    sheet.setColumnWidth(0, 50.0); // Metric column - needs extra space for long labels
    sheet.setColumnWidth(1, 30.0); // Value column

    // Format financial table
    final financialRowIndex = sheet.maxRows - 5;
    for (int i = 0; i < 5; i++) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: financialRowIndex + i));
      labelCell.cellStyle = CellStyle(bold: true);
      final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: financialRowIndex + i));
      valueCell.cellStyle = CellStyle(bold: true, fontColorHex: '#006100');
    }
  }

  static void _addStatusSummary(Sheet sheet, List<Tool> tools) {
    final statusCounts = <String, int>{};
    for (final tool in tools) {
      statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
    }

    sheet.appendRow(['Status', 'Count', 'Percentage']);
    final total = tools.length;
    for (final entry in statusCounts.entries) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      sheet.appendRow([entry.key, entry.value.toString(), '$percentage%']);
    }
  }

  static void _addConditionSummary(Sheet sheet, List<Tool> tools) {
    final conditionCounts = <String, int>{};
    for (final tool in tools) {
      conditionCounts[tool.condition] = (conditionCounts[tool.condition] ?? 0) + 1;
    }

    sheet.appendRow(['Condition', 'Count', 'Percentage']);
    final total = tools.length;
    for (final entry in conditionCounts.entries) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      sheet.appendRow([entry.key, entry.value.toString(), '$percentage%']);
    }
  }

  static void _formatTable(Sheet sheet, int startRow, int columnCount) {
    // Set column widths optimized for landscape viewing
    // Landscape orientation allows more columns to fit, so we can use much wider columns
    // Define custom widths for specific columns that need more space
    // Widths are set significantly larger to prevent text truncation
    final Map<int, double> customWidths = {
      // Column indices for Tools Inventory (with assignment details)
      0: 45.0,  // Tool Name - needs extra space for long names
      1: 35.0,  // Category - can be "Testing Equipment", "Safety Equipment", etc.
      2: 30.0,  // Brand
      3: 35.0,  // Model - can have long model numbers
      4: 35.0,  // Serial Number - can be long
      5: 20.0,  // Status - short values
      6: 30.0,  // Assigned To - technician names
      7: 35.0,  // Assigned Date - full datetime format
      8: 22.0,  // Returned Status - Yes/No
      9: 20.0,  // Condition - short values
      10: 30.0, // Location
      11: 35.0, // Purchase Date - full datetime format
      12: 25.0, // Purchase Price - numbers
      13: 25.0, // Current Value - numbers
      14: 25.0, // Tool Type
    };
    
    for (int i = 0; i < columnCount; i++) {
      // Use custom width if defined, otherwise use much wider default (40 for landscape)
      // This ensures all text fits without truncation
      final width = customWidths[i] ?? 40.0;
      sheet.setColumnWidth(i, width);
    }
  }

  static String _getTechnicianName(String? technicianId, List<dynamic> technicians) {
    if (technicianId == null || technicianId.isEmpty) return 'Unassigned';
    for (final tech in technicians) {
      if (tech.id?.toString() == technicianId) {
        return tech.name ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

  static String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.tryParse(dateTime.toString());
      if (dt == null) return '';
      return _dateFormat.format(dt);
    } catch (e) {
      return dateTime.toString();
    }
  }

  static String _getReportTypeName(ReportType type) {
    switch (type) {
      case ReportType.comprehensive:
        return 'Comprehensive';
      case ReportType.toolsInventory:
        return 'ToolsInventory';
      case ReportType.toolAssignments:
        return 'ToolAssignments';
      case ReportType.technicianSummary:
        return 'TechnicianSummary';
      case ReportType.toolIssues:
        return 'ToolIssues';
      case ReportType.financialSummary:
        return 'FinancialSummary';
      case ReportType.toolHistory:
        return 'ToolHistory';
    }
  }

  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile, use app documents directory
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
    } else if (Platform.isLinux) {
      // For Linux, use Downloads directory
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        return Directory('$homeDir/Downloads');
      }
    }
    
    // Fallback to application documents directory
    return await getApplicationDocumentsDirectory();
  }
}

