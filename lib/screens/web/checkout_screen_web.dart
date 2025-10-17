import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/tool.dart';
import '../../models/technician.dart';
import "../../providers/supabase_tool_provider.dart";
import '../../providers/supabase_technician_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/status_chip.dart';
import '../../utils/error_handler.dart';

class CheckoutScreenWeb extends StatefulWidget {
  const CheckoutScreenWeb({super.key});

  @override
  State<CheckoutScreenWeb> createState() => _CheckoutScreenWebState();
}

class _CheckoutScreenWebState extends State<CheckoutScreenWeb> with ErrorHandlingMixin {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  
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
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search for Tool to Check Out',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter tool name, serial number, or barcode',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _searchQuery.isNotEmpty ? _searchTools : null,
            child: Text('Search Tools'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolDetails() {
    if (_selectedTool == null) return SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Tool',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTool!.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_selectedTool!.brand} ${_selectedTool!.model}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    if (_selectedTool!.serialNumber?.isNotEmpty == true) ...[
                      SizedBox(height: 4),
                      Text(
                        'SN: ${_selectedTool!.serialNumber}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusChip(status: _selectedTool!.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianSelection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Technician',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<Technician>>(
            future: Provider.of<SupabaseTechnicianProvider>(context, listen: false).getActiveTechnicians(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Error loading technicians: ${snapshot.error}');
              }
              
              final technicians = snapshot.data ?? [];
              
              return DropdownButtonFormField<Technician>(
                value: _selectedTechnician,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                hint: Text('Select a technician'),
                items: technicians.map((Technician technician) {
                  return DropdownMenuItem<Technician>(
                    value: technician,
                    child: Text(technician.name),
                  );
                }).toList(),
                onChanged: (Technician? newValue) {
                  setState(() {
                    _selectedTechnician = newValue;
                  });
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
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checkout Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checkout Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: _selectCheckoutDate,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20),
                            SizedBox(width: 8),
                            Text(
                              _checkoutDate != null 
                                ? '${_checkoutDate!.day}/${_checkoutDate!.month}/${_checkoutDate!.year}'
                                : 'Select date',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Return',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: _selectExpectedReturnDate,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20),
                            SizedBox(width: 8),
                            Text(
                              _expectedReturnDate != null 
                                ? '${_expectedReturnDate!.day}/${_expectedReturnDate!.month}/${_expectedReturnDate!.year}'
                                : 'Select date',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _canCheckout() ? _clearSelection : null,
              child: Text('Clear Selection'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canCheckout() ? _performCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Check Out Tool'),
            ),
          ),
        ],
      ),
    );
  }

  void _searchTools() async {
    if (_searchQuery.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final toolProvider = Provider.of<SupabaseToolProvider>(context, listen: false);
      // Simple search through loaded tools
      final allTools = toolProvider.tools;
      final tools = allTools.where((tool) => 
        tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        tool.serialNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) == true
      ).toList();
      
      if (tools.isNotEmpty) {
        setState(() {
          _selectedTool = tools.first;
          _checkoutDate = DateTime.now();
          _expectedReturnDate = DateTime.now().add(Duration(days: 7));
        });
      } else {
        _showErrorSnackBar('No tools found matching your search');
      }
    } catch (e) {
      _showErrorSnackBar('Error searching tools: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectCheckoutDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _checkoutDate = date;
      });
    }
  }

  void _selectExpectedReturnDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _expectedReturnDate = date;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedTool = null;
      _selectedTechnician = null;
      _checkoutDate = null;
      _expectedReturnDate = null;
      _notesController.clear();
    });
  }

  bool _canCheckout() {
    return _selectedTool != null && 
           _selectedTechnician != null && 
           _checkoutDate != null && 
           _expectedReturnDate != null && 
           !_isLoading;
  }

  void _performCheckout() async {
    if (!_canCheckout()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final toolProvider = Provider.of<SupabaseToolProvider>(context, listen: false);
      
      // Update tool status to assigned
      // Update tool status by creating a new tool with updated status
      final updatedTool = Tool(
        id: _selectedTool!.id,
        name: _selectedTool!.name,
        category: _selectedTool!.category,
        brand: _selectedTool!.brand,
        model: _selectedTool!.model,
        serialNumber: _selectedTool!.serialNumber,
        condition: _selectedTool!.condition,
        status: 'assigned',
        toolType: _selectedTool!.toolType,
        assignedTo: _selectedTechnician!.id,
        purchaseDate: _selectedTool!.purchaseDate,
        purchasePrice: _selectedTool!.purchasePrice,
        currentValue: _selectedTool!.currentValue,
        location: _selectedTool!.location,
        notes: _selectedTool!.notes,
        imagePath: _selectedTool!.imagePath,
        createdAt: _selectedTool!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await toolProvider.updateTool(updatedTool);
      
      _showSuccessSnackBar('Tool checked out successfully');
      _clearSelection();
    } catch (e) {
      _showErrorSnackBar('Error checking out tool: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
