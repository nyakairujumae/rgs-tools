import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../models/tool.dart';
import '../models/maintenance_schedule.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with ErrorHandlingMixin {
  String _selectedFilter = 'All';
  bool _isLoading = false;
  List<MaintenanceSchedule> _maintenanceItems = [];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    // Sample maintenance data
    _maintenanceItems = [
      MaintenanceSchedule(
        id: 1,
        toolId: 1,
        toolName: 'Digital Multimeter',
        maintenanceType: 'Calibration',
        description: 'Annual calibration check for accuracy',
        scheduledDate: DateTime.now().add(Duration(days: 4)),
        priority: 'High',
        assignedTo: 'Ahmed Hassan',
        estimatedCost: 50.0,
        status: 'Scheduled',
      ),
      MaintenanceSchedule(
        id: 2,
        toolId: 2,
        toolName: 'Pressure Gauge',
        maintenanceType: 'Inspection',
        description: 'Check for leaks and accuracy',
        scheduledDate: DateTime.now().subtract(Duration(days: 2)),
        priority: 'Medium',
        assignedTo: 'Mohammed Ali',
        estimatedCost: 25.0,
        status: 'Overdue',
      ),
      MaintenanceSchedule(
        id: 3,
        toolId: 3,
        toolName: 'Vacuum Pump',
        maintenanceType: 'Cleaning',
        description: 'Clean and lubricate pump components',
        scheduledDate: DateTime.now().subtract(Duration(days: 1)),
        priority: 'Low',
        assignedTo: 'Omar Al-Rashid',
        estimatedCost: 15.0,
        status: 'In Progress',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Schedule'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddMaintenanceDialog,
            icon: Icon(Icons.add),
            tooltip: 'Schedule Maintenance',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          
          // Maintenance List
          Expanded(
            child: _buildMaintenanceList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMaintenanceDialog,
        icon: Icon(Icons.schedule),
        label: Text('Schedule'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Scheduled', 'Overdue', 'In Progress', 'Completed'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceList() {
    final filteredItems = _filterMaintenanceItems(_maintenanceItems);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildMaintenanceCard(item);
      },
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'Overdue':
        title = 'No Overdue Maintenance';
        subtitle = 'All maintenance is up to date!';
        icon = Icons.check_circle;
        break;
      case 'Scheduled':
        title = 'No Scheduled Maintenance';
        subtitle = 'No maintenance is currently scheduled';
        icon = Icons.schedule;
        break;
      case 'In Progress':
        title = 'No Active Maintenance';
        subtitle = 'No maintenance is currently in progress';
        icon = Icons.build;
        break;
      case 'Completed':
        title = 'No Completed Maintenance';
        subtitle = 'No maintenance has been completed yet';
        icon = Icons.done_all;
        break;
      default:
        title = 'No Maintenance Scheduled';
        subtitle = 'Start by scheduling maintenance for your tools';
        icon = Icons.schedule;
    }

    return EmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actionText: 'Schedule Maintenance',
      onAction: _showAddMaintenanceDialog,
    );
  }

  Widget _buildMaintenanceCard(MaintenanceSchedule item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.toolName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                StatusChip(status: item.status),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Maintenance Type and Priority
            Row(
              children: [
                Icon(
                  Icons.build,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  item.maintenanceType,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(item.priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.priority,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(item.priority),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Description
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Date and Status Info
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  _formatDate(item.scheduledDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  item.dueStatus,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isOverdue ? AppTheme.errorColor : AppTheme.textSecondary,
                    fontWeight: item.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            
            if (item.assignedTo != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Assigned to: ${item.assignedTo}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            
            if (item.estimatedCost != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Est. Cost: \$${item.estimatedCost!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                if (item.status == 'Scheduled' || item.status == 'Overdue')
                  TextButton.icon(
                    onPressed: () => _startMaintenance(item),
                    icon: Icon(Icons.play_arrow, size: 16),
                    label: Text('Start'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                if (item.status == 'In Progress')
                  TextButton.icon(
                    onPressed: () => _completeMaintenance(item),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Complete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _viewMaintenanceDetails(item),
                  icon: Icon(Icons.info_outline, size: 16),
                  label: Text('Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<MaintenanceSchedule> _getMockMaintenanceData() {
    final now = DateTime.now();
    return [
      MaintenanceSchedule(
        id: 1,
        toolId: 1,
        toolName: 'Digital Multimeter',
        maintenanceType: 'Calibration',
        description: 'Annual calibration check for accuracy',
        scheduledDate: now.add(const Duration(days: 5)),
        priority: 'High',
        assignedTo: 'Ahmed Hassan',
        estimatedCost: 50.0,
        intervalDays: 365,
      ),
      MaintenanceSchedule(
        id: 2,
        toolId: 2,
        toolName: 'Refrigerant Manifold Gauge Set',
        maintenanceType: 'Routine Inspection',
        description: 'Check for leaks and gauge accuracy',
        scheduledDate: now.subtract(const Duration(days: 2)),
        status: 'Overdue',
        priority: 'Medium',
        assignedTo: 'Mohammed Ali',
        estimatedCost: 25.0,
        intervalDays: 30,
      ),
      MaintenanceSchedule(
        id: 3,
        toolId: 3,
        toolName: 'Vacuum Pump',
        maintenanceType: 'Cleaning',
        description: 'Clean and lubricate pump components',
        scheduledDate: now,
        status: 'In Progress',
        priority: 'Low',
        assignedTo: 'Omar Al-Rashid',
        estimatedCost: 15.0,
        intervalDays: 14,
      ),
      MaintenanceSchedule(
        id: 4,
        toolId: 4,
        toolName: 'Cordless Drill',
        maintenanceType: 'Battery Replacement',
        description: 'Replace old battery pack',
        scheduledDate: now.add(const Duration(days: 10)),
        priority: 'Medium',
        estimatedCost: 80.0,
        intervalDays: 180,
      ),
      MaintenanceSchedule(
        id: 5,
        toolId: 5,
        toolName: 'Safety Harness',
        maintenanceType: 'Safety Check',
        description: 'Inspect for wear and damage',
        scheduledDate: now.add(const Duration(days: 15)),
        priority: 'Critical',
        assignedTo: 'Hassan Mohammed',
        estimatedCost: 0.0,
        intervalDays: 90,
      ),
    ];
  }

  List<MaintenanceSchedule> _filterMaintenanceItems(List<MaintenanceSchedule> items) {
    switch (_selectedFilter) {
      case 'Scheduled':
        return items.where((item) => item.status == 'Scheduled').toList();
      case 'Overdue':
        return items.where((item) => item.isOverdue).toList();
      case 'In Progress':
        return items.where((item) => item.status == 'In Progress').toList();
      case 'Completed':
        return items.where((item) => item.status == 'Completed').toList();
      default:
        return items;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddMaintenanceDialog(
        onMaintenanceAdded: (maintenance) {
          setState(() {
            _maintenanceItems.add(maintenance);
          });
        },
      ),
    );
  }

  void _startMaintenance(MaintenanceSchedule item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started maintenance for ${item.toolName}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _completeMaintenance(MaintenanceSchedule item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completed maintenance for ${item.toolName}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _viewMaintenanceDetails(MaintenanceSchedule item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance Details - ${item.toolName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${item.maintenanceType}'),
            Text('Priority: ${item.priority}'),
            Text('Scheduled: ${_formatDate(item.scheduledDate)}'),
            Text('Status: ${item.status}'),
            if (item.assignedTo != null) Text('Assigned to: ${item.assignedTo}'),
            if (item.estimatedCost != null) Text('Estimated Cost: \$${item.estimatedCost!.toStringAsFixed(2)}'),
            if (item.notes != null) Text('Notes: ${item.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AddMaintenanceDialog extends StatefulWidget {
  final Function(MaintenanceSchedule) onMaintenanceAdded;
  
  const _AddMaintenanceDialog({
    required this.onMaintenanceAdded,
  });

  @override
  _AddMaintenanceDialogState createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<_AddMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  
  String _selectedTool = '';
  String _selectedType = 'Calibration';
  String _selectedPriority = 'Medium';
  DateTime _selectedDate = DateTime.now().add(Duration(days: 7));
  String? _selectedTechnician;

  final List<String> _maintenanceTypes = [
    'Calibration',
    'Cleaning',
    'Inspection',
    'Repair',
    'Replacement',
    'Lubrication',
    'Testing',
    'Other'
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: AppTheme.primaryColor, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Schedule Maintenance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Tool Selection
                  Text(
                    'Select Tool',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Consumer<SupabaseToolProvider>(
                    builder: (context, toolProvider, child) {
                      final tools = toolProvider.tools;
                      return DropdownButtonFormField<String>(
                        value: _selectedTool.isEmpty ? null : _selectedTool,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: Text('Choose a tool'),
                        items: tools.map((tool) {
                          return DropdownMenuItem<String>(
                            value: tool.id,
                            child: Text(tool.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTool = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a tool';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Maintenance Type
                  Text(
                    'Maintenance Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _maintenanceTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? 'Calibration';
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Describe the maintenance task',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Priority and Date Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _priorities.map((priority) {
                                return DropdownMenuItem<String>(
                                  value: priority,
                                  child: Text(priority),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value ?? 'Medium';
                                });
                              },
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
                              'Scheduled Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 20),
                                    SizedBox(width: 8),
                                    Text(_formatDate(_selectedDate)),
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
                  
                  // Estimated Cost
                  Text(
                    'Estimated Cost (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _estimatedCostController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: '0.00',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  
                  // Notes
                  Text(
                    'Notes (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Additional notes or instructions',
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveMaintenance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text('Schedule Maintenance'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _saveMaintenance() {
    if (_formKey.currentState!.validate()) {
      // Get the selected tool name
      final toolProvider = context.read<SupabaseToolProvider>();
      final selectedTool = toolProvider.tools.firstWhere(
        (tool) => tool.id == _selectedTool,
      );
      
      final maintenance = MaintenanceSchedule(
        toolId: int.parse(_selectedTool),
        toolName: selectedTool.name,
        maintenanceType: _selectedType,
        description: _descriptionController.text.trim(),
        scheduledDate: _selectedDate,
        priority: _selectedPriority,
        estimatedCost: _estimatedCostController.text.isNotEmpty 
            ? double.tryParse(_estimatedCostController.text) 
            : null,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
      );
      
      // Add to maintenance list via callback
      widget.onMaintenanceAdded(maintenance);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maintenance scheduled for ${selectedTool.name}'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }
}
