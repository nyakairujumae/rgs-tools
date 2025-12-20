import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tool.dart';
import '../models/tool_issue.dart';
import '../models/approval_workflow.dart';
import '../services/supabase_service.dart';

enum ReportType {
  comprehensive,
  toolsInventory,
  toolAssignments,
  technicianSummary,
  toolIssues,
  toolIssuesSummary,
  approvalWorkflowsSummary,
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
    List<ToolIssue>? issues,
    List<ApprovalWorkflow>? workflows,
    DateTime? startDate,
    DateTime? endDate,
    ReportFormat format = ReportFormat.pdf, // Default to PDF for all reports
  }) async {
    // All reports now use PDF format with table-based sheets
    return _generatePdfReport(
      reportType: reportType,
      tools: tools,
      technicians: technicians,
      issues: issues,
      workflows: workflows,
      startDate: startDate,
      endDate: endDate,
    );
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

    // Rename the default Sheet1 to the target name
    // Avoid using delete() as it may cause unmodifiable list errors
    if (excel.sheets.containsKey('Sheet1')) {
      try {
        excel.rename('Sheet1', targetSheetName);
      } catch (e) {
        debugPrint('Could not rename Sheet1: $e');
        // If rename fails, we'll just use Sheet1
      }
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
      case ReportType.toolIssuesSummary:
        await _generateToolIssuesSummaryReport(excel, startDate, endDate);
        break;
      case ReportType.approvalWorkflowsSummary:
        await _generateApprovalWorkflowsSummaryReport(excel, startDate, endDate);
        break;
      case ReportType.financialSummary:
        _generateFinancialSummaryReport(excel, tools);
        break;
      case ReportType.toolHistory:
        await _generateToolHistoryReport(excel, tools, startDate, endDate);
        break;
    }

    // Set all sheets to landscape orientation (optional - wrapped in try-catch)
    try {
      _setSheetsToLandscape(excel);
    } catch (e) {
      debugPrint('Warning: Could not set sheet landscape settings: $e');
      // Continue anyway - Excel file will still be generated
    }

    // Get directory and create file
    final directory = await _getDownloadsDirectory();
    final fileName = 'RGS_Tools_${_getReportTypeName(reportType)}_${_fileNameFormat.format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    
    // Save Excel file - wrap in try-catch to handle any unmodifiable list errors
    List<int>? bytesList;
    try {
      bytesList = excel.save();
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving Excel file: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Check if it's the unmodifiable list error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('unmodifiable') || errorString.contains('cannot remove')) {
        // This is a known issue with the Excel library
        // Try to work around it by creating a fresh Excel object
        debugPrint('⚠️ Unmodifiable list error detected - this is a known Excel library issue');
        debugPrint('⚠️ Attempting workaround...');
        
        // Re-throw with a more helpful error message
        throw Exception(
          'Excel export failed due to a library limitation. '
          'Please try exporting again, or contact support if the issue persists.'
        );
      }
      
      // For other errors, rethrow
      rethrow;
    }
    
    if (bytesList != null) {
      try {
        // Convert List<int> to Uint8List for file writing
        final bytes = Uint8List.fromList(bytesList);
        await file.writeAsBytes(bytes);
      } catch (e) {
        debugPrint('Error writing Excel file to disk: $e');
        rethrow;
      }
      // Landscape orientation modification is disabled - was causing errors
      // Users can set landscape orientation manually in Excel
    } else {
      throw Exception('Failed to generate Excel file - save returned null');
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
      case ReportType.toolIssuesSummary:
        return 'Tool Issues Summary';
      case ReportType.approvalWorkflowsSummary:
        return 'Approval Workflows Summary';
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
    List<ToolIssue>? issues,
    List<ApprovalWorkflow>? workflows,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    final reportTitle = _getReportTitle(reportType);
    final dateRangeText = _buildDateRangeText(startDate, endDate);

    // Use provided issues or fetch from database if not provided
    List<dynamic> toolIssues = [];
    if (reportType == ReportType.toolIssues || reportType == ReportType.financialSummary || reportType == ReportType.comprehensive) {
      if (issues != null) {
        // Convert ToolIssue objects to Map format for compatibility
        toolIssues = issues.map((issue) => issue.toJson()).toList();
      } else {
        // Fallback to database fetch if not provided
        toolIssues = await _fetchToolIssues(startDate, endDate);
      }
    }
    
    // Filter by date range if provided
    if (startDate != null || endDate != null) {
      toolIssues = toolIssues.where((issue) {
        final reportedAt = issue['reported_at'] ?? issue['reportedAt'];
        if (reportedAt == null) return false;
        final date = reportedAt is String ? DateTime.tryParse(reportedAt) : reportedAt;
        if (date == null) return false;
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
        return true;
      }).toList();
    }
    
    // Convert approval workflows to Map format for compatibility
    List<dynamic> approvalWorkflows = [];
    if (reportType == ReportType.approvalWorkflowsSummary || reportType == ReportType.comprehensive) {
      if (workflows != null) {
        approvalWorkflows = workflows.map((workflow) => workflow.toMap()).toList();
        
        // Filter by date range if provided
        if (startDate != null || endDate != null) {
          approvalWorkflows = approvalWorkflows.where((workflow) {
            final requestDate = workflow['request_date'];
            if (requestDate == null) return false;
            final date = requestDate is String ? DateTime.tryParse(requestDate) : requestDate;
            if (date == null) return false;
            if (startDate != null && date.isBefore(startDate)) return false;
            if (endDate != null && date.isAfter(endDate)) return false;
            return true;
          }).toList();
        }
      } else {
        approvalWorkflows = await _fetchApprovalWorkflows(startDate, endDate);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Use landscape for wider columns
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (context) {
          final widgets = <pw.Widget>[
            _buildPdfHeader(reportTitle, dateRangeText),
            pw.SizedBox(height: 8), // Reduced gap after header
          ];

          switch (reportType) {
            case ReportType.toolIssues:
              widgets.add(_buildToolIssuesPdfSection(toolIssues));
              break;
            case ReportType.toolIssuesSummary:
              widgets.add(_buildToolIssuesSummaryPdfSection(toolIssues));
              break;
            case ReportType.approvalWorkflowsSummary:
              widgets.add(_buildApprovalWorkflowsSummaryPdfSection(approvalWorkflows));
              break;
            case ReportType.toolsInventory:
              widgets.add(_buildToolsInventoryPdfSection(tools, technicians));
              break;
            case ReportType.toolAssignments:
              widgets.add(_buildToolAssignmentsPdfSection(tools, technicians, startDate, endDate));
              break;
            case ReportType.technicianSummary:
              widgets.add(_buildTechnicianSummaryPdfSection(tools, technicians));
              break;
            case ReportType.financialSummary:
              widgets.add(_buildFinancialSummaryPdfSection(tools, toolIssues));
              break;
            case ReportType.toolHistory:
              widgets.add(_buildToolHistoryPdfSection(tools, startDate, endDate));
              break;
            case ReportType.comprehensive:
              // Add comprehensive report sections - break down Columns to allow natural page breaks
              widgets.add(pw.Text(
                'Comprehensive Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ));
              widgets.add(pw.SizedBox(height: 12));
              
              // Tools Inventory Section - add title and table separately
              widgets.add(pw.Text(
                'Tools Inventory',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ));
              widgets.add(pw.SizedBox(height: 8));
              if (tools.isNotEmpty) {
                widgets.add(pw.Text(
                  'Total Tools: ${tools.length}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
                ));
                widgets.add(pw.SizedBox(height: 8));
              }
              widgets.add(_buildToolsInventoryTable(tools, technicians));
              widgets.add(pw.SizedBox(height: 16));
              
              // Tool Assignments Section
              widgets.add(pw.Text(
                'Tool Assignments',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ));
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(_buildToolAssignmentsTable(tools, technicians, startDate, endDate));
              widgets.add(pw.SizedBox(height: 16));
              
              // Technician Summary Section
              widgets.add(pw.Text(
                'Technician Summary',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ));
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(_buildTechnicianSummaryTable(tools, technicians));
              widgets.add(pw.SizedBox(height: 16));
              
              // Financial Summary Section
              widgets.add(pw.Text(
                'Financial Summary',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ));
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(_buildFinancialSummaryTable(tools, toolIssues));
              widgets.add(pw.SizedBox(height: 12));
              final statusCounts = <String, int>{};
              for (final tool in tools) {
                statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
              }
              widgets.add(pw.Text(
                'Status Distribution',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ));
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(pw.Table.fromTextArray(
                headers: const ['Status', 'Count'],
                data: statusCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
                cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.0),
                  1: pw.FlexColumnWidth(1.0),
                },
              ));
              
              // Tool Issues Section (if any) - break down Column to allow page breaks
              if (toolIssues.isNotEmpty) {
                widgets.add(pw.SizedBox(height: 16));
                widgets.add(pw.Text(
                  'Tool Issues Overview',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ));
                widgets.add(pw.SizedBox(height: 12));
                
                // Calculate metrics
                final statusCounts = <String, int>{};
                final priorityCounts = <String, int>{};
                double totalCost = 0.0;
                for (final item in toolIssues) {
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
                final openIssues = toolIssues.where((item) {
                  final status = (item['status'] ?? '').toString().toLowerCase();
                  return status != 'resolved' && status != 'closed';
                }).length;
                
                // Add metric cards
                widgets.add(pw.Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard('Total Issues', toolIssues.length.toString(), PdfColors.indigo),
                    _buildMetricCard('Open Issues', openIssues.toString(), PdfColors.deepOrange),
                    _buildMetricCard('Estimated Cost', _currencyFormat.format(totalCost), PdfColors.teal),
                  ],
                ));
                widgets.add(pw.SizedBox(height: 18));
                
                // Add summary tables
                widgets.add(pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: _buildSummaryTable('By Status', statusCounts)),
                    pw.SizedBox(width: 12),
                    pw.Expanded(child: _buildSummaryTable('By Priority', priorityCounts)),
                  ],
                ));
                widgets.add(pw.SizedBox(height: 18));
                
                // Add main issues table
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
                final tableData = toolIssues.map<List<String>>((item) {
                  final issue = item as Map<String, dynamic>;
                  final cost = issue['estimated_cost'];
                  return [
                    issue['tool_name']?.toString() ?? '',
                    issue['issue_type']?.toString() ?? '',
                    issue['priority']?.toString() ?? '',
                    issue['status']?.toString() ?? '',
                    _formatFriendlyDateTime(issue['reported_at']),
                    issue['reported_by']?.toString() ?? '',
                    cost is num ? _currencyFormat.format(cost.toDouble()) : '-',
                    _composeIssueSummary(issue),
                  ];
                }).toList();
                widgets.add(pw.Table.fromTextArray(
                  headers: tableHeaders,
                  data: tableData,
                  headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
                  border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
                  cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2.5),
                    1: pw.FlexColumnWidth(1.8),
                    2: pw.FlexColumnWidth(1.5),
                    3: pw.FlexColumnWidth(1.8),
                    4: pw.FlexColumnWidth(2.0),
                    5: pw.FlexColumnWidth(2.0),
                    6: pw.FlexColumnWidth(1.8),
                    7: pw.FlexColumnWidth(4.0),
                  },
                ));
              }
              
              // Approval Workflows Section (if any)
              if (approvalWorkflows.isNotEmpty) {
                widgets.add(pw.SizedBox(height: 16));
                widgets.add(pw.Text(
                  'Approval Workflows Overview',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ));
                widgets.add(pw.SizedBox(height: 12));
                
                // Calculate metrics
                final workflowStatusCounts = <String, int>{};
                final workflowTypeCounts = <String, int>{};
                for (final item in approvalWorkflows) {
                  final workflow = item as Map<String, dynamic>;
                  final status = (workflow['status'] ?? 'Unknown').toString();
                  final type = (workflow['request_type'] ?? 'Unknown').toString();
                  workflowStatusCounts[status] = (workflowStatusCounts[status] ?? 0) + 1;
                  workflowTypeCounts[type] = (workflowTypeCounts[type] ?? 0) + 1;
                }
                
                // Add metric cards
                widgets.add(pw.Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard('Total Workflows', approvalWorkflows.length.toString(), PdfColors.purple),
                    _buildMetricCard('Pending', workflowStatusCounts['Pending']?.toString() ?? '0', PdfColors.orange),
                    _buildMetricCard('Approved', workflowStatusCounts['Approved']?.toString() ?? '0', PdfColors.green),
                    _buildMetricCard('Rejected', workflowStatusCounts['Rejected']?.toString() ?? '0', PdfColors.red),
                  ],
                ));
                widgets.add(pw.SizedBox(height: 18));
                
                // Add summary tables
                widgets.add(pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: _buildSummaryTable('By Status', workflowStatusCounts)),
                    pw.SizedBox(width: 12),
                    pw.Expanded(child: _buildSummaryTable('By Type', workflowTypeCounts)),
                  ],
                ));
                widgets.add(pw.SizedBox(height: 18));
                
                // Add main workflows table
                final workflowHeaders = [
                  'Type',
                  'Title',
                  'Requester',
                  'Status',
                  'Priority',
                  'Request Date',
                  'Due Date',
                ];
                final workflowData = approvalWorkflows.map<List<String>>((item) {
                  final workflow = item as Map<String, dynamic>;
                  return [
                    workflow['request_type']?.toString() ?? '',
                    workflow['title']?.toString() ?? '',
                    workflow['requester_name']?.toString() ?? '',
                    workflow['status']?.toString() ?? '',
                    workflow['priority']?.toString() ?? '',
                    _formatFriendlyDateTime(workflow['request_date']),
                    _formatFriendlyDateTime(workflow['due_date']) ?? '-',
                  ];
                }).toList();
                widgets.add(pw.Table.fromTextArray(
                  headers: workflowHeaders,
                  data: workflowData,
                  headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
                  border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
                  cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2.0),
                    1: pw.FlexColumnWidth(3.0),
                    2: pw.FlexColumnWidth(2.0),
                    3: pw.FlexColumnWidth(1.5),
                    4: pw.FlexColumnWidth(1.5),
                    5: pw.FlexColumnWidth(2.0),
                    6: pw.FlexColumnWidth(2.0),
                  },
                ));
              }
              
              // Tool History Section
              widgets.add(pw.SizedBox(height: 16));
              widgets.add(pw.Text(
                'Tool History',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ));
              widgets.add(pw.SizedBox(height: 8));
              if (tools.isNotEmpty) {
                widgets.add(pw.Text(
                  'Total Tools: ${tools.length}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
                ));
                widgets.add(pw.SizedBox(height: 8));
              }
              widgets.add(_buildToolHistoryTable(tools, startDate, endDate));
              break;
          }

          return widgets;
        },
      ),
    );

    try {
      final directory = await _getDownloadsDirectory();
      final fileName = 'RGS_Tools_${_getReportTypeName(reportType)}_${_fileNameFormat.format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      
      // Save PDF with error handling
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      debugPrint('✅ PDF report saved successfully: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Error saving PDF report: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      
      // If it's a TooManyPagesException, provide helpful error message
      if (e.toString().contains('TooManyPages') || e.toString().contains('too many pages')) {
        throw Exception(
          'The report is too large to generate. '
          'Please try filtering the data or selecting a shorter time period.'
        );
      }
      
      // Re-throw with context
      throw Exception('Failed to save PDF report: $e');
    }
  }

  /// Set all sheets to landscape orientation and optimize column widths
  static void _setSheetsToLandscape(Excel excel) {
    try {
      // Create a copy of the keys to avoid unmodifiable list issues
      final sheetNames = List<String>.from(excel.sheets.keys);
      
      for (var sheetName in sheetNames) {
        try {
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
              continue;
            }
          }
        } catch (e) {
          debugPrint('Warning: Could not optimize sheet $sheetName: $e');
          // Continue with other sheets
          continue;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Warning: Could not optimize sheets for landscape: $e');
      debugPrint('Stack trace: $stackTrace');
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

      sheet.appendRow(List<dynamic>.from([
        technician.name ?? '',
        technician.employeeId ?? '',
        technician.phone ?? '',
        technician.email ?? '',
        technician.department ?? '',
        technician.status ?? '',
        assignedTools.length.toString(),
        toolNames,
      ]));
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
        sheet.appendRow(List<dynamic>.from(['No issues found in the selected period.']));
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

        sheet.appendRow(List<dynamic>.from([
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
        ]));

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
      sheet.appendRow(List<dynamic>.from(['Error fetching issues: $e']));
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

  /// Tool Issues Summary Report
  static Future<void> _generateToolIssuesSummaryReport(
    Excel excel,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final sheet = excel['Tool Issues Summary'];
    _addHeader(sheet, 'Tool Issues Summary Report', 20);
    _addInfoRow(sheet, 'Generated', _dateFormat.format(DateTime.now()));
    sheet.appendRow([]);

    try {
      final issues = await _fetchToolIssues(startDate, endDate);

      if (issues.isEmpty) {
        sheet.appendRow(List<dynamic>.from(['No issues found in the selected period.']));
        return;
      }

      // Calculate summary statistics
      final statusCounts = <String, int>{};
      final priorityCounts = <String, int>{};
      final typeCounts = <String, int>{};
      double totalCost = 0.0;

      for (final issue in issues) {
        final issueMap = issue as Map<String, dynamic>;
        final status = (issueMap['status'] ?? 'Unknown').toString();
        final priority = (issueMap['priority'] ?? 'Unspecified').toString();
        final issueType = (issueMap['issue_type'] ?? 'Unknown').toString();
        
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
        typeCounts[issueType] = (typeCounts[issueType] ?? 0) + 1;
        
        final cost = issueMap['estimated_cost'];
        if (cost is num) {
          totalCost += cost.toDouble();
        }
      }

      // Add summary section
      _addSectionHeader(sheet, 'Summary Statistics', 16);
      sheet.appendRow(['Total Issues', issues.length]);
      sheet.appendRow(['Estimated Total Cost', _currencyFormat.format(totalCost)]);
      sheet.appendRow([]);

      // Status Distribution
      _addSectionHeader(sheet, 'Status Distribution', 14);
      _addTableHeader(sheet, ['Status', 'Count']);
      for (final entry in statusCounts.entries) {
        sheet.appendRow([entry.key, entry.value]);
      }
      sheet.appendRow([]);

      // Priority Distribution
      _addSectionHeader(sheet, 'Priority Distribution', 14);
      _addTableHeader(sheet, ['Priority', 'Count']);
      for (final entry in priorityCounts.entries) {
        sheet.appendRow([entry.key, entry.value]);
      }
      sheet.appendRow([]);

      // Issue Type Distribution
      _addSectionHeader(sheet, 'Issue Type Distribution', 14);
      _addTableHeader(sheet, ['Issue Type', 'Count']);
      for (final entry in typeCounts.entries) {
        sheet.appendRow([entry.key, entry.value]);
      }
    } catch (e) {
      debugPrint('Error generating tool issues summary report: $e');
    }
  }

  /// Approval Workflows Summary Report
  static Future<void> _generateApprovalWorkflowsSummaryReport(
    Excel excel,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final sheet = excel['Approval Workflows Summary'];
    _addHeader(sheet, 'Approval Workflows Summary Report', 20);
    _addInfoRow(sheet, 'Generated', _dateFormat.format(DateTime.now()));
    sheet.appendRow([]);

    try {
      var query = _client.from('approval_workflows').select();
      
      if (startDate != null) {
        query = query.gte('request_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('request_date', endDate.toIso8601String());
      }

      final workflows = await query.order('request_date', ascending: false);

      if (workflows.isEmpty) {
        sheet.appendRow(List<dynamic>.from(['No approval workflows found in the selected period.']));
        return;
      }

      // Calculate summary statistics
      final statusCounts = <String, int>{};
      final typeCounts = <String, int>{};
      final priorityCounts = <String, int>{};

      for (final workflow in workflows) {
        final workflowMap = workflow as Map<String, dynamic>;
        final status = (workflowMap['status'] ?? 'Unknown').toString();
        final requestType = (workflowMap['request_type'] ?? 'Unknown').toString();
        final priority = (workflowMap['priority'] ?? 'Medium').toString();
        
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        typeCounts[requestType] = (typeCounts[requestType] ?? 0) + 1;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
      }

      // Add summary section
      _addSectionHeader(sheet, 'Summary Statistics', 16);
      sheet.appendRow(['Total Workflows', workflows.length]);
      sheet.appendRow([]);

      // Status Distribution
      _addSectionHeader(sheet, 'Status Distribution', 14);
      _addTableHeader(sheet, ['Status', 'Count']);
      for (final entry in statusCounts.entries) {
        sheet.appendRow([entry.key, entry.value]);
      }
      sheet.appendRow([]);

      // Request Type Distribution
      _addSectionHeader(sheet, 'Request Type Distribution', 14);
      _addTableHeader(sheet, ['Request Type', 'Count']);
      for (final entry in typeCounts.entries) {
        sheet.appendRow([entry.key, entry.value]);
      }
      sheet.appendRow([]);

      // Priority Distribution
      _addSectionHeader(sheet, 'Priority Distribution', 14);
      _addTableHeader(sheet, ['Priority', 'Count']);
      for (final entry in priorityCounts.entries) {
        sheet.appendRow([entry.key, entry.value]);
      }
    } catch (e) {
      debugPrint('Error generating approval workflows summary report: $e');
    }
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
      sheet.appendRow(List<dynamic>.from([
        tool.name,
        tool.category,
        tool.brand ?? '',
        tool.model ?? '',
        tool.serialNumber ?? '',
        tool.status,
        tool.assignedTo ?? 'Available',
        _formatDateTime(tool.updatedAt),
        _formatDateTime(tool.createdAt),
      ]));
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

      // Create a modifiable copy of the row list before appending
      final modifiableRow = List<dynamic>.from(row);
      sheet.appendRow(modifiableRow);

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

          sheet.appendRow(List<dynamic>.from([
            tool.name,
            tool.category,
            technicianName,
            _formatDateTime(assignment['assigned_date']),
            assignment['status'] ?? 'Active',
            isReturned ? 'Yes' : 'No',
          ]));
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
          sheet.appendRow(List<dynamic>.from(['No assignments found in the selected period.']));
          return;
        }

        for (final tool in filteredTools) {
          final technicianName = _getTechnicianName(tool.assignedTo, technicians);
          final isReturned = tool.status == 'Available';
          
          sheet.appendRow(List<dynamic>.from([
            tool.name,
            tool.category,
            technicianName,
            _formatDateTime(tool.updatedAt), // Use updatedAt as proxy for assignment date
            tool.status,
            isReturned ? 'Yes' : 'No',
          ]));
        }
      }

      final rowCount = assignmentsTableExists && assignments.isNotEmpty 
          ? assignments.length 
          : tools.where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty && t.status != 'Available').length;
      _formatTable(sheet, sheet.maxRows - rowCount, headers.length);
    } catch (e) {
      sheet.appendRow(List<dynamic>.from(['Error fetching assignments: $e']));
      debugPrint('Error in _addAssignmentsTable: $e');
    }
  }

  static void _addFinancialData(Sheet sheet, List<Tool> tools) {
    final totalPurchasePrice = tools.fold(0.0, (sum, tool) => sum + (tool.purchasePrice ?? 0));

    sheet.appendRow(List<dynamic>.from(['Metric', 'Value']));
    sheet.appendRow(List<dynamic>.from(['Total Purchase Value', 'AED ${totalPurchasePrice.toStringAsFixed(2)}']));

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

    sheet.appendRow(List<dynamic>.from(['Status', 'Count', 'Percentage']));
    final total = tools.length;
    for (final entry in statusCounts.entries) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      sheet.appendRow(List<dynamic>.from([entry.key, entry.value.toString(), '$percentage%']));
    }
  }

  static void _addConditionSummary(Sheet sheet, List<Tool> tools) {
    final conditionCounts = <String, int>{};
    for (final tool in tools) {
      conditionCounts[tool.condition] = (conditionCounts[tool.condition] ?? 0) + 1;
    }

    sheet.appendRow(List<dynamic>.from(['Condition', 'Count', 'Percentage']));
    final total = tools.length;
    for (final entry in conditionCounts.entries) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      sheet.appendRow(List<dynamic>.from([entry.key, entry.value.toString(), '$percentage%']));
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
      case ReportType.toolIssuesSummary:
        return 'ToolIssuesSummary';
      case ReportType.approvalWorkflowsSummary:
        return 'ApprovalWorkflowsSummary';
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

  static Future<List<dynamic>> _fetchApprovalWorkflows(DateTime? startDate, DateTime? endDate) async {
    var query = _client.from('approval_workflows').select();

    if (startDate != null) {
      query = query.gte('request_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('request_date', endDate.toIso8601String());
    }

    return await query.order('request_date', ascending: false);
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
      case ReportType.toolIssuesSummary:
        return 'Tool Issues Summary Report';
      case ReportType.approvalWorkflowsSummary:
        return 'Approval Workflows Summary Report';
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
    return '$startText - $endText'; // Use ASCII hyphen instead of en dash
  }

  static pw.Widget _buildPdfHeader(String title, String dateRangeText) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RGS HVAC Services',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey700,
          ),
        ),
        pw.SizedBox(height: 2), // Reduced spacing
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 4), // Reduced spacing
        pw.Row(
          children: [
            pw.Text(
              'Reporting period: $dateRangeText',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blueGrey600,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              'Generated: ${_formatFriendlyDateTime(DateTime.now().toIso8601String())}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey500,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8), // Reduced spacing before divider
        pw.Divider(color: PdfColors.blueGrey200, height: 1),
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
        cost is num ? _currencyFormat.format(cost.toDouble()) : '-', // Use ASCII hyphen instead of em dash
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

    return parts.isEmpty ? '-' : parts.join('\n'); // Use ASCII hyphen instead of em dash
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

  // PDF Report Sections - Table-based reports similar to Excel
  
  // Helper to build section titles
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
    );
  }

  // Extract table building methods for comprehensive report
  static pw.Widget _buildToolsInventoryTable(List<Tool> tools, List<dynamic> technicians) {
    if (tools.isEmpty) {
      return _buildPdfPlaceholder('No tools found in inventory.');
    }

    final headers = [
      'Tool Name',
      'Category',
      'Brand',
      'Model',
      'Serial Number',
      'Status',
      'Condition',
      'Location',
      'Assigned To',
      'Purchase Date',
      'Purchase Price',
    ];

    // Split tools into smaller batches to avoid TooManyPagesException
    // Process in smaller chunks to allow proper pagination
    const int batchSize = 10; // Process 10 tools at a time to ensure proper pagination
    final batches = <List<Tool>>[];
    for (int i = 0; i < tools.length; i += batchSize) {
      batches.add(tools.sublist(i, i + batchSize > tools.length ? tools.length : i + batchSize));
    }

    // Build table widgets for each batch
    final tableWidgets = <pw.Widget>[];
    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final tableData = batch.map<List<String>>((tool) {
        // Ensure purchasePrice is a valid number (not infinity or NaN)
        String priceStr = '';
        if (tool.purchasePrice != null) {
          final price = tool.purchasePrice!;
          if (price.isFinite && !price.isNaN) {
            priceStr = _currencyFormat.format(price);
          }
        }
        
        return [
          tool.name,
          tool.category,
          tool.brand ?? '',
          tool.model ?? '',
          tool.serialNumber ?? '',
          tool.status,
          tool.condition,
          tool.location ?? '',
          _getTechnicianName(tool.assignedTo, technicians),
          _formatDate(tool.purchaseDate),
          priceStr,
        ];
      }).toList();

      // Add batch header if multiple batches
      if (batches.length > 1) {
        tableWidgets.add(
          pw.Text(
            'Tools ${i * batchSize + 1} - ${i * batchSize + batch.length} of ${tools.length}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey700, fontStyle: pw.FontStyle.italic),
          ),
        );
        tableWidgets.add(pw.SizedBox(height: 4));
      }

      // Always include headers to ensure proper column width calculation
      tableWidgets.add(
        pw.Table.fromTextArray(
          headers: headers, // Always show headers for proper column width calculation
          data: tableData,
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
          cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey800),
          columnWidths: {
            0: const pw.FlexColumnWidth(3.0),
            1: const pw.FlexColumnWidth(2.0),
            2: const pw.FlexColumnWidth(2.0),
            3: const pw.FlexColumnWidth(2.0),
            4: const pw.FlexColumnWidth(2.5),
            5: const pw.FlexColumnWidth(1.5),
            6: const pw.FlexColumnWidth(1.5),
            7: const pw.FlexColumnWidth(2.5),
            8: const pw.FlexColumnWidth(2.5),
            9: const pw.FlexColumnWidth(2.0),
            10: const pw.FlexColumnWidth(2.0),
          },
        ),
      );

      // Add spacing between batches (except after last batch)
      if (i < batches.length - 1) {
        tableWidgets.add(pw.SizedBox(height: 12));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: tableWidgets,
    );
  }

  static pw.Widget _buildToolsInventoryPdfSection(List<Tool> tools, List<dynamic> technicians) {
    if (tools.isEmpty) {
      return _buildPdfPlaceholder('No tools found in inventory.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tools Inventory',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Total Tools: ${tools.length}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
        ),
        pw.SizedBox(height: 12),
        _buildToolsInventoryTable(tools, technicians),
      ],
    );
  }

  static pw.Widget _buildToolAssignmentsTable(List<Tool> tools, List<dynamic> technicians, DateTime? startDate, DateTime? endDate) {
    final assignedTools = tools.where((tool) => tool.assignedTo != null && tool.assignedTo!.isNotEmpty).toList();
    
    if (assignedTools.isEmpty) {
      return _buildPdfPlaceholder('No tool assignments found for the selected period.');
    }

    final headers = [
      'Tool Name',
      'Category',
      'Assigned To',
      'Status',
      'Condition',
      'Location',
      'Assigned Date',
    ];

    final tableData = assignedTools.map<List<String>>((tool) {
      return [
        tool.name,
        tool.category,
        _getTechnicianName(tool.assignedTo, technicians),
        tool.status,
        tool.condition,
        tool.location ?? '',
        _formatDateTime(tool.updatedAt),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: tableData,
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
      cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(2.0),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(2.5),
        6: pw.FlexColumnWidth(2.0),
      },
    );
  }

  static pw.Widget _buildToolAssignmentsPdfSection(List<Tool> tools, List<dynamic> technicians, DateTime? startDate, DateTime? endDate) {
    final assignedTools = tools.where((tool) => tool.assignedTo != null && tool.assignedTo!.isNotEmpty).toList();
    
    if (assignedTools.isEmpty) {
      return _buildPdfPlaceholder('No tool assignments found for the selected period.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tool Assignments',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Total Assignments: ${assignedTools.length}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
        ),
        pw.SizedBox(height: 12),
        _buildToolAssignmentsTable(tools, technicians, startDate, endDate),
      ],
    );
  }

  static pw.Widget _buildTechnicianSummaryTable(List<Tool> tools, List<dynamic> technicians) {
    final techToolCounts = <String, int>{};
    final techToolNames = <String, List<String>>{};

    for (final tool in tools) {
      if (tool.assignedTo != null && tool.assignedTo!.isNotEmpty) {
        final techName = _getTechnicianName(tool.assignedTo, technicians);
        techToolCounts[techName] = (techToolCounts[techName] ?? 0) + 1;
        techToolNames.putIfAbsent(techName, () => []).add(tool.name);
      }
    }

    if (techToolCounts.isEmpty) {
      return _buildPdfPlaceholder('No technician assignments found.');
    }

    final headers = ['Technician', 'Tools Assigned', 'Tool Names'];
    final tableData = techToolCounts.entries.map<List<String>>((entry) {
      final toolNames = techToolNames[entry.key]?.join(', ') ?? '';
      return [
        entry.key,
        entry.value.toString(),
        toolNames.length > 50 ? '${toolNames.substring(0, 50)}...' : toolNames,
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: tableData,
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
      cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(5.0),
      },
    );
  }

  static pw.Widget _buildTechnicianSummaryPdfSection(List<Tool> tools, List<dynamic> technicians) {
    final techToolCounts = <String, int>{};
    final techToolNames = <String, List<String>>{};

    for (final tool in tools) {
      if (tool.assignedTo != null && tool.assignedTo!.isNotEmpty) {
        final techName = _getTechnicianName(tool.assignedTo, technicians);
        techToolCounts[techName] = (techToolCounts[techName] ?? 0) + 1;
        techToolNames.putIfAbsent(techName, () => []).add(tool.name);
      }
    }

    if (techToolCounts.isEmpty) {
      return _buildPdfPlaceholder('No technician assignments found.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Technician Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Total Technicians: ${techToolCounts.length}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
        ),
        pw.SizedBox(height: 12),
        _buildTechnicianSummaryTable(tools, technicians),
      ],
    );
  }

  static pw.Widget _buildFinancialSummaryTable(List<Tool> tools, List<dynamic> toolIssues) {
    double totalPurchasePrice = 0.0;
    double totalExpenditures = 0.0;
    final statusCounts = <String, int>{};

    // Calculate total purchase price
    for (final tool in tools) {
      if (tool.purchasePrice != null) {
        totalPurchasePrice += tool.purchasePrice!;
      }
      statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
    }

    // Calculate total expenditures from tool issues
    for (final issue in toolIssues) {
      final cost = issue['estimated_cost'];
      if (cost != null) {
        if (cost is num) {
          totalExpenditures += cost.toDouble();
        } else if (cost is String) {
          final parsedCost = double.tryParse(cost);
          if (parsedCost != null) {
            totalExpenditures += parsedCost;
          }
        }
      }
    }

    final headers = ['Metric', 'Value'];
    final tableData = [
      ['Total Tools', tools.length.toString()],
      ['Total Purchase Price', _currencyFormat.format(totalPurchasePrice)],
      ['Total Expenditures', _currencyFormat.format(totalExpenditures)],
      ['Total Investment', _currencyFormat.format(totalPurchasePrice + totalExpenditures)],
    ];

    return pw.Table.fromTextArray(
      headers: headers,
      data: tableData,
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
      cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(3.5),
      },
    );
  }

  static pw.Widget _buildFinancialSummaryPdfSection(List<Tool> tools, List<dynamic> toolIssues) {
    final statusCounts = <String, int>{};

    for (final tool in tools) {
      statusCounts[tool.status] = (statusCounts[tool.status] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Financial Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 12),
        _buildFinancialSummaryTable(tools, toolIssues),
        pw.SizedBox(height: 18),
        pw.Text(
          'Status Distribution',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: const ['Status', 'Count'],
          data: statusCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
          cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.0),
            1: pw.FlexColumnWidth(1.0),
          },
        ),
      ],
    );
  }

  static pw.Widget _buildToolIssuesSummaryPdfSection(List<dynamic> toolIssues) {
    if (toolIssues.isEmpty) {
      return _buildPdfPlaceholder('No tool issues found for the selected period.');
    }

    // Calculate statistics
    final statusCounts = <String, int>{};
    final priorityCounts = <String, int>{};
    final typeCounts = <String, int>{};
    double totalCost = 0.0;
    
    for (final item in toolIssues) {
      final issue = item as Map<String, dynamic>;
      final status = (issue['status'] ?? 'Unknown').toString();
      final priority = (issue['priority'] ?? 'Unspecified').toString();
      final issueType = (issue['issue_type'] ?? 'Unknown').toString();
      
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
      typeCounts[issueType] = (typeCounts[issueType] ?? 0) + 1;
      
      final cost = issue['estimated_cost'];
      if (cost is num) {
        totalCost += cost.toDouble();
      }
    }

    final openIssues = toolIssues.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status != 'resolved' && status != 'closed';
    }).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tool Issues Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 12),
        
        // Overview metrics
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard('Total Issues', toolIssues.length.toString(), PdfColors.indigo),
            _buildMetricCard('Open Issues', openIssues.toString(), PdfColors.deepOrange),
            _buildMetricCard('Estimated Cost', _currencyFormat.format(totalCost), PdfColors.teal),
          ],
        ),
        pw.SizedBox(height: 18),
        
        // Status Distribution
        pw.Text(
          'Status Distribution',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: const ['Status', 'Count'],
          data: statusCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
          cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.0),
            1: pw.FlexColumnWidth(1.0),
          },
        ),
        pw.SizedBox(height: 18),
        
        // Priority Distribution
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Priority Distribution',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    headers: const ['Priority', 'Count'],
                    data: priorityCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                    border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
                    cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.0),
                      1: pw.FlexColumnWidth(1.0),
                    },
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Issue Type Distribution',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    headers: const ['Type', 'Count'],
                    data: typeCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                    border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
                    cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.0),
                      1: pw.FlexColumnWidth(1.0),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildApprovalWorkflowsSummaryPdfSection(List<dynamic> approvalWorkflows) {
    if (approvalWorkflows.isEmpty) {
      return _buildPdfPlaceholder('No approval workflows found for the selected period.');
    }

    // Calculate statistics
    final statusCounts = <String, int>{};
    final typeCounts = <String, int>{};
    final priorityCounts = <String, int>{};
    
    for (final item in approvalWorkflows) {
      final workflow = item as Map<String, dynamic>;
      final status = (workflow['status'] ?? 'Unknown').toString();
      final requestType = (workflow['request_type'] ?? 'Unknown').toString();
      final priority = (workflow['priority'] ?? 'Medium').toString();
      
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      typeCounts[requestType] = (typeCounts[requestType] ?? 0) + 1;
      priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
    }

    final pendingCount = statusCounts['Pending'] ?? 0;
    final approvedCount = statusCounts['Approved'] ?? 0;
    final rejectedCount = statusCounts['Rejected'] ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Approval Workflows Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 12),
        
        // Overview metrics
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard('Total Workflows', approvalWorkflows.length.toString(), PdfColors.purple),
            _buildMetricCard('Pending', pendingCount.toString(), PdfColors.orange),
            _buildMetricCard('Approved', approvedCount.toString(), PdfColors.green),
            _buildMetricCard('Rejected', rejectedCount.toString(), PdfColors.red),
          ],
        ),
        pw.SizedBox(height: 18),
        
        // Status Distribution
        pw.Text(
          'Status Distribution',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: const ['Status', 'Count'],
          data: statusCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
          border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
          cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.0),
            1: pw.FlexColumnWidth(1.0),
          },
        ),
        pw.SizedBox(height: 18),
        
        // Request Type and Priority Distribution
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Request Type Distribution',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    headers: const ['Type', 'Count'],
                    data: typeCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
                    border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
                    cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.0),
                      1: pw.FlexColumnWidth(1.0),
                    },
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Priority Distribution',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    headers: const ['Priority', 'Count'],
                    data: priorityCounts.entries.map((e) => [e.key, e.value.toString()]).toList(),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
                    border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
                    cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.0),
                      1: pw.FlexColumnWidth(1.0),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildToolHistoryTable(List<Tool> tools, DateTime? startDate, DateTime? endDate) {
    if (tools.isEmpty) {
      return _buildPdfPlaceholder('No tool history found for the selected period.');
    }

    final headers = [
      'Tool Name',
      'Category',
      'Status',
      'Condition',
      'Created',
      'Last Updated',
      'Location',
    ];

    final tableData = tools.map<List<String>>((tool) {
      return [
        tool.name,
        tool.category,
        tool.status,
        tool.condition,
        _formatDateTime(tool.createdAt),
        _formatDateTime(tool.updatedAt),
        tool.location ?? '',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: tableData,
      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.4),
      cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(2.0),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(2.0),
        5: pw.FlexColumnWidth(2.0),
        6: pw.FlexColumnWidth(2.5),
      },
    );
  }

  static pw.Widget _buildToolHistoryPdfSection(List<Tool> tools, DateTime? startDate, DateTime? endDate) {
    if (tools.isEmpty) {
      return _buildPdfPlaceholder('No tool history found for the selected period.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tool History',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Total Tools: ${tools.length}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey700),
        ),
        pw.SizedBox(height: 12),
        _buildToolHistoryTable(tools, startDate, endDate),
      ],
    );
  }

  static pw.Widget _buildComprehensivePdfSection(
    List<Tool> tools,
    List<dynamic> technicians,
    List<dynamic> toolIssues,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Comprehensive Report',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        ),
        pw.SizedBox(height: 20),
        _buildToolsInventoryPdfSection(tools, technicians),
        pw.SizedBox(height: 24),
        _buildToolAssignmentsPdfSection(tools, technicians, startDate, endDate),
        pw.SizedBox(height: 24),
        _buildTechnicianSummaryPdfSection(tools, technicians),
        pw.SizedBox(height: 24),
        _buildFinancialSummaryPdfSection(tools, toolIssues),
        if (toolIssues.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          _buildToolIssuesPdfSection(toolIssues),
        ],
      ],
    );
  }

  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isIOS) {
      // For iOS, use path_provider to get application documents directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        // Ensure directory exists
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      } catch (e) {
        // Fallback: use temp directory
        debugPrint('⚠️ Failed to get application documents directory, using temp directory: $e');
        final tempDir = Directory.systemTemp;
        final fallbackDir = Directory('${tempDir.path}/RGS_Reports');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      }
    } else if (Platform.isAndroid) {
      // For Android, use app documents directory (path_provider_android doesn't use FFI)
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
    
    // Fallback: use a temp directory that definitely exists
    return Directory.systemTemp;
  }
}
