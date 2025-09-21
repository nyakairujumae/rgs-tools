import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../theme/app_theme.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_chip.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compliance & Certifications'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddCertificationDialog,
            icon: Icon(Icons.add),
            tooltip: 'Add Certification',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          
          // Compliance Overview
          _buildComplianceOverview(),
          
          // Certifications List
          Expanded(
            child: _buildCertificationsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCertificationDialog,
        icon: Icon(Icons.add),
        label: Text('Add Certification'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Valid', 'Expiring Soon', 'Expired', 'By Type'];
    
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

  Widget _buildComplianceOverview() {
    final certifications = CertificationService.getMockCertifications();
    final validCount = certifications.where((c) => c.isValid).length;
    final expiringCount = certifications.where((c) => c.isExpiringSoon).length;
    final expiredCount = certifications.where((c) => c.isExpired).length;
    final totalCount = certifications.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard('Total', totalCount.toString(), Icons.assignment, AppTheme.primaryColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard('Valid', validCount.toString(), Icons.check_circle, AppTheme.successColor),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard('Expiring Soon', expiringCount.toString(), Icons.warning, AppTheme.warningColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard('Expired', expiredCount.toString(), Icons.error, AppTheme.errorColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsList() {
    final certifications = _getFilteredCertifications();

    if (certifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certifications.length,
      itemBuilder: (context, index) {
        final certification = certifications[index];
        return _buildCertificationCard(certification);
      },
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'Valid':
        title = 'No Valid Certifications';
        subtitle = 'No valid certifications found';
        icon = Icons.check_circle;
        break;
      case 'Expiring Soon':
        title = 'No Expiring Certifications';
        subtitle = 'No certifications expiring soon';
        icon = Icons.warning;
        break;
      case 'Expired':
        title = 'No Expired Certifications';
        subtitle = 'No expired certifications found';
        icon = Icons.error;
        break;
      default:
        title = 'No Certifications Found';
        subtitle = 'No certifications match the selected filter';
        icon = Icons.assignment;
    }

    return EmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actionText: 'Add Certification',
      onAction: _showAddCertificationDialog,
    );
  }

  Widget _buildCertificationCard(Certification certification) {
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
                    color: _getStatusColor(certification.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getStatusIcon(certification.status),
                    color: _getStatusColor(certification.status),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certification.toolName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        certification.certificationType,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: certification.status),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Certification Details
            _buildDetailRow('Certification #', certification.certificationNumber),
            _buildDetailRow('Issuing Authority', certification.issuingAuthority),
            _buildDetailRow('Issue Date', _formatDate(certification.issueDate)),
            _buildDetailRow('Expiry Date', _formatDate(certification.expiryDate)),
            _buildDetailRow('Status', certification.expiryStatus),
            
            if (certification.inspectorName != null)
              _buildDetailRow('Inspector', certification.inspectorName!),
            
            if (certification.location != null)
              _buildDetailRow('Location', certification.location!),
            
            if (certification.notes != null) ...[
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certification.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                if (certification.documentPath != null)
                  TextButton.icon(
                    onPressed: () => _viewDocument(certification),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('View Document'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editCertification(certification),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _renewCertification(certification),
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Renew'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                  ),
                ),
              ],
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
            width: 120,
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

  List<Certification> _getFilteredCertifications() {
    final certifications = CertificationService.getMockCertifications();
    
    switch (_selectedFilter) {
      case 'Valid':
        return certifications.where((c) => c.isValid).toList();
      case 'Expiring Soon':
        return certifications.where((c) => c.isExpiringSoon).toList();
      case 'Expired':
        return certifications.where((c) => c.isExpired).toList();
      case 'By Type':
        return certifications..sort((a, b) => a.certificationType.compareTo(b.certificationType));
      default:
        return certifications;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Valid':
        return AppTheme.successColor;
      case 'Expiring Soon':
        return AppTheme.warningColor;
      case 'Expired':
        return AppTheme.errorColor;
      case 'Revoked':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Valid':
        return Icons.check_circle;
      case 'Expiring Soon':
        return Icons.warning;
      case 'Expired':
        return Icons.error;
      case 'Revoked':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddCertificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Certification'),
        content: Text('Certification management feature will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewDocument(Certification certification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing document for ${certification.certificationNumber}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _editCertification(Certification certification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing certification ${certification.certificationNumber}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _renewCertification(Certification certification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renew Certification'),
        content: Text('Are you sure you want to renew the certification for ${certification.toolName}?'),
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
                  content: Text('Certification renewal initiated for ${certification.toolName}'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Renew'),
          ),
        ],
      ),
    );
  }
}
