import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../models/tool_template.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../utils/error_handler.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _csvController = TextEditingController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _parsedData = [];
  List<String> _errors = [];
  String _selectedTemplate = '';

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bulk Import Tools'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions Card
              _buildInstructionsCard(),
              SizedBox(height: 24),

              // Template Selection
              _buildTemplateSelection(),
              SizedBox(height: 24),

              // CSV Input
              _buildCsvInput(),
              SizedBox(height: 24),

              // Parse Button
              _buildParseButton(),
              SizedBox(height: 24),

              // Preview Data
              if (_parsedData.isNotEmpty) _buildDataPreview(),
              if (_errors.isNotEmpty) _buildErrorList(),

              SizedBox(height: 32),

              // Import Button
              if (_parsedData.isNotEmpty) _buildImportButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Import Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '1. Select a tool template below\n'
              '2. Copy your data from Excel/CSV\n'
              '3. Paste it in the text area\n'
              '4. Click "Parse Data" to preview\n'
              '5. Review and import the tools',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Required columns: Name, Category, Brand, Serial Number, Purchase Date, Purchase Price',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tool Template',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedTemplate.isEmpty ? null : _selectedTemplate,
          decoration: const InputDecoration(
            labelText: 'Select Template (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('No Template - Manual Entry'),
            ),
            ...ToolTemplates.defaultTemplates.map((template) {
              return DropdownMenuItem(
                value: template.name,
                child: Text(template.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTemplate = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildCsvInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CSV Data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _csvController,
          decoration: const InputDecoration(
            labelText: 'Paste your CSV data here',
            border: OutlineInputBorder(),
            hintText: 'Name,Category,Brand,Serial Number,Purchase Date,Purchase Price\n'
                'Multimeter,Testing Equipment,Fluke,FL123456,2024-01-15,400.00',
            prefixIcon: Icon(Icons.table_chart),
          ),
          maxLines: 10,
          minLines: 5,
        ),
      ],
    );
  }

  Widget _buildParseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _parseCsvData,
        icon: _isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.analytics),
        label: Text(_isLoading ? 'Parsing...' : 'Parse Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDataPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.preview, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Preview (${_parsedData.length} tools)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: _parsedData.length,
            itemBuilder: (context, index) {
              final item = _parsedData[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(item['name'] ?? 'Unknown'),
                subtitle: Text('${item['category']} • ${item['brand']}'),
                trailing: Text(
                  '\$${item['purchasePrice'] ?? '0.00'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text(
              'Errors (${_errors.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _errors.map((error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• $error',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImportButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _errors.isEmpty ? _importTools : null,
            icon: Icon(Icons.upload),
            label: Text('Import Tools'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _parsedData.clear();
                _errors.clear();
                _csvController.clear();
              });
            },
            icon: Icon(Icons.clear),
            label: Text('Clear All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _parseCsvData() async {
    setState(() {
      _isLoading = true;
      _parsedData.clear();
      _errors.clear();
    });

    try {
      final csvData = _csvController.text.trim();
      if (csvData.isEmpty) {
        setState(() {
          _errors.add('Please enter CSV data');
        });
        return;
      }

      final lines = csvData.split('\n');
      if (lines.length < 2) {
        setState(() {
          _errors.add('CSV must have at least a header row and one data row');
        });
        return;
      }

      final headers = lines[0].split(',').map((h) => h.trim()).toList();
      final requiredHeaders = ['name', 'category', 'brand', 'serialNumber', 'purchaseDate', 'purchasePrice'];
      
      // Check for required headers
      for (final required in requiredHeaders) {
        if (!headers.any((h) => h.toLowerCase().contains(required.toLowerCase()))) {
          _errors.add('Missing required column: $required');
        }
      }

      if (_errors.isNotEmpty) {
        return;
      }

      // Parse data rows
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = line.split(',');
        if (values.length != headers.length) {
          _errors.add('Row ${i + 1}: Column count mismatch');
          continue;
        }

        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          rowData[headers[j].toLowerCase()] = values[j].trim();
        }

        // Validate required fields
        if (rowData['name']?.isEmpty ?? true) {
          _errors.add('Row ${i + 1}: Name is required');
          continue;
        }

        if (rowData['category']?.isEmpty ?? true) {
          _errors.add('Row ${i + 1}: Category is required');
          continue;
        }

        // Parse numeric values
        try {
          if (rowData['purchaseprice'] != null) {
            rowData['purchaseprice'] = double.parse(rowData['purchaseprice']);
          }
        } catch (e) {
          _errors.add('Row ${i + 1}: Invalid purchase price format');
          continue;
        }

        _parsedData.add(rowData);
      }

    } catch (e) {
      _errors.add('Error parsing CSV: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importTools() async {
    if (_parsedData.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      
      for (final data in _parsedData) {
        final tool = Tool(
          name: data['name'],
          category: data['category'],
          brand: data['brand'],
          model: data['model'],
          serialNumber: data['serialnumber'],
          purchaseDate: data['purchasedate'],
          purchasePrice: data['purchaseprice']?.toDouble() ?? 0.0,
          currentValue: data['purchaseprice']?.toDouble() ?? 0.0,
          condition: data['condition'] ?? 'Good',
          location: data['location'],
          status: 'Available',
          notes: data['notes'],
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await toolProvider.addTool(tool);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${_parsedData.length} tools'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
