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
        title: Text('Approval Workflows'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateRequestDialog,
            icon: Icon(Icons.add),
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
        icon: Icon(Icons.add),
        label: Text('Create Request'),
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
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        workflow.requestType,
                        style: TextStyle(
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
                    SizedBox(height: 4),
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
            
            SizedBox(height: 12),
            
            // Description
            Text(
              workflow.description,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            
            SizedBox(height: 12),
            
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
              SizedBox(height: 8),
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
                    SizedBox(width: 8),
                    Text(
                      'Approved by ${workflow.approvedBy} on ${_formatDate(workflow.approvedDate!)}',
                      style: TextStyle(
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
              SizedBox(height: 8),
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
                        SizedBox(width: 8),
                        Text(
                          'Rejected by ${workflow.rejectedBy} on ${_formatDate(workflow.rejectedDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (workflow.rejectionReason != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Reason: ${workflow.rejectionReason}',
                        style: TextStyle(
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
              SizedBox(height: 8),
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
                    SizedBox(width: 8),
                    Text(
                      'Overdue by ${workflow.daysUntilDue.abs()} days',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 12),
            
            // Action Buttons
            if (workflow.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveWorkflow(workflow),
                      icon: Icon(Icons.check, size: 16),
                      label: Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectWorkflow(workflow),
                      icon: Icon(Icons.close, size: 16),
                      label: Text('Reject'),
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
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  if (workflow.isRejected) ...[
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _resubmitWorkflow(workflow),
                        icon: Icon(Icons.refresh, size: 16),
                        label: Text('Resubmit'),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
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
      builder: (context) => _CreateRequestDialog(
        onRequestCreated: (workflow) {
          // Add the new workflow to the list
          setState(() {
            // In a real app, this would be saved to the database
            // For now, we'll just refresh the UI
          });
        },
      ),
    );
  }

  void _approveWorkflow(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Request'),
        content: Text('Are you sure you want to approve "${workflow.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
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
            child: Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectWorkflow(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject this request?'),
            SizedBox(height: 16),
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
            child: Text('Cancel'),
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
            child: Text('Reject'),
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
              SizedBox(height: 8),
              Text('Description: ${workflow.description}'),
            ],
          ),
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

  void _resubmitWorkflow(ApprovalWorkflow workflow) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resubmitting request "${workflow.title}"'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class _CreateRequestDialog extends StatefulWidget {
  final Function(ApprovalWorkflow) onRequestCreated;

  const _CreateRequestDialog({
    required this.onRequestCreated,
  });

  @override
  State<_CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<_CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentsController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _supplierController = TextEditingController();
  final _technicianController = TextEditingController();
  final _toolController = TextEditingController();
  final _reasonController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();

  String _selectedRequestType = RequestTypes.toolAssignment;
  String _selectedPriority = 'Medium';
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  String _selectedAssignedTo = 'Manager';
  String _selectedAssignedToRole = 'Manager';

  final List<String> _requestTypes = RequestTypes.allTypes;
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _assignedToOptions = ['Manager', 'Supervisor', 'Admin', 'Maintenance Team'];
  final List<String> _assignedToRoles = ['Manager', 'Supervisor', 'Admin', 'Maintenance Supervisor'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentsController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _totalCostController.dispose();
    _supplierController.dispose();
    _technicianController.dispose();
    _toolController.dispose();
    _reasonController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Create New Request',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Request Type Selection
                      _buildRequestTypeSection(),
                      const SizedBox(height: 24),

                      // Basic Information
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),

                      // Dynamic Fields Based on Request Type
                      _buildDynamicFields(),
                      const SizedBox(height: 24),

                      // Priority and Due Date
                      _buildPriorityAndDueDateSection(),
                      const SizedBox(height: 24),

                      // Assignment Information
                      _buildAssignmentSection(),
                      const SizedBox(height: 24),

                      // Comments
                      _buildCommentsSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Create Request'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedRequestType,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _requestTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRequestType = value ?? RequestTypes.toolAssignment;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          RequestTypes.typeDescriptions[_selectedRequestType] ?? '',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Request Title',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a request title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicFields() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return _buildToolPurchaseFields();
      case RequestTypes.toolAssignment:
        return _buildToolAssignmentFields();
      case RequestTypes.toolDisposal:
        return _buildToolDisposalFields();
      case RequestTypes.transfer:
        return _buildTransferFields();
      case RequestTypes.maintenance:
        return _buildMaintenanceFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildToolPurchaseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _unitPriceController,
                decoration: InputDecoration(
                  labelText: 'Unit Price (\$)',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                onChanged: _calculateTotalCost,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit price';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _totalCostController,
          decoration: InputDecoration(
            labelText: 'Total Cost (\$)',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: TextInputType.number,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _supplierController,
          decoration: InputDecoration(
            labelText: 'Supplier',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildToolAssignmentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: InputDecoration(
            labelText: 'Tool Name/Serial',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _technicianController,
          decoration: InputDecoration(
            labelText: 'Technician Name',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter technician name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildToolDisposalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disposal Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: InputDecoration(
            labelText: 'Tool Name/Serial',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: 'Disposal Reason',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter disposal reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTransferFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transfer Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: InputDecoration(
            labelText: 'Tool Name/Serial',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fromLocationController,
                decoration: InputDecoration(
                  labelText: 'From Location',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter from location';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _toLocationController,
                decoration: InputDecoration(
                  labelText: 'To Location',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter to location';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaintenanceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maintenance Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _toolController,
          decoration: InputDecoration(
            labelText: 'Tool Name/Serial',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter tool name or serial';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: 'Maintenance Type/Reason',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter maintenance type or reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriorityAndDueDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority & Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(priority),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? 'Medium';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(_formatDate(_selectedDueDate)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedAssignedTo,
                decoration: InputDecoration(
                  labelText: 'Assigned To',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _assignedToOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssignedTo = value ?? 'Manager';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedAssignedToRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _assignedToRoles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssignedToRole = value ?? 'Manager';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _commentsController,
          decoration: InputDecoration(
            labelText: 'Comments (Optional)',
            border: OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  void _calculateTotalCost(String value) {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(value) ?? 0.0;
    final total = quantity * unitPrice;
    _totalCostController.text = total.toStringAsFixed(2);
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _submitRequest() {
    if (_formKey.currentState?.validate() ?? false) {
      // Create the approval workflow
      final workflow = ApprovalWorkflow(
        requestType: _selectedRequestType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requesterId: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
        requesterName: 'Current User', // In a real app, get from auth
        requesterRole: 'User', // In a real app, get from auth
        status: 'Pending',
        priority: _selectedPriority,
        requestDate: DateTime.now(),
        dueDate: _selectedDueDate,
        assignedTo: _selectedAssignedTo,
        assignedToRole: _selectedAssignedToRole,
        comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        requestData: _buildRequestData(),
      );

      widget.onRequestCreated(workflow);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request created successfully!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Map<String, dynamic> _buildRequestData() {
    final data = <String, dynamic>{};
    
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        data['quantity'] = _quantityController.text;
        data['unit_price'] = _unitPriceController.text;
        data['total_cost'] = _totalCostController.text;
        data['supplier'] = _supplierController.text;
        break;
      case RequestTypes.toolAssignment:
        data['tool_name'] = _toolController.text;
        data['technician_name'] = _technicianController.text;
        break;
      case RequestTypes.toolDisposal:
        data['tool_name'] = _toolController.text;
        data['disposal_reason'] = _reasonController.text;
        break;
      case RequestTypes.transfer:
        data['tool_name'] = _toolController.text;
        data['from_location'] = _fromLocationController.text;
        data['to_location'] = _toLocationController.text;
        break;
      case RequestTypes.maintenance:
        data['tool_name'] = _toolController.text;
        data['maintenance_type'] = _reasonController.text;
        break;
    }
    
    return data;
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
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
