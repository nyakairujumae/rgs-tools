import 'package:flutter/material.dart';
import '../models/approval_workflow.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_chip.dart';

class ApprovalWorkflowsScreen extends StatefulWidget {
  const ApprovalWorkflowsScreen({super.key});

  @override
  State<ApprovalWorkflowsScreen> createState() => _ApprovalWorkflowsScreenState();
}

class _ApprovalWorkflowsScreenState extends State<ApprovalWorkflowsScreen> {
  String _selectedFilter = 'All';
  String _selectedType = 'All';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Workflows'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateRequestDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Request',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          
          // Type Filter
          _buildTypeFilter(),
          
          // Workflows List
          Expanded(
            child: _buildWorkflowsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Request'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Pending', 'Approved', 'Rejected', 'Overdue'];
    
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

  Widget _buildTypeFilter() {
    final types = ['All', ...RequestTypes.allTypes];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = _selectedType == type;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type;
                });
              },
              selectedColor: AppTheme.secondaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.secondaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkflowsList() {
    final workflows = _getFilteredWorkflows();

    if (workflows.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workflows.length,
      itemBuilder: (context, index) {
        final workflow = workflows[index];
        return _buildWorkflowCard(workflow);
      },
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'Pending':
        title = 'No Pending Requests';
        subtitle = 'No pending approval requests found';
        icon = Icons.pending;
        break;
      case 'Approved':
        title = 'No Approved Requests';
        subtitle = 'No approved requests found';
        icon = Icons.check_circle;
        break;
      case 'Rejected':
        title = 'No Rejected Requests';
        subtitle = 'No rejected requests found';
        icon = Icons.cancel;
        break;
      case 'Overdue':
        title = 'No Overdue Requests';
        subtitle = 'No overdue requests found';
        icon = Icons.warning;
        break;
      default:
        title = 'No Requests Found';
        subtitle = 'No requests match the selected filters';
        icon = Icons.assignment;
    }

    return EmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actionText: 'Create Request',
      onAction: _showCreateRequestDialog,
    );
  }

  Widget _buildWorkflowCard(ApprovalWorkflow workflow) {
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTypeColor(workflow.requestType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getTypeIcon(workflow.requestType),
                    color: _getTypeColor(workflow.requestType),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        workflow.requestType,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(status: workflow.status),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(workflow.priority).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        workflow.priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(workflow.priority),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              workflow.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Details
            _buildDetailRow('Requester', workflow.requesterName),
            _buildDetailRow('Role', workflow.requesterRole),
            _buildDetailRow('Request Date', _formatDate(workflow.requestDate)),
            if (workflow.dueDate != null)
              _buildDetailRow('Due Date', _formatDate(workflow.dueDate!)),
            if (workflow.assignedTo != null)
              _buildDetailRow('Assigned To', workflow.assignedTo!),
            if (workflow.location != null)
              _buildDetailRow('Location', workflow.location!),
            
            // Status specific information
            if (workflow.isApproved && workflow.approvedBy != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Approved by ${workflow.approvedBy} on ${_formatDate(workflow.approvedDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (workflow.isRejected && workflow.rejectedBy != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          size: 16,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rejected by ${workflow.rejectedBy} on ${_formatDate(workflow.rejectedDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (workflow.rejectionReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${workflow.rejectionReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            if (workflow.isOverdue) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Overdue by ${workflow.daysUntilDue.abs()} days',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action Buttons
            if (workflow.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveWorkflow(workflow),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectWorkflow(workflow),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewWorkflowDetails(workflow),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  if (workflow.isRejected) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _resubmitWorkflow(workflow),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Resubmit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                          side: const BorderSide(color: AppTheme.secondaryColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ApprovalWorkflow> _getFilteredWorkflows() {
    var workflows = ApprovalWorkflowService.getMockWorkflows();
    
    // Filter by status
    switch (_selectedFilter) {
      case 'Pending':
        workflows = workflows.where((w) => w.isPending).toList();
        break;
      case 'Approved':
        workflows = workflows.where((w) => w.isApproved).toList();
        break;
      case 'Rejected':
        workflows = workflows.where((w) => w.isRejected).toList();
        break;
      case 'Overdue':
        workflows = workflows.where((w) => w.isOverdue).toList();
        break;
    }
    
    // Filter by type
    if (_selectedType != 'All') {
      workflows = workflows.where((w) => w.requestType == _selectedType).toList();
    }
    
    return workflows;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case RequestTypes.toolAssignment:
        return AppTheme.primaryColor;
      case RequestTypes.toolPurchase:
        return AppTheme.secondaryColor;
      case RequestTypes.toolDisposal:
        return AppTheme.errorColor;
      case RequestTypes.maintenance:
        return AppTheme.warningColor;
      case RequestTypes.transfer:
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case RequestTypes.toolAssignment:
        return Icons.person_add;
      case RequestTypes.toolPurchase:
        return Icons.shopping_cart;
      case RequestTypes.toolDisposal:
        return Icons.delete;
      case RequestTypes.maintenance:
        return Icons.build;
      case RequestTypes.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.assignment;
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
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Request'),
        content: const Text('Request creation feature will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _approveWorkflow(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text('Are you sure you want to approve "${workflow.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request "${workflow.title}" approved'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectWorkflow(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this request?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request "${workflow.title}" rejected'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _viewWorkflowDetails(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Details - ${workflow.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${workflow.requestType}'),
              Text('Status: ${workflow.status}'),
              Text('Priority: ${workflow.priority}'),
              Text('Requester: ${workflow.requesterName}'),
              Text('Request Date: ${_formatDate(workflow.requestDate)}'),
              if (workflow.dueDate != null) Text('Due Date: ${_formatDate(workflow.dueDate!)}'),
              if (workflow.assignedTo != null) Text('Assigned To: ${workflow.assignedTo}'),
              if (workflow.location != null) Text('Location: ${workflow.location}'),
              const SizedBox(height: 8),
              Text('Description: ${workflow.description}'),
            ],
          ),
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

  void _resubmitWorkflow(ApprovalWorkflow workflow) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resubmitting request "${workflow.title}"'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
