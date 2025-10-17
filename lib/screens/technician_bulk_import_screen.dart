import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../providers/supabase_tool_provider.dart';
import '../models/tool.dart';

class TechnicianBulkImportScreen extends StatefulWidget {
  const TechnicianBulkImportScreen({super.key});

  @override
  State<TechnicianBulkImportScreen> createState() => _TechnicianBulkImportScreenState();
}

class _TechnicianBulkImportScreenState extends State<TechnicianBulkImportScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _importedData = [];
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Import Tools'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Important notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'Initial Setup Only',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This feature is for initial setup only. After setup, only admins can add tools.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Instructions
            Text(
              'Import Instructions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Prepare a CSV file with the following columns:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• name (required)\n• category (required)\n• brand\n• model\n• serial_number\n• condition (Excellent/Good/Fair/Poor/Needs Repair)\n• location\n• status (Available/In Use/Maintenance/Retired)\n• notes',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '2. Click "Select CSV File" to choose your file',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. Review the imported data',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '4. Click "Import All Tools" to add them to the system',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // File selection
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _selectFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_fileName ?? 'Select CSV File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            if (_importedData.isNotEmpty) ...[
              SizedBox(height: 24),
              
              Text(
                'Imported Data (${_importedData.length} tools)',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              
              // Preview table
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Brand')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: _importedData.take(10).map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row['name'] ?? '')),
                          DataCell(Text(row['category'] ?? '')),
                          DataCell(Text(row['brand'] ?? '')),
                          DataCell(Text(row['status'] ?? '')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              if (_importedData.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${_importedData.length - 10} more tools',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              SizedBox(height: 24),
              
              // Import button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _importTools,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Import All Tools (${_importedData.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileName = file.name;
        });

        // Parse CSV file
        final bytes = file.bytes;
        if (bytes != null) {
          final csvContent = String.fromCharCodes(bytes);
          _parseCSV(csvContent);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _parseCSV(String csvContent) {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return;

    final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
    final data = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      
      final values = lines[i].split(',');
      if (values.length != headers.length) continue;

      final row = <String, dynamic>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      
      // Only add if name and category are present
      if (row['name'] != null && row['name'].toString().isNotEmpty &&
          row['category'] != null && row['category'].toString().isNotEmpty) {
        data.add(row);
      }
    }

    setState(() {
      _importedData = data;
    });
  }

  Future<void> _importTools() async {
    if (_importedData.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int successCount = 0;
      int errorCount = 0;

      for (final row in _importedData) {
        try {
          final tool = Tool(
            name: row['name']?.toString() ?? '',
            category: row['category']?.toString() ?? '',
            brand: row['brand']?.toString().isEmpty == true ? null : row['brand']?.toString(),
            model: row['model']?.toString().isEmpty == true ? null : row['model']?.toString(),
            serialNumber: row['serial_number']?.toString().isEmpty == true ? null : row['serial_number']?.toString(),
            condition: row['condition']?.toString() ?? 'Good',
            location: row['location']?.toString().isEmpty == true ? null : row['location']?.toString(),
            status: row['status']?.toString() ?? 'Available',
            toolType: 'inventory',
            notes: row['notes']?.toString().isEmpty == true ? null : row['notes']?.toString(),
          );

          await context.read<SupabaseToolProvider>().addTool(tool);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Error importing tool: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import completed: $successCount successful, $errorCount failed'),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );
        
        if (successCount > 0) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
