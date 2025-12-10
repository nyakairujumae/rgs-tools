
import 'package:flutter/material.dart';
import '../models/approval_workflow.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../utils/responsive_helper.dart';
import '../utils/navigation_helper.dart';

class ApprovalWorkflowsScreen extends StatefulWidget {
  const ApprovalWorkflowsScreen({super.key});

  @override
  State<ApprovalWorkflowsScreen> createState() => _ApprovalWorkflowsScreenState();
}

class _ApprovalWorkflowsScreenState extends State<ApprovalWorkflowsScreen> {
  String _selectedFilter = 'All';
  String _selectedType = 'All';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Overdue'
  ];
  final List<String> _types = [
    'All',
    RequestTypes.toolAssignment,
    RequestTypes.toolPurchase,
    RequestTypes.toolDisposal,
    RequestTypes.maintenance,
    RequestTypes.transfer,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPremiumAppBar(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
      child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildFilterPills(),
            const SizedBox(height: 8),
            _buildTypePills(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildWorkflowsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showCreateRequestDialog,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Create Request',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowsList() {
    final workflows = _getFilteredWorkflows();

    if (workflows.isEmpty) {
      return _buildEmptyState();
    }

    final isDesktop = ResponsiveHelper.isDesktop(context);
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 200));
      },
      color: AppTheme.secondaryColor,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 16,
          isDesktop ? 16 : 12,
          isDesktop ? 24 : 16,
          120,
        ),
        itemCount: workflows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final workflow = workflows[index];
          return _buildWorkflowCard(workflow);
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.cardSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: 'Search requests, tools, or reporters...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
              },
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypePills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _types.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFEBF6F1) : const Color(0xFFF6F6F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.secondaryColor : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);
    final initial =
        workflow.title.isNotEmpty ? workflow.title[0].toUpperCase() : '?';
    final details = [
      workflow.requestType,
      workflow.requesterRole,
    ].join(' • ');

    return InkWell(
      borderRadius: radius,
      onTap: () => _showCreateRequestDialog(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getTypeColor(workflow.requestType)
                      .withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: _getTypeColor(workflow.requestType),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildIssueTypePill(workflow.requestType),
                _buildPriorityPill(workflow.priority),
                _buildStatusOutlineChip(workflow.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workflow.description,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Requested by ${workflow.requesterName} • ${_formatDate(workflow.requestDate)}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTypePill(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getTypeColor(type),
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String priority) {
    final color = _getPriorityAccentColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusOutlineChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPriorityAccentColor(String priority) {
    switch (priority) {
      case 'Critical':
      case 'High':
        return const Color(0xFFFF4D4F);
      case 'Medium':
        return const Color(0xFFFAAD14);
      case 'Low':
        return const Color(0xFF52C41A);
      default:
        return const Color(0xFF8C8C8C);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFFF4D4F);
      case 'Approved':
        return const Color(0xFF52C41A);
      case 'Rejected':
        return const Color(0xFFFAAD14);
      case 'Cancelled':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
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

    final searchTerm = _searchQuery.trim().toLowerCase();
    if (searchTerm.isNotEmpty) {
      workflows = workflows.where((issue) {
        final haystack = [
          issue.title,
          issue.description,
          issue.requesterName,
          issue.requestType,
        ].join(' ').toLowerCase();
        return haystack.contains(searchTerm);
      }).toList();
    }

    return workflows;
  }

  PreferredSizeWidget _buildPremiumAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: true,
      titleSpacing: 0,
      title: const Text(
        'Approval Workflows',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
        onPressed: () => NavigationHelper.safePop(context),
      ),
      actions: [],
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CreateRequestDialog(
          onRequestCreated: (workflow) {
            // Add the new workflow to the list
            setState(() {
              // In a real app, this would be saved to the database
              // For now, we'll just refresh the UI
            });
          },
        ),
      ),
    );
  }

  void _approveWorkflow(ApprovalWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Approve Request',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to approve "${workflow.title}"?',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request "${workflow.title}" approved'),
                  backgroundColor: AppTheme.secondaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Reject Request',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject this request?',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.cardSurfaceColor(context),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            child: Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request "${workflow.title}" rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Request Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workflow.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Type', workflow.requestType),
              _buildDetailRow('Status', workflow.status),
              _buildDetailRow('Priority', workflow.priority),
              _buildDetailRow('Requester', workflow.requesterName),
              _buildDetailRow('Request Date', _formatDate(workflow.requestDate)),
              if (workflow.dueDate != null) _buildDetailRow('Due Date', _formatDate(workflow.dueDate!)),
              if (workflow.assignedTo != null) _buildDetailRow('Assigned To', workflow.assignedTo!),
              if (workflow.location != null) _buildDetailRow('Location', workflow.location!),
              const SizedBox(height: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workflow.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
            ),
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
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: (isDesktop ? 24 : 20) + bottomInset,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                    minHeight: constraints.maxHeight - ((isDesktop ? 20 : 16) * 2),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                          vertical: isDesktop ? 20 : 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: ResponsiveHelper.getResponsiveIconSize(context, 44),
                              height: ResponsiveHelper.getResponsiveIconSize(context, 44),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? theme.colorScheme.surface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 14),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create New Request',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                                      fontWeight: FontWeight.w700,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Request approvals for tools, purchases, maintenance, and more.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                        ),
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

                              const SizedBox(height: 24),

                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _submitRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('Create Request'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.cardSurfaceColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.secondaryColor,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedRequestType,
          decoration: _buildInputDecoration('Request Type'),
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
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: _buildInputDecoration('Request Title'),
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
          decoration: _buildInputDecoration('Description'),
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
          decoration: _buildInputDecoration('Location'),
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
                  labelText: 'Unit Price (AED)',
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
            labelText: 'Total Cost (AED)',
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
                      Expanded(
                        child: Text(
                          _formatDate(_selectedDueDate),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
