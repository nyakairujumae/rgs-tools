import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/tool.dart';
import "../providers/supabase_tool_provider.dart";
import "../providers/supabase_technician_provider.dart";
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> with ErrorHandlingMixin {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isScanning = false;
  bool _isLoading = false;
  String _searchQuery = '';
  Tool? _selectedTool;
  DateTime? _checkinDate;
  String _returnCondition = 'Good';

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Checkin Tool'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
            onPressed: _toggleScanning,
          ),
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            labelStyle: TextStyle(color: Colors.grey),
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            bodyMedium: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
          // Scanner Section
          if (_isScanning) _buildScannerSection(),
          
          // Search Section
          _buildSearchSection(),
          
          // Tool Details
          if (_selectedTool != null) _buildToolDetails(),
          
          // Checkin Details
          if (_selectedTool != null) _buildCheckinDetails(),
          
          // Action Buttons
          _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MobileScanner(
          onDetect: _onBarcodeDetected,
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
            facing: CameraFacing.back,
            torchEnabled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search tools by name, brand, or serial number...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.qr_code_scanner),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 16),
          Consumer<SupabaseToolProvider>(
            builder: (context, toolProvider, child) {
              final inUseTools = toolProvider.tools
                  .where((tool) => tool.status == 'In Use')
                  .where((tool) => _searchQuery.isEmpty ||
                      tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (tool.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                      (tool.serialNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
                  .toList();

              if (inUseTools.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.build, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tools currently checked out',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: inUseTools.length,
                  itemBuilder: (context, index) {
                    final tool = inUseTools[index];
                    return Card(
                      color: Theme.of(context).cardTheme.color,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.getStatusColor(tool.status),
                          child: Icon(Icons.build, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        title: Text(tool.name, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${tool.category} • ${tool.brand ?? 'Unknown'}', style: TextStyle(color: Colors.grey)),
                            if (tool.assignedTo != null)
                              Consumer<SupabaseTechnicianProvider>(
                                builder: (context, technicianProvider, child) {
                                  final technicianName = technicianProvider.getTechnicianNameById(tool.assignedTo) ?? 'Unknown';
                                  return Text('Assigned to: $technicianName', 
                                       style: TextStyle(fontSize: 12, color: Colors.grey));
                                },
                              ),
                          ],
                        ),
                        trailing: StatusChip(status: tool.status),
                        onTap: () {
                          setState(() {
                            _selectedTool = tool;
                            _isScanning = false;
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.build, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Tool to Check In',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildDetailRow('Name', _selectedTool!.name),
              _buildDetailRow('Category', _selectedTool!.category),
              if (_selectedTool!.brand != null) _buildDetailRow('Brand', _selectedTool!.brand!),
              if (_selectedTool!.serialNumber != null) _buildDetailRow('Serial Number', _selectedTool!.serialNumber!),
              if (_selectedTool!.assignedTo != null) _buildDetailRow('Assigned To', _selectedTool!.assignedTo!),
              _buildDetailRow('Current Status', _selectedTool!.status, 
                  statusWidget: StatusChip(status: _selectedTool!.status)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checkin Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          
          // Checkin Date
          InkWell(
            onTap: _selectCheckinDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Checkin Date *',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _checkinDate != null
                    ? '${_checkinDate!.day}/${_checkinDate!.month}/${_checkinDate!.year}'
                    : 'Select date',
                style: TextStyle(
                  color: _checkinDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Return Condition
          DropdownButtonFormField<String>(
            value: _returnCondition,
            decoration: const InputDecoration(
              labelText: 'Return Condition *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
              DropdownMenuItem(value: 'Good', child: Text('Good')),
              DropdownMenuItem(value: 'Fair', child: Text('Fair')),
              DropdownMenuItem(value: 'Poor', child: Text('Poor')),
              DropdownMenuItem(value: 'Needs Repair', child: Text('Needs Repair')),
            ],
            onChanged: (value) {
              setState(() {
                _returnCondition = value!;
              });
            },
          ),
          SizedBox(height: 16),
          
          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Checkin Notes',
              border: OutlineInputBorder(),
              hintText: 'Any issues, damage, or additional information...',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canCheckin() ? _performCheckin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Theme.of(context).textTheme.bodyLarge?.color)
                  : Text(
                      'Checkin Tool',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? statusWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
              value,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? barcodeValue = barcodes.first.rawValue;
      if (barcodeValue != null) {
        _searchByBarcode(barcodeValue);
      }
    }
  }

  void _searchByBarcode(String barcode) {
    final tool = context.read<SupabaseToolProvider>().tools.firstWhere(
      (tool) => tool.serialNumber == barcode && tool.status == 'In Use',
      orElse: () => Tool(name: '', category: '', condition: ''),
    );
    
    if (tool.name.isNotEmpty) {
      setState(() {
        _selectedTool = tool;
        _isScanning = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tool not found or not currently checked out'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  Future<void> _selectCheckinDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkinDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() {
        _checkinDate = date;
      });
    }
  }

  bool _canCheckin() {
    return _selectedTool != null && 
           _checkinDate != null &&
           !_isLoading;
  }

  Future<void> _performCheckin() async {
    if (!_canCheckin()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine new status based on condition
      String newStatus = 'Available';
      if (_returnCondition == 'Poor' || _returnCondition == 'Needs Repair') {
        newStatus = 'Maintenance';
      }

      // Update tool status and condition
      final updatedTool = _selectedTool!.copyWith(
        status: newStatus,
        condition: _returnCondition,
        assignedTo: null, // Remove assignment
        updatedAt: DateTime.now().toIso8601String(),
      );

      await context.read<SupabaseToolProvider>().updateTool(updatedTool);

      // TODO: Create tool usage record in database
      // This would typically be done through a service layer

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedTool!.name} checked in successfully'),
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