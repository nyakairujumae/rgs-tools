import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import '../models/location.dart';
import '../models/permanent_assignment.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';

class BulkAssignmentScreen extends StatefulWidget {
  const BulkAssignmentScreen({super.key});

  @override
  State<BulkAssignmentScreen> createState() => _BulkAssignmentScreenState();
}

class _BulkAssignmentScreenState extends State<BulkAssignmentScreen> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  Technician? _selectedTechnician;
  Location? _selectedLocation;
  DateTime? _assignmentDate;
  String _assignmentType = 'Permanent';
  bool _isLoading = false;
  
  // Bulk selection
  Set<String> _selectedToolIds = {};
  List<Tool> _availableTools = [];
  List<Tool> _suggestedTools = [];
  bool _showSuggestions = false;
  String? _lastAssignedTechnicianId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<SupabaseToolProvider>().loadTools(),
      context.read<SupabaseTechnicianProvider>().loadTechnicians(),
    ]);
    
    if (mounted) {
      setState(() {
        _availableTools = context.read<SupabaseToolProvider>().tools
            .where((tool) => tool.status == 'Available')
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bulk Tool Assignment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedToolIds.isNotEmpty)
            TextButton(
              onPressed: _clearSelection,
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Consumer2<SupabaseToolProvider, SupabaseTechnicianProvider>(
        builder: (context, toolProvider, technicianProvider, child) {
          return Column(
            children: [
              // Selection Summary
              if (_selectedToolIds.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Text(
                        '${_selectedToolIds.length} tool${_selectedToolIds.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: _assignSelectedTools,
                        child: Text('Assign All'),
                      ),
                    ],
                  ),
                ),

              // Smart Suggestions
              if (_showSuggestions && _suggestedTools.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Smart Suggestion',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Want to assign the same tools as the previous technician?',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _suggestedTools.map((tool) {
                          return Chip(
                            label: Text(tool.name),
                            onDeleted: () {
                              setState(() {
                                _suggestedTools.remove(tool);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _acceptSuggestions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Yes, Add These Tools'),
                          ),
                          SizedBox(width: 12),
                          TextButton(
                            onPressed: _dismissSuggestions,
                            child: Text('No, Thanks'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Tools Grid
              Expanded(
                child: _availableTools.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No available tools',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'All tools are currently assigned or in maintenance',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _availableTools.length,
                        itemBuilder: (context, index) {
                          final tool = _availableTools[index];
                          final isSelected = _selectedToolIds.contains(tool.id);
                          
                          return _buildToolCard(tool, isSelected);
                        },
                      ),
              ),

              // Assignment Form (Bottom Sheet)
              if (_selectedToolIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Assignment Details',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Technician Selection
                        DropdownButtonFormField<Technician>(
                          value: _selectedTechnician,
                          decoration: const InputDecoration(
                            labelText: 'Select Technician *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: technicianProvider.technicians.map((technician) {
                            return DropdownMenuItem(
                              value: technician,
                              child: Text(technician.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTechnician = value;
                              _checkForSuggestions();
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a technician';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Assignment Date
                        InkWell(
                          onTap: _selectAssignmentDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Assignment Date *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _assignmentDate != null
                                  ? '${_assignmentDate!.day}/${_assignmentDate!.month}/${_assignmentDate!.year}'
                                  : 'Select date',
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Assign Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _assignSelectedTools,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Assign ${_selectedToolIds.length} Tool${_selectedToolIds.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolCard(Tool tool, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleToolSelection(tool.id!),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                child: tool.imagePath != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          tool.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.build, size: 40, color: Colors.grey);
                          },
                        ),
                      )
                    : const Icon(Icons.build, size: 40, color: Colors.grey),
              ),
            ),
            
            // Tool Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      tool.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    StatusChip(status: tool.status),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleToolSelection(String toolId) {
    setState(() {
      if (_selectedToolIds.contains(toolId)) {
        _selectedToolIds.remove(toolId);
      } else {
        _selectedToolIds.add(toolId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedToolIds.clear();
      _showSuggestions = false;
    });
  }

  void _checkForSuggestions() {
    if (_selectedTechnician != null && _lastAssignedTechnicianId != null) {
      // Check if this technician has been assigned tools before
      // This would require checking assignment history
      // For now, we'll show a simple suggestion
      setState(() {
        _showSuggestions = true;
        _suggestedTools = _availableTools.take(3).toList(); // Mock suggestion
      });
    }
  }

  void _acceptSuggestions() {
    setState(() {
      for (final tool in _suggestedTools) {
        _selectedToolIds.add(tool.id!);
      }
      _showSuggestions = false;
    });
  }

  void _dismissSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
  }

  Future<void> _selectAssignmentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _assignmentDate = date;
      });
    }
  }

  Future<void> _assignSelectedTools() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTechnician == null || _assignmentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Here you would implement the bulk assignment logic
      // For now, we'll just show a success message
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully assigned ${_selectedToolIds.length} tools'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear selection and reset form
        setState(() {
          _selectedToolIds.clear();
          _selectedTechnician = null;
          _assignmentDate = null;
          _notesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning tools: $e'),
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
