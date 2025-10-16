import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with ErrorHandlingMixin {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isScanning = false;
  bool _isLoading = false;
  String _searchQuery = '';
  Tool? _selectedTool;
  Technician? _selectedTechnician;
  DateTime? _checkoutDate;
  DateTime? _expectedReturnDate;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout Tool'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
            onPressed: _toggleScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner Section
          if (_isScanning) _buildScannerSection(),
          
          // Search Section
          _buildSearchSection(),
          
          // Tool Selection
          if (_selectedTool != null) _buildToolDetails(),
          
          // Technician Selection
          _buildTechnicianSelection(),
          
          // Checkout Details
          if (_selectedTool != null && _selectedTechnician != null) _buildCheckoutDetails(),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    // Skip scanner on web
    if (kIsWeb) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text(
                'Scanner not available on web',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please use the search function below',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
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
              final availableTools = toolProvider.tools
                  .where((tool) => tool.status == 'Available')
                  .where((tool) => _searchQuery.isEmpty ||
                      tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (tool.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                      (tool.serialNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
                  .toList();

              if (availableTools.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.build, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No available tools found',
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
                  itemCount: availableTools.length,
                  itemBuilder: (context, index) {
                    final tool = availableTools[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.getStatusColor(tool.status),
                          child: Icon(Icons.build, color: Colors.white),
                        ),
                        title: Text(tool.name),
                        subtitle: Text('${tool.category} • ${tool.brand ?? 'Unknown'}'),
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
                    'Selected Tool',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
              SizedBox(height: 12),
              _buildDetailRow('Name', _selectedTool!.name),
              _buildDetailRow('Category', _selectedTool!.category),
              if (_selectedTool!.brand != null) _buildDetailRow('Brand', _selectedTool!.brand!),
              if (_selectedTool!.serialNumber != null) _buildDetailRow('Serial Number', _selectedTool!.serialNumber!),
              _buildDetailRow('Status', _selectedTool!.status, statusWidget: StatusChip(status: _selectedTool!.status)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTechnicianSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Text(
                  'Select Technician',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
          Consumer<SupabaseTechnicianProvider>(
            builder: (context, technicianProvider, child) {
              final activeTechnicians = technicianProvider.technicians
                  .where((tech) => tech.status == 'Active')
                  .toList();

              return DropdownButtonFormField<Technician>(
                value: _selectedTechnician,
                decoration: const InputDecoration(
                  labelText: 'Technician *',
                  border: OutlineInputBorder(),
                ),
                items: activeTechnicians.map((technician) {
                  return DropdownMenuItem(
                          value: technician,
                    child: Text(technician.name),
                  );
                }).toList(),
                onChanged: (value) {
                            setState(() {
                              _selectedTechnician = value;
                            });
                          },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a technician';
                  }
                  return null;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Text(
            'Checkout Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          
          // Checkout Date
          InkWell(
            onTap: _selectCheckoutDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Checkout Date *',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _checkoutDate != null
                    ? '${_checkoutDate!.day}/${_checkoutDate!.month}/${_checkoutDate!.year}'
                    : 'Select date',
                style: TextStyle(
                  color: _checkoutDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Expected Return Date
          InkWell(
            onTap: _selectExpectedReturnDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Expected Return Date',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _expectedReturnDate != null
                    ? '${_expectedReturnDate!.day}/${_expectedReturnDate!.month}/${_expectedReturnDate!.year}'
                    : 'Select date (optional)',
                style: TextStyle(
                  color: _expectedReturnDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Notes
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
              labelText: 'Notes',
                    border: OutlineInputBorder(),
              hintText: 'Additional information...',
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
              onPressed: _canCheckout() ? _performCheckout : null,
                    style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Checkout Tool',
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
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
              value,
              style: TextStyle(color: AppTheme.textPrimary),
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
      (tool) => tool.serialNumber == barcode && tool.status == 'Available',
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
          content: Text('Tool not found or not available'),
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

  Future<void> _selectCheckoutDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkoutDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _checkoutDate = date;
      });
    }
  }

  Future<void> _selectExpectedReturnDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expectedReturnDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _expectedReturnDate = date;
      });
    }
  }

  bool _canCheckout() {
    return _selectedTool != null && 
           _selectedTechnician != null && 
           _checkoutDate != null &&
           !_isLoading;
  }

  Future<void> _performCheckout() async {
    if (!_canCheckout()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update tool status and assignment
      final updatedTool = _selectedTool!.copyWith(
        status: 'In Use',
        assignedTo: _selectedTechnician!.name,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await context.read<SupabaseToolProvider>().updateTool(updatedTool);

      // TODO: Create tool usage record in database
      // This would typically be done through a service layer

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedTool!.name} checked out to ${_selectedTechnician!.name}'),
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