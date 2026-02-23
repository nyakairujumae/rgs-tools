import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../services/supabase_service.dart';
import '../services/image_upload_service.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';
import '../models/approval_workflow.dart';
import '../utils/responsive_helper.dart';
import '../utils/auth_error_handler.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';
import '../utils/logger.dart';

class RequestNewToolScreen extends StatefulWidget {
  const RequestNewToolScreen({super.key});

  @override
  State<RequestNewToolScreen> createState() => _RequestNewToolScreenState();
}

class _RequestNewToolScreenState extends State<RequestNewToolScreen> {
  final _formKey = GlobalKey<FormState>();

  // Request type
  String _selectedRequestType = RequestTypes.toolPurchase;

  // Common fields
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _siteCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  // Tool Purchase fields
  final TextEditingController _nameCtrl = TextEditingController();
  String _selectedCategory = '';
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController(text: '1');
  final TextEditingController _unitPriceCtrl = TextEditingController();
  final TextEditingController _totalCostCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();

  // Tool Assignment fields
  final TextEditingController _toolNameCtrl = TextEditingController();
  final TextEditingController _toolSerialCtrl = TextEditingController();
  final TextEditingController _technicianNameCtrl = TextEditingController();
  final TextEditingController _projectCtrl = TextEditingController();

  // Tool Transfer fields
  final TextEditingController _fromLocationCtrl = TextEditingController();
  final TextEditingController _toLocationCtrl = TextEditingController();

  // Tool Maintenance fields
  final TextEditingController _maintenanceTypeCtrl = TextEditingController();
  final TextEditingController _estimatedCostCtrl = TextEditingController();

  // Tool Disposal fields
  final TextEditingController _disposalReasonCtrl = TextEditingController();
  final TextEditingController _conditionCtrl = TextEditingController();

  DateTime? _neededBy;
  String _priority = 'Normal';
  bool _isSubmitting = false;
  
  // Image upload
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  // Categories (same as admin side)
  final List<String> _categories = [
    'Hand Tools',
    'Power Tools',
    'Testing Equipment',
    'Safety Equipment',
    'Measuring Tools',
    'Cutting Tools',
    'Fastening Tools',
    'Electrical Tools',
    'Plumbing Tools',
    'Carpentry Tools',
    'Automotive Tools',
    'Garden Tools',
    'Other',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Hand Tools': Icons.build_outlined,
    'Power Tools': Icons.power_outlined,
    'Testing Equipment': Icons.science_outlined,
    'Safety Equipment': Icons.shield_outlined,
    'Measuring Tools': Icons.straighten_outlined,
    'Cutting Tools': Icons.cut_outlined,
    'Fastening Tools': Icons.construction_outlined,
    'Electrical Tools': Icons.electrical_services_outlined,
    'Plumbing Tools': Icons.plumbing_outlined,
    'Carpentry Tools': Icons.hardware_outlined,
    'Automotive Tools': Icons.car_repair_outlined,
    'Garden Tools': Icons.yard_outlined,
    'Other': Icons.category_outlined,
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _siteCtrl.dispose();
    _reasonCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _quantityCtrl.dispose();
    _unitPriceCtrl.dispose();
    _totalCostCtrl.dispose();
    _supplierCtrl.dispose();
    _toolNameCtrl.dispose();
    _toolSerialCtrl.dispose();
    _technicianNameCtrl.dispose();
    _projectCtrl.dispose();
    _fromLocationCtrl.dispose();
    _toLocationCtrl.dispose();
    _maintenanceTypeCtrl.dispose();
    _estimatedCostCtrl.dispose();
    _disposalReasonCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 24,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/technician',
                (route) => false,
              );
            },
          ),
        ),
        title: Text(
          _getScreenTitle(),
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.getMaxWidth(context),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getScreenDescription(),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                      
                      // Request Type Selection
                      _SectionCard(
                        title: 'Request Type',
                        child: _buildRequestTypeDropdown(),
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      
                      // Dynamic Fields Based on Request Type
                      _buildDynamicFieldsSection(),
                      
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                      // Timing & Location
                      _SectionCard(
                        title: 'Timing & Location',
                        child: Column(
                          children: [
                            _dateField(
                              label: 'Needed by',
                              value: _neededBy,
                              onPick: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now.add(const Duration(days: 1)),
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (picked != null)
                                  setState(() => _neededBy = picked);
                              },
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            _textField(_siteCtrl,
                                label: 'Site / Location',
                                hint: 'Job site or office pickup'),
                          ],
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                      _SectionCard(
                        title: _getJustificationTitle(),
                        child: Column(
                          children: [
                            _multiline(_reasonCtrl,
                                label: _getJustificationLabel(),
                                hint: _getJustificationHint(),
                                validator: _req),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            _buildImageAttachmentSection(),
                          ],
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ThemedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          isLoading: _isSubmitting,
                          child: Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _textField(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return ThemedTextField(
      controller: ctrl,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      enabled: !readOnly,
    );
  }

  Widget _multiline(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return ThemedTextField(
      controller: ctrl,
      label: label,
      hint: hint,
      maxLines: 6,
      validator: validator,
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: context.chatGPTInputDecoration.copyWith(
        labelText: label,
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      icon: const Icon(Icons.keyboard_arrow_down),
      menuMaxHeight: 300,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCategoryDropdown() {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedCategory.isEmpty ? null : _selectedCategory,
      isExpanded: true,
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
      decoration: context.chatGPTInputDecoration.copyWith(
        labelText: 'Category',
        hintText: 'Select a category',
        prefixIcon: Icon(
          _categoryIcons[_selectedCategory.isEmpty ? 'Other' : _selectedCategory] ?? Icons.category_outlined,
          size: 22,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcons[category] ?? Icons.category_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return _categories
            .map(
              (category) => Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcons[category] ?? Icons.category_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();
      },
      onChanged: (value) {
        setState(() {
          _selectedCategory = value ?? '';
        });
      },
      validator: (value) {
        if (_selectedCategory.isEmpty) {
          return 'Required';
        }
        return null;
      },
      dropdownColor: Theme.of(context).colorScheme.surface,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(20),
      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }

  Widget _dateField(
      {required String label,
      required DateTime? value,
      required VoidCallback onPick}) {
    final text = value == null
        ? 'Select date'
        : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.cardBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: context.chatGPTInputDecoration.copyWith(
            labelText: label,
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: value == null
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                    : AppTheme.secondaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Text(
                text,
                style: TextStyle(
                  color: value == null
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final authProvider = context.read<AuthProvider>();
    final adminNotificationProvider = context.read<AdminNotificationProvider>();
    final user = authProvider.user;

    setState(() => _isSubmitting = true);

    try {
      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          final requestId = DateTime.now().millisecondsSinceEpoch.toString();
          for (var image in _selectedImages) {
            final imageUrl = await ImageUploadService.uploadImage(
              File(image.path),
              'request_$requestId',
            );
            if (imageUrl != null) {
              imageUrls.add(imageUrl);
            }
          }
          Logger.debug('✅ Uploaded ${imageUrls.length} image(s) for request');
        } catch (e) {
          Logger.debug('⚠️ Failed to upload some images: $e');
          // Continue with submission even if image upload fails
        }
      }

      // Create approval workflow in database
      try {
        Logger.debug('🔍 Creating approval workflow for ${_selectedRequestType} request');
        final approvalWorkflow = _buildApprovalWorkflow(authProvider, user, imageUrls);
        final workflowMap = approvalWorkflow.toMap(includeId: false);
        Logger.debug('🔍 Approval workflow data: $workflowMap');
        
        final response = await SupabaseService.client
            .from('approval_workflows')
            .insert(workflowMap)
            .select()
            .single();
        
        Logger.debug('✅ Created approval workflow for ${_selectedRequestType} request (ID: ${response['id']})');
      } catch (e) {
        Logger.debug('❌ Failed to create approval workflow: $e');
        Logger.debug('❌ Error type: ${e.runtimeType}');
        Logger.debug('❌ Stack trace: ${StackTrace.current}');
        // Continue anyway - notification is still important
      }

      // Create notification for admin - this is the main way admin sees tool requests
      // Store all request details in the notification data
      try {
        final notificationData = _buildNotificationData(user, authProvider);
        notificationData['image_urls'] = imageUrls;
        
        await adminNotificationProvider.createNotification(
          technicianName:
              authProvider.userFullName ?? (user?.email ?? 'Technician'),
          technicianEmail: user?.email ?? 'unknown@technician',
          type: NotificationType.toolRequest,
          title: '${_selectedRequestType}: ${_titleCtrl.text.trim()}',
          message: _buildNotificationMessage(authProvider),
          data: notificationData,
        );
        Logger.debug('✅ Created admin notification for tool request');
      } catch (e) {
        Logger.debug('❌ Failed to create admin notification: $e');
        // Re-throw so user sees the error
        rethrow;
      }

      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          '${_selectedRequestType} request submitted. Admin will review it soon.',
        );
      }
      _resetForm();
    } catch (e) {
      Logger.debug('Error submitting tool request: $e');
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to submit request: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getScreenTitle() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return 'Request New Tool';
      case RequestTypes.toolAssignment:
        return 'Request Tool Assignment';
      case RequestTypes.transfer:
        return 'Request Tool Transfer';
      case RequestTypes.maintenance:
        return 'Request Tool Maintenance';
      case RequestTypes.toolDisposal:
        return 'Request Tool Disposal';
      default:
        return 'Create Request';
    }
  }

  String _getScreenDescription() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return 'Fill in the details below to request a new tool';
      case RequestTypes.toolAssignment:
        return 'Request to assign a tool to yourself or another technician';
      case RequestTypes.transfer:
        return 'Request to transfer a tool between locations';
      case RequestTypes.maintenance:
        return 'Request maintenance or repair for a tool';
      case RequestTypes.toolDisposal:
        return 'Request to dispose of a tool that is no longer needed';
      default:
        return 'Fill in the details below to create your request';
    }
  }

  String _getJustificationTitle() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return 'Justification';
      case RequestTypes.toolAssignment:
        return 'Project Details';
      case RequestTypes.transfer:
        return 'Transfer Reason';
      case RequestTypes.maintenance:
        return 'Maintenance Details';
      case RequestTypes.toolDisposal:
        return 'Disposal Reason';
      default:
        return 'Additional Information';
    }
  }

  String _getJustificationLabel() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return 'Why is this needed?';
      case RequestTypes.toolAssignment:
        return 'Project or work description';
      case RequestTypes.transfer:
        return 'Reason for transfer';
      case RequestTypes.maintenance:
        return 'Maintenance requirements';
      case RequestTypes.toolDisposal:
        return 'Reason for disposal';
      default:
        return 'Additional details';
    }
  }

  String _getJustificationHint() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return 'Describe reason, job, safety/efficiency impact';
      case RequestTypes.toolAssignment:
        return 'Describe the project or work that requires this tool';
      case RequestTypes.transfer:
        return 'Explain why the tool needs to be transferred';
      case RequestTypes.maintenance:
        return 'Describe the maintenance or repair needed';
      case RequestTypes.toolDisposal:
        return 'Explain why this tool should be disposed of';
      default:
        return 'Provide additional information';
    }
  }

  Widget _buildRequestTypeDropdown() {
    final availableTypes = [
      RequestTypes.toolPurchase,
      RequestTypes.toolAssignment,
      RequestTypes.transfer,
      RequestTypes.maintenance,
      RequestTypes.toolDisposal,
    ];

    return DropdownButtonFormField<String>(
      value: _selectedRequestType,
      isExpanded: true,
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: context.chatGPTInputDecoration.copyWith(
        labelText: 'Request Type',
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      icon: const Icon(Icons.keyboard_arrow_down),
      menuMaxHeight: 300,
      items: availableTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRequestType = value;
          });
        }
      },
    );
  }

  Widget _buildDynamicFieldsSection() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return _buildToolPurchaseFields();
      case RequestTypes.toolAssignment:
        return _buildToolAssignmentFields();
      case RequestTypes.transfer:
        return _buildToolTransferFields();
      case RequestTypes.maintenance:
        return _buildToolMaintenanceFields();
      case RequestTypes.toolDisposal:
        return _buildToolDisposalFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildToolPurchaseFields() {
    return _SectionCard(
      title: 'Tool Details',
      child: Column(
        children: [
          _textField(_nameCtrl, label: 'Tool name', hint: 'e.g., Cordless Drill', validator: _req),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _textField(_brandCtrl, label: 'Brand', hint: 'e.g., Makita')),
            const SizedBox(width: 12),
            Expanded(child: _textField(_modelCtrl, label: 'Model', hint: 'e.g., XFD131')),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _textField(
                _quantityCtrl,
                label: 'Quantity',
                hint: '1',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdown(
                label: 'Priority',
                value: _priority,
                items: const ['Low', 'Normal', 'High', 'Urgent'],
                onChanged: (v) => setState(() => _priority = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _textField(
                _unitPriceCtrl,
                label: 'Unit Price (AED)',
                hint: '0.00',
                keyboardType: TextInputType.number,
                onChanged: (value) => _calculateTotalCost(value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                _totalCostCtrl,
                label: 'Total Cost (AED)',
                hint: '0.00',
                keyboardType: TextInputType.number,
                readOnly: false,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _textField(_supplierCtrl, label: 'Supplier (Optional)', hint: 'Preferred supplier name'),
        ],
      ),
    );
  }

  Widget _buildToolAssignmentFields() {
    return _SectionCard(
      title: 'Assignment Details',
      child: Column(
        children: [
          _textField(_toolNameCtrl, label: 'Tool Name', hint: 'e.g., Digital Multimeter', validator: _req),
          const SizedBox(height: 16),
          _textField(_toolSerialCtrl, label: 'Tool Serial Number (Optional)', hint: 'e.g., FL123456'),
          const SizedBox(height: 16),
          _textField(_technicianNameCtrl, label: 'Assign To (Your Name or Another Technician)', hint: 'e.g., Ahmed Hassan', validator: _req),
          const SizedBox(height: 16),
          _textField(_projectCtrl, label: 'Project/Site', hint: 'e.g., Site A HVAC Installation'),
          const SizedBox(height: 16),
          _dropdown(
            label: 'Priority',
            value: _priority,
            items: const ['Low', 'Normal', 'High', 'Urgent'],
            onChanged: (v) => setState(() => _priority = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTransferFields() {
    return _SectionCard(
      title: 'Transfer Details',
      child: Column(
        children: [
          _textField(_toolNameCtrl, label: 'Tool Name', hint: 'e.g., Cordless Drill', validator: _req),
          const SizedBox(height: 16),
          _textField(_toolSerialCtrl, label: 'Tool Serial Number (Optional)', hint: 'e.g., CD901234'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _textField(_fromLocationCtrl, label: 'From Location', hint: 'e.g., Main Office', validator: _req)),
            const SizedBox(width: 12),
            Expanded(child: _textField(_toLocationCtrl, label: 'To Location', hint: 'e.g., Site A', validator: _req)),
          ]),
          const SizedBox(height: 16),
          _dropdown(
            label: 'Priority',
            value: _priority,
            items: const ['Low', 'Normal', 'High', 'Urgent'],
            onChanged: (v) => setState(() => _priority = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildToolMaintenanceFields() {
    return _SectionCard(
      title: 'Maintenance Details',
      child: Column(
        children: [
          _textField(_toolNameCtrl, label: 'Tool Name', hint: 'e.g., Vacuum Pump', validator: _req),
          const SizedBox(height: 16),
          _textField(_toolSerialCtrl, label: 'Tool Serial Number (Optional)', hint: 'e.g., VP789012'),
          const SizedBox(height: 16),
          _textField(_maintenanceTypeCtrl, label: 'Maintenance Type', hint: 'e.g., Annual Service, Repair, Calibration', validator: _req),
          const SizedBox(height: 16),
          _textField(
            _estimatedCostCtrl,
            label: 'Estimated Cost (AED)',
            hint: '0.00',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _dropdown(
            label: 'Priority',
            value: _priority,
            items: const ['Low', 'Normal', 'High', 'Urgent'],
            onChanged: (v) => setState(() => _priority = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildToolDisposalFields() {
    return _SectionCard(
      title: 'Disposal Details',
      child: Column(
        children: [
          _textField(_toolNameCtrl, label: 'Tool Name', hint: 'e.g., Safety Harness', validator: _req),
          const SizedBox(height: 16),
          _textField(_toolSerialCtrl, label: 'Tool Serial Number (Optional)', hint: 'e.g., SH345678'),
          const SizedBox(height: 16),
          _textField(_conditionCtrl, label: 'Current Condition', hint: 'e.g., Poor, Damaged, Obsolete', validator: _req),
          const SizedBox(height: 16),
          _dropdown(
            label: 'Priority',
            value: _priority,
            items: const ['Low', 'Normal', 'High', 'Urgent'],
            onChanged: (v) => setState(() => _priority = v!),
          ),
        ],
      ),
    );
  }

  void _calculateTotalCost(String value) {
    final quantity = int.tryParse(_quantityCtrl.text) ?? 0;
    final unitPrice = double.tryParse(value) ?? 0.0;
    final total = quantity * unitPrice;
    setState(() {
      _totalCostCtrl.text = total.toStringAsFixed(2);
    });
  }

  ApprovalWorkflow _buildApprovalWorkflow(AuthProvider authProvider, user, List<String> imageUrls) {
    final title = _titleCtrl.text.trim().isEmpty 
        ? _getDefaultTitle() 
        : _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim().isEmpty
        ? _getDefaultDescription()
        : _descriptionCtrl.text.trim();

    final requestData = _buildRequestData();
    if (imageUrls.isNotEmpty) {
      requestData['image_urls'] = imageUrls;
    }

    return ApprovalWorkflow(
      requestType: _selectedRequestType,
      title: title,
      description: description,
      requesterId: user?.id ?? '',
      requesterName: authProvider.userFullName ?? (user?.email ?? 'Technician'),
      requesterRole: 'Technician',
      status: 'Pending',
      priority: _priority == 'Urgent' ? 'High' : (_priority == 'Normal' ? 'Medium' : (_priority == 'High' ? 'High' : 'Low')),
      requestDate: DateTime.now(),
      dueDate: _neededBy,
      location: _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
      requestData: requestData,
    );
  }

  String _getDefaultTitle() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return 'Tool Purchase Request: ${_nameCtrl.text.trim()}';
      case RequestTypes.toolAssignment:
        return 'Tool Assignment Request: ${_toolNameCtrl.text.trim()}';
      case RequestTypes.transfer:
        return 'Tool Transfer Request: ${_toolNameCtrl.text.trim()}';
      case RequestTypes.maintenance:
        return 'Tool Maintenance Request: ${_toolNameCtrl.text.trim()}';
      case RequestTypes.toolDisposal:
        return 'Tool Disposal Request: ${_toolNameCtrl.text.trim()}';
      default:
        return 'Request';
    }
  }

  String _getDefaultDescription() {
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return 'Request to purchase ${_quantityCtrl.text.trim()} x ${_nameCtrl.text.trim()}${_brandCtrl.text.trim().isNotEmpty ? ' (${_brandCtrl.text.trim()})' : ''}${_modelCtrl.text.trim().isNotEmpty ? ' - Model: ${_modelCtrl.text.trim()}' : ''}';
      case RequestTypes.toolAssignment:
        return 'Request to assign ${_toolNameCtrl.text.trim()}${_toolSerialCtrl.text.trim().isNotEmpty ? ' (Serial: ${_toolSerialCtrl.text.trim()})' : ''} to ${_technicianNameCtrl.text.trim()}${_projectCtrl.text.trim().isNotEmpty ? ' for ${_projectCtrl.text.trim()}' : ''}';
      case RequestTypes.transfer:
        return 'Request to transfer ${_toolNameCtrl.text.trim()}${_toolSerialCtrl.text.trim().isNotEmpty ? ' (Serial: ${_toolSerialCtrl.text.trim()})' : ''} from ${_fromLocationCtrl.text.trim()} to ${_toLocationCtrl.text.trim()}';
      case RequestTypes.maintenance:
        return 'Request for ${_maintenanceTypeCtrl.text.trim()} of ${_toolNameCtrl.text.trim()}${_toolSerialCtrl.text.trim().isNotEmpty ? ' (Serial: ${_toolSerialCtrl.text.trim()})' : ''}';
      case RequestTypes.toolDisposal:
        return 'Request to dispose of ${_toolNameCtrl.text.trim()}${_toolSerialCtrl.text.trim().isNotEmpty ? ' (Serial: ${_toolSerialCtrl.text.trim()})' : ''} - Condition: ${_conditionCtrl.text.trim()}';
      default:
        return _reasonCtrl.text.trim();
    }
  }

  Map<String, dynamic> _buildRequestData() {
    final data = <String, dynamic>{
      'reason': _reasonCtrl.text.trim(),
      'needed_by': _neededBy?.toIso8601String(),
      'site': _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
    };

    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        data.addAll({
          'tool_name': _nameCtrl.text.trim(),
          'category': _selectedCategory,
          'brand': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
          'model': _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
          'quantity': _quantityCtrl.text.trim(),
          'unit_price': _unitPriceCtrl.text.trim().isEmpty ? null : _unitPriceCtrl.text.trim(),
          'total_cost': _totalCostCtrl.text.trim().isEmpty ? null : _totalCostCtrl.text.trim(),
          'supplier': _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        });
        break;
      case RequestTypes.toolAssignment:
        data.addAll({
          'tool_name': _toolNameCtrl.text.trim(),
          'tool_serial': _toolSerialCtrl.text.trim().isEmpty ? null : _toolSerialCtrl.text.trim(),
          'technician_name': _technicianNameCtrl.text.trim(),
          'project': _projectCtrl.text.trim().isEmpty ? null : _projectCtrl.text.trim(),
        });
        break;
      case RequestTypes.transfer:
        data.addAll({
          'tool_name': _toolNameCtrl.text.trim(),
          'tool_serial': _toolSerialCtrl.text.trim().isEmpty ? null : _toolSerialCtrl.text.trim(),
          'from_location': _fromLocationCtrl.text.trim(),
          'to_location': _toLocationCtrl.text.trim(),
        });
        break;
      case RequestTypes.maintenance:
        data.addAll({
          'tool_name': _toolNameCtrl.text.trim(),
          'tool_serial': _toolSerialCtrl.text.trim().isEmpty ? null : _toolSerialCtrl.text.trim(),
          'maintenance_type': _maintenanceTypeCtrl.text.trim(),
          'estimated_cost': _estimatedCostCtrl.text.trim().isEmpty ? null : _estimatedCostCtrl.text.trim(),
        });
        break;
      case RequestTypes.toolDisposal:
        data.addAll({
          'tool_name': _toolNameCtrl.text.trim(),
          'tool_serial': _toolSerialCtrl.text.trim().isEmpty ? null : _toolSerialCtrl.text.trim(),
          'condition': _conditionCtrl.text.trim(),
          'disposal_reason': _reasonCtrl.text.trim(),
        });
        break;
    }

    return data;
  }

  String _buildNotificationMessage(AuthProvider authProvider) {
    final requesterName = authProvider.userFullName ?? 'A technician';
    switch (_selectedRequestType) {
      case RequestTypes.toolPurchase:
        return '$requesterName requested ${_quantityCtrl.text.trim()} x ${_nameCtrl.text.trim()}';
      case RequestTypes.toolAssignment:
        return '$requesterName requested to assign ${_toolNameCtrl.text.trim()} to ${_technicianNameCtrl.text.trim()}';
      case RequestTypes.transfer:
        return '$requesterName requested to transfer ${_toolNameCtrl.text.trim()} from ${_fromLocationCtrl.text.trim()} to ${_toLocationCtrl.text.trim()}';
      case RequestTypes.maintenance:
        return '$requesterName requested ${_maintenanceTypeCtrl.text.trim()} for ${_toolNameCtrl.text.trim()}';
      case RequestTypes.toolDisposal:
        return '$requesterName requested to dispose of ${_toolNameCtrl.text.trim()}';
      default:
        return '$requesterName created a request';
    }
  }

  Map<String, dynamic> _buildNotificationData(user, AuthProvider authProvider) {
    final baseData = {
      'request_type': _selectedRequestType,
      'priority': _priority,
      'needed_by': _neededBy?.toIso8601String(),
      'site': _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
      'reason': _reasonCtrl.text.trim(),
      'requested_by_id': user?.id,
      'requested_by_email': user?.email,
      'requested_by_name': authProvider.userFullName,
      'requested_at': DateTime.now().toIso8601String(),
    };

    baseData.addAll(_buildRequestData());
    return baseData;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descriptionCtrl.clear();
    _siteCtrl.clear();
    _reasonCtrl.clear();
    _nameCtrl.clear();
    _selectedCategory = '';
    _brandCtrl.clear();
    _modelCtrl.clear();
    _quantityCtrl.text = '1';
    _unitPriceCtrl.clear();
    _totalCostCtrl.clear();
    _supplierCtrl.clear();
    _toolNameCtrl.clear();
    _toolSerialCtrl.clear();
    _technicianNameCtrl.clear();
    _projectCtrl.clear();
    _fromLocationCtrl.clear();
    _toLocationCtrl.clear();
    _maintenanceTypeCtrl.clear();
    _estimatedCostCtrl.clear();
    _disposalReasonCtrl.clear();
    _conditionCtrl.clear();
    setState(() {
      _priority = 'Normal';
      _neededBy = null;
      _selectedRequestType = RequestTypes.toolPurchase;
      _selectedImages.clear();
    });
  }

  Widget _buildImageAttachmentSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            all: 16,
          ),
          decoration: context.cardDecoration.copyWith(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                Icons.attachment,
                color: AppTheme.secondaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: Text(
                  'Attach photo or spec (optional)',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
              TextButton(
                onPressed: _showImagePickerOptions,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'Add Image',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Wrap(
            spacing: ResponsiveHelper.getResponsiveSpacing(context, 8),
            runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 8),
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: context.cardBackground,
                            child: Icon(
                              Icons.broken_image,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showImagePickerOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: context.cardDecoration.copyWith(
          color: AppTheme.secondaryColor.withValues(alpha: 0.08),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.secondaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to pick image: $e',
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        all: 20,
      ),
      decoration: context.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          child,
        ],
      ),
    );
  }
}
