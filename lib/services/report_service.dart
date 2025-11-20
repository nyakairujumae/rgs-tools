import 'dart:io';
import 'dart:math' as math;
import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

enum ReportFormat { excel, pdf }

class ReportService {
  static final SupabaseClient _client = SupabaseService.client;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

  /// Generate and save a report in the desired format
  static Future<File> generateReport({
    required ReportType reportType,
    required List<Tool> tools,
    required List<dynamic> technicians,
    DateTime? startDate,
    DateTime? endDate,
    ReportFormat format = ReportFormat.excel,
  }) async {
    switch (format) {
      case ReportFormat.pdf:
        return _generatePdfReport(
          reportType: reportType,
          tools: tools,
          technicians: technicians,
          startDate: startDate,
          endDate: endDate,
        );
      case ReportFormat.excel:
      default:
        return _generateExcelReport(
          reportType: reportType,
          tools: tools,
          technicians: technicians,
          startDate: startDate,
          endDate: endDate,
        );
    }
  }

  /// Generate and save an Excel report
  static Future<File> _generateExcelReport({
    required ReportType reportType,
    required List<Tool> tools,
    required List<dynamic> technicians,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final excel = Excel.createExcel();
    final targetSheetName = _getSheetName(reportType);

    if (excel.sheets.containsKey('Sheet1')) {
      excel.rename('Sheet1', targetSheetName);
    }

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
      // Try to set landscape orientation, but don't fail if it doesn't work
      // The Excel file will still be valid and exportable
      try {
        await _setExcelLandscapeOrientation(file);
      } catch (e) {
        // Silently fail - landscape orientation is a nice-to-have, not critical
        debugPrint('Note: Could not set landscape orientation, but file is still valid: $e');
      }
    }
    
    return file;
  }

  static String _getSheetName(ReportType type) {
    switch (type) {
      case ReportType.comprehensive:
        return 'Comprehensive Report';
      case ReportType.toolsInventory:
        return 'Tools Inventory';
      case ReportType.toolAssignments:
        return 'Tool Assignments';
      case ReportType.technicianSummary:
        return 'Technician Summary';
      case ReportType.toolIssues:
        return 'Tool Issues';
      case ReportType.financialSummary:
        return 'Financial Summary';
      case ReportType.toolHistory:
        return 'Tool History';
    }
  }

  static Future<File> _generatePdfReport({
    required ReportType reportType,
    required List<Tool> tools,
    required List<dynamic> technicians,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    final reportTitle = _getReportTitle(reportType);
    final dateRangeText = _buildDateRangeText(startDate, endDate);

    List<dynamic> toolIssues = [];
    if (reportType == ReportType.toolIssues) {
      toolIssues = await _fetchToolIssues(startDate, endDate);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        build: (context) {
          final widgets = <pw.Widget>[
            _buildPdfHeader(reportTitle, dateRangeText),
            pw.SizedBox(height: 20),
          ];

          switch (reportType) {
            case ReportType.toolIssues:
              widgets.add(_buildToolIssuesPdfSection(toolIssues));
              break;
            case ReportType.toolsInventory:
              widgets.add(_buildPdfPlaceholder('PDF export for Tools Inventory is coming soon.'));
              break;
            case ReportType.toolAssignments:
              widgets.add(_buildPdfPlaceholder('PDF export for Assignment reports is coming soon.'));
              break;
            case ReportType.technicianSummary:
              widgets.add(_buildPdfPlaceholder('PDF export for Technician summary is coming soon.'));
              break;
            case ReportType.financialSummary:
              widgets.add(_buildPdfPlaceholder('PDF export for Financial summary is coming soon.'));
              break;
            case ReportType.toolHistory:
              widgets.add(_buildPdfPlaceholder('PDF export for Tool history is coming soon.'));
              break;
            case ReportType.comprehensive:
              widgets.add(_buildPdfPlaceholder('Comprehensive PDF report is coming soon.'));
              break;
          }

          return widgets;
        },
      ),
    );

    final directory = await _getDownloadsDirectory();
    final fileName = 'RGS_Tools_${_getReportTypeName(reportType)}_${_fileNameFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
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
  /// DISABLED: This feature is causing unmodifiable list errors
  /// The Excel file will still be generated correctly - users can manually set landscape orientation
  static Future<void> _setExcelLandscapeOrientation(File excelFile) async {
    // Feature disabled - Excel file is still valid and exportable
    // Users can set landscape orientation manually when opening the file in Excel
    // This was causing "Cannot remove from an unmodifiable list" errors
    return;
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
      final issues = await _fetchToolIssues(startDate, endDate);

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

      for (var index = 0; index < issues.length; index++) {
        final issue = issues[index] as Map<String, dynamic>;
        final estimatedCost = issue['estimated_cost'] != null
            ? _currencyFormat.format(issue['estimated_cost'])
            : '';

        sheet.appendRow([
          issue['tool_name'] ?? '',
          issue['issue_type'] ?? '',
          issue['priority'] ?? '',
          issue['status'] ?? '',
          issue['reported_by'] ?? '',
          issue['description'] ?? '',
          issue['location'] ?? '',
          estimatedCost,
          _formatDateTime(issue['reported_at']),
          _formatDateTime(issue['resolved_at']),
          issue['resolution'] ?? '',
        ]);

        final rowIndex = sheet.maxRows - 1;
        final numericColumns = <int>{headers.indexOf('Estimated Cost')};
        final wrapColumns = <int>{
          headers.indexOf('Description'),
          headers.indexOf('Location'),
        };
        _setDataRowStyle(
          sheet,
          rowIndex,
          headers.length,
          numericColumns: numericColumns.where((i) => i >= 0).toSet(),
          wrapColumns: wrapColumns.where((i) => i >= 0).toSet(),
        );
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
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }
  }

  static void _setDataRowStyle(
    Sheet sheet,
    int rowIndex,
    int columnCount, {
    Set<int> numericColumns = const {},
    Set<int> wrapColumns = const {},
  }) {
    final isEven = rowIndex % 2 == 0;
    final backgroundColor = isEven ? '#F7FAFF' : '#FFFFFF';

    for (int i = 0; i < columnCount; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.cellStyle = CellStyle(
        backgroundColorHex: backgroundColor,
        horizontalAlign: numericColumns.contains(i) ? HorizontalAlign.Right : HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        textWrapping: wrapColumns.contains(i) ? TextWrapping.WrapText : TextWrapping.Clip,
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

    final returnedStatusIndex = headers.indexOf('Returned Status');
    final purchasePriceIndex = headers.indexOf('Purchase Price');

    for (var index = 0; index < tools.length; index++) {
      final tool = tools[index];
      final row = <dynamic>[
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
            final isReturned = assignment['status'] == 'Returned' ||
                assignment['actual_return_date'] != null;
            row.add(isReturned ? 'Yes' : 'No');
          } else {
            row.add(_formatDateTime(tool.updatedAt));
            row.add(tool.status == 'Available' ? 'Yes' : 'No');
          }
        } else {
          row.add(_formatDateTime(tool.updatedAt));
        }
      }

      row.addAll([
        tool.condition,
        tool.location ?? '',
        _formatDate(tool.purchaseDate),
        tool.purchasePrice != null ? _currencyFormat.format(tool.purchasePrice) : '',
        tool.toolType,
      ]);

      sheet.appendRow(row);

      final rowIndex = sheet.maxRows - 1;
      final numericColumns = <int>{}
        ..addAll([purchasePriceIndex].where((index) => index >= 0));
      final wrapColumns = <int>{
        headers.indexOf('Location'),
        headers.indexOf('Brand'),
        headers.indexOf('Model'),
      }.where((index) => index >= 0).toSet();
      _setDataRowStyle(
        sheet,
        rowIndex,
        headers.length,
        numericColumns: numericColumns,
        wrapColumns: wrapColumns,
      );

      // Emphasize high priority conditions by color coding status cell
      final statusColumnIndex = headers.indexOf('Status');
      if (statusColumnIndex >= 0) {
        final statusCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: statusColumnIndex, rowIndex: rowIndex));
        if (tool.status.toLowerCase() == 'maintenance') {
          statusCell.cellStyle = CellStyle(
            backgroundColorHex: '#FFF2CC',
            horizontalAlign: HorizontalAlign.Left,
            verticalAlign: VerticalAlign.Center,
            textWrapping: TextWrapping.WrapText,
            bold: true,
          );
        }
      }

      if (returnedStatusIndex >= 0) {
        final returnCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: returnedStatusIndex, rowIndex: rowIndex));
        final value = returnCell.value.toString();
        if (value == 'No') {
          returnCell.cellStyle = CellStyle(
            backgroundColorHex: '#FCE4E4',
            fontColorHex: '#C53030',
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        } else if (value == 'Yes') {
          returnCell.cellStyle = CellStyle(
            backgroundColorHex: '#E6F4EA',
            fontColorHex: '#2F855A',
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }
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

    sheet.appendRow(['Metric', 'Value']);
    sheet.appendRow(['Total Purchase Value', 'AED ${totalPurchasePrice.toStringAsFixed(2)}']);

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

  static void _formatTable(
    Sheet sheet,
    int startRow,
    int columnCount, {
    Map<int, double>? fixedColumnWidths,
    bool autoFit = true,
    double minWidth = 22,
    double maxWidth = 70,
  }) {
    final fixedColumns = <int>{};
    if (fixedColumnWidths != null && fixedColumnWidths.isNotEmpty) {
      for (final entry in fixedColumnWidths.entries) {
        if (entry.key < columnCount) {
          sheet.setColumnWidth(entry.key, entry.value);
          fixedColumns.add(entry.key);
        }
      }
    }

    if (autoFit) {
      _autoFitColumns(
        sheet,
        columnCount: columnCount,
        skipColumns: fixedColumns,
        minWidth: minWidth,
        maxWidth: maxWidth,
      );
    }
  }

  static void _autoFitColumns(
    Sheet sheet, {
    required int columnCount,
    Set<int> skipColumns = const {},
    double minWidth = 12,
    double maxWidth = 55,
  }) {
    final rows = sheet.rows;
    for (int col = 0; col < columnCount; col++) {
      if (skipColumns.contains(col)) continue;

      double maxLength = 0;
      for (final row in rows) {
        if (col >= row.length) continue;
        final cell = row[col];
        final value = cell?.value;
        if (value == null) continue;
        final text = value.toString();
        if (text.isEmpty) continue;
        final length = _estimateTextWidth(text);
        if (length > maxLength) {
          maxLength = length;
        }
      }

      final width = math.max(minWidth, math.min(maxWidth, maxLength + 2));
      sheet.setColumnWidth(col, width);
    }
  }

  static double _estimateTextWidth(String text) {
    double width = 0;
    for (final codePoint in text.runes) {
      final char = String.fromCharCode(codePoint);
      if (char == ' ') {
        width += 0.6;
      } else if ('MW'.contains(char)) {
        width += 1.4;
      } else if ('il.,!1'.contains(char)) {
        width += 0.6;
      } else {
        width += 1.0;
      }
    }
    return width;
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

  static String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(date);
      if (dt == null) return date;
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return date;
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

  static Future<List<dynamic>> _fetchToolIssues(DateTime? startDate, DateTime? endDate) async {
    var query = _client.from('tool_issues').select();

    if (startDate != null) {
      query = query.gte('reported_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('reported_at', endDate.toIso8601String());
    }

    return await query.order('reported_at', ascending: false);
  }

  static String _getReportTitle(ReportType type) {
    switch (type) {
      case ReportType.comprehensive:
        return 'Comprehensive Tool Report';
      case ReportType.toolsInventory:
        return 'Tools Inventory Report';
      case ReportType.toolAssignments:
        return 'Tool Assignments Report';
      case ReportType.technicianSummary:
        return 'Technician Summary Report';
      case ReportType.toolIssues:
        return 'Tool Issues Report';
      case ReportType.financialSummary:
        return 'Financial Summary Report';
      case ReportType.toolHistory:
        return 'Tool History Report';
    }
  }

  static String _buildDateRangeText(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return 'All time';
    }

    final dateFormatter = DateFormat('dd MMM yyyy');
    final now = DateTime.now();
    final startText = startDate != null ? dateFormatter.format(startDate) : 'Beginning';
    final endText = endDate != null ? dateFormatter.format(endDate) : dateFormatter.format(now);

    if (startDate == null) {
      return 'Up to $endText';
    }
    if (endDate == null) {
      return 'From $startText';
    }
    return '$startText – $endText';
  }

  static pw.Widget _buildPdfHeader(String title, String dateRangeText) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RGS HVAC Services',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Reporting period: $dateRangeText',
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.blueGrey600,
          ),
        ),
        pw.Text(
          'Generated ${_formatFriendlyDateTime(DateTime.now().toIso8601String())}',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.blueGrey500,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.blueGrey200),
      ],
    );
  }

  static pw.Widget _buildPdfPlaceholder(String message) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blueGrey100),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.blueGrey700,
        ),
      ),
    );
  }

  static pw.Widget _buildToolIssuesPdfSection(List<dynamic> issues) {
    if (issues.isEmpty) {
      return _buildPdfPlaceholder('No tool issues were recorded for the selected period.');
    }

    final statusCounts = <String, int>{};
    final priorityCounts = <String, int>{};
    double totalCost = 0.0;

    for (final item in issues) {
      final issue = item as Map<String, dynamic>;
      final status = (issue['status'] ?? 'Unknown').toString();
      final priority = (issue['priority'] ?? 'Unspecified').toString();
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;

      final cost = issue['estimated_cost'];
      if (cost is num) {
        totalCost += cost.toDouble();
      }
    }

    final openIssues = issues.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status != 'resolved' && status != 'closed';
    }).length;

    final tableHeaders = [
      'Tool',
      'Type',
      'Priority',
      'Status',
      'Reported',
      'Reporter',
      'Cost',
      'Summary',
    ];

    final tableData = issues.map<List<String>>((item) {
      final issue = item as Map<String, dynamic>;
      final cost = issue['estimated_cost'];
      return [
        issue['tool_name']?.toString() ?? '',
        issue['issue_type']?.toString() ?? '',
        issue['priority']?.toString() ?? '',
        issue['status']?.toString() ?? '',
        _formatFriendlyDateTime(issue['reported_at']),
        issue['reported_by']?.toString() ?? '',
        cost is num ? _currencyFormat.format(cost.toDouble()) : '—',
        _composeIssueSummary(issue),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tool Issues Overview',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard('Total Issues', issues.length.toString(), PdfColors.indigo),
            _buildMetricCard('Open Issues', openIssues.toString(), PdfColors.deepOrange),
            _buildMetricCard('Estimated Cost', _currencyFormat.format(totalCost), PdfColors.teal),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildSummaryTable('By Status', statusCounts)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _buildSummaryTable('By Priority', priorityCounts)),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Table.fromTextArray(
          headers: tableHeaders,
          data: tableData,
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
          cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey800),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.2),
            3: pw.FlexColumnWidth(1.3),
            4: pw.FlexColumnWidth(1.8),
            5: pw.FlexColumnWidth(1.6),
            6: pw.FlexColumnWidth(1.4),
            7: pw.FlexColumnWidth(3.0),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.centerLeft,
            5: pw.Alignment.centerLeft,
            6: pw.Alignment.centerRight,
            7: pw.Alignment.centerLeft,
          },
        ),
      ],
    );
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFF),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _blendWithWhite(color, 0.65), width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.blueGrey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _blendWithWhite(PdfColor color, double amount) {
    final t = amount.clamp(0.0, 1.0);
    return PdfColor(
      color.red + (1 - color.red) * t,
      color.green + (1 - color.green) * t,
      color.blue + (1 - color.blue) * t,
      color.alpha,
    );
  }

  static pw.Widget _buildSummaryTable(String title, Map<String, int> data) {
    if (data.isEmpty) {
      return _buildPdfPlaceholder('No $title data available.');
    }

    final total = data.values.fold<int>(0, (sum, value) => sum + value);

    final rows = data.entries
        .map(
          (entry) => [
            entry.key,
            entry.value.toString(),
            total == 0 ? '0%' : '${((entry.value / total) * 100).toStringAsFixed(1)}%',
          ],
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headers: const ['Label', 'Count', 'Share'],
          data: rows,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
        ),
      ],
    );
  }

  static String _composeIssueSummary(Map<String, dynamic> issue) {
    final parts = <String>[];
    final description = issue['description']?.toString();
    final location = issue['location']?.toString();
    final resolution = issue['resolution']?.toString();
    final resolvedAt = issue['resolved_at'];

    if (description != null && description.isNotEmpty) {
      parts.add(description);
    }
    if (location != null && location.isNotEmpty) {
      parts.add('Location: $location');
    }
    if (resolution != null && resolution.isNotEmpty) {
      parts.add('Resolution: $resolution');
    }
    if (resolvedAt != null) {
      final resolvedText = _formatFriendlyDateTime(resolvedAt);
      if (resolvedText.isNotEmpty) {
        parts.add('Resolved: $resolvedText');
      }
    }

    return parts.isEmpty ? '—' : parts.join('\n');
  }

  static final DateFormat _friendlyDateFormat = DateFormat('dd MMM yyyy HH:mm');

  static String _formatFriendlyDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      if (dateTime is DateTime) {
        return _friendlyDateFormat.format(dateTime.toLocal());
      }
      final dt = DateTime.tryParse(dateTime.toString());
      if (dt == null) return '';
      return _friendlyDateFormat.format(dt.toLocal());
    } catch (e) {
      return dateTime.toString();
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

