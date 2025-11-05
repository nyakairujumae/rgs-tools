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
    try {
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
    } catch (e) {
      debugPrint('Error loading sample data: $e');
      _maintenanceItems = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Schedule'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
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
        icon: Icon(Icons.add),
        label: Text('New Maintenance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Scheduled', 'Overdue', 'In Progress', 'Completed'];
    
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected 
                      ? Theme.of(context).textTheme.bodyLarge?.color 
                      : Colors.grey[600],
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Theme.of(context).cardTheme.color,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    final statusColor = _getStatusColor(item.status);
    final priorityColor = _getPriorityColor(item.priority);
    final isOverdue = item.isOverdue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Maintenance Type Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.build_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                // Title and Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.maintenanceType,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        item.toolName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          if (item.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          
          SizedBox(height: 16),
          
          // Info Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Priority
                _buildInfoBadge(
                  Icons.flag_outlined,
                  'Priority ${item.priority}',
                  priorityColor,
                ),
                // Due Date
                _buildInfoBadge(
                  Icons.calendar_today_outlined,
                  'Due Date ${_formatDate(item.scheduledDate)}',
                  isOverdue ? Colors.red : Colors.blue,
                ),
                // Assigned To
                if (item.assignedTo != null)
                  _buildInfoBadge(
                    Icons.person_outline,
                    'Assigned To ${item.assignedTo!}',
                    Theme.of(context).primaryColor,
                  ),
                // Estimated Cost
                if (item.estimatedCost != null)
                  _buildInfoBadge(
                    Icons.attach_money,
                    'Est. Cost \$${item.estimatedCost!.toStringAsFixed(0)}',
                    Colors.green,
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (item.status == 'Scheduled' || item.status == 'Overdue')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startMaintenance(item),
                      icon: Icon(Icons.play_arrow, size: 18),
                      label: Text('Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (item.status == 'Scheduled' || item.status == 'Overdue')
                  SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewMaintenanceDetails(item),
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (item.status == 'In Progress') ...[
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completeMaintenance(item),
                      icon: Icon(Icons.check_circle, size: 18),
                      label: Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddMaintenancePage(
          onMaintenanceAdded: (maintenance) {
            setState(() {
              _maintenanceItems.add(maintenance);
            });
          },
        ),
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

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return Colors.red;
      case 'in progress':
        return Colors.blue;
      case 'scheduled':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _AddMaintenancePage extends StatefulWidget {
  final Function(MaintenanceSchedule) onMaintenanceAdded;
  
  const _AddMaintenancePage({
    required this.onMaintenanceAdded,
  });

  @override
  _AddMaintenancePageState createState() => _AddMaintenancePageState();
}

class _AddMaintenancePageState extends State<_AddMaintenancePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  
  String _selectedTool = '';
  String _selectedType = 'Calibration';
  String _selectedPriority = 'Medium';
  DateTime _selectedDate = DateTime.now().add(Duration(days: 7));
  String? _selectedTechnician;
  String? _selectedImagePath;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Maintenance'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tool Selection
                _buildSectionLabel('Select Tool', Icons.build_outlined),
                SizedBox(height: 8),
                Consumer<SupabaseToolProvider>(
                  builder: (context, toolProvider, child) {
                    final tools = toolProvider.tools;
                    return DropdownButtonFormField<String>(
                      value: _selectedTool.isEmpty ? null : _selectedTool,
                      decoration: _buildInputDecoration(hint: 'Choose a tool'),
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
                SizedBox(height: 20),
                
                // Maintenance Type
                _buildSectionLabel('Maintenance Type', Icons.category_outlined),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: _buildInputDecoration(),
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
                SizedBox(height: 20),
                
                // Description
                _buildSectionLabel('Description', Icons.description_outlined),
                SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _buildInputDecoration(
                    hint: 'Describe the maintenance task',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                
                // Image Picker
                _buildSectionLabel('Maintenance Image (Optional)', Icons.image_outlined),
                SizedBox(height: 8),
                _buildImagePicker(),
                SizedBox(height: 20),
                
                // Priority and Date Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Priority', Icons.flag_outlined),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: _buildInputDecoration(),
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
                          _buildSectionLabel('Scheduled Date', Icons.calendar_today_outlined),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
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
                SizedBox(height: 20),
                
                // Estimated Cost
                _buildSectionLabel('Estimated Cost (Optional)', Icons.attach_money_outlined),
                SizedBox(height: 8),
                TextFormField(
                  controller: _estimatedCostController,
                  decoration: _buildInputDecoration(
                    hint: '0.00',
                    prefixIcon: Icon(
                      Icons.attach_money,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 20),
                
                // Notes
                _buildSectionLabel('Notes (Optional)', Icons.note_outlined),
                SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: _buildInputDecoration(
                    hint: 'Additional notes or instructions',
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveMaintenance,
                    icon: Icon(Icons.schedule, size: 20),
                    label: Text(
                      'Schedule Maintenance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
  
  InputDecoration _buildInputDecoration({
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Theme.of(context).cardTheme.color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }
  
  Widget _buildImagePicker() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: _selectedImagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _selectedImagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  ),
                )
              : _buildImagePlaceholder(),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.camera_alt, size: 18),
                label: Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: Icon(Icons.photo_library, size: 18),
                label: Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
    if (_formKey.currentState?.validate() ?? false) {
      try {
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maintenance scheduled for ${selectedTool.name}'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error scheduling maintenance: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    // TODO: Implement camera image picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Camera functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    // TODO: Implement gallery image picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gallery functionality will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
