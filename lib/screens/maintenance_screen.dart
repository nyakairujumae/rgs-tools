import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Schedule'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddMaintenanceDialog,
            icon: const Icon(Icons.add),
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
        icon: const Icon(Icons.schedule),
        label: const Text('Schedule'),
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
    return Consumer<ToolProvider>(
      builder: (context, toolProvider, child) {
        final maintenanceItems = _getMockMaintenanceData();
        final filteredItems = _filterMaintenanceItems(maintenanceItems);

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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                StatusChip(status: item.status),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Maintenance Type and Priority
            Row(
              children: [
                Icon(
                  Icons.build,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  item.maintenanceType,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
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
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Date and Status Info
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.scheduledDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${item.assignedTo}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            
            if (item.estimatedCost != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Est. Cost: \$${item.estimatedCost!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                if (item.status == 'Scheduled' || item.status == 'Overdue')
                  TextButton.icon(
                    onPressed: () => _startMaintenance(item),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                if (item.status == 'In Progress')
                  TextButton.icon(
                    onPressed: () => _completeMaintenance(item),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Complete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _viewMaintenanceDetails(item),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details'),
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
      builder: (context) => AlertDialog(
        title: const Text('Schedule Maintenance'),
        content: const Text('Maintenance scheduling feature will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
