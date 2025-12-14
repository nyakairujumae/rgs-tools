import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/tool_issue_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/auth_provider.dart';
import '../models/tool_issue.dart';
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';
import '../services/image_upload_service.dart';

class AddToolIssueScreen extends StatefulWidget {
  final Function()? onNavigateToDashboard;
  
  const AddToolIssueScreen({super.key, this.onNavigateToDashboard});

  @override
  State<AddToolIssueScreen> createState() => _AddToolIssueScreenState();
}

class _AddToolIssueScreenState extends State<AddToolIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _estimatedCostController = TextEditingController();

  String _selectedToolId = '';
  String _selectedIssueType = 'Faulty';
  String _selectedPriority = 'Medium';
  bool _isLoading = false;
  
  // Image upload
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  final List<String> _issueTypes = [
    'Faulty',
    'Lost',
    'Damaged',
    'Missing Parts',
    'Other',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _estimatedCostController.dispose();
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
        backgroundColor: context.appBarBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 28,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              // If embedded as tab, navigate to dashboard instead of popping
              if (widget.onNavigateToDashboard != null) {
                widget.onNavigateToDashboard!();
              } else {
                NavigationHelper.safePop(context);
              }
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Report Tool Issue',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              'Help us track and resolve tool problems quickly',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
              : SingleChildScrollView(
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

                        // Tool Information Section
                        _SectionCard(
                          title: 'Tool Information',
                          child: Consumer<SupabaseToolProvider>(
                            builder: (context, toolProvider, child) {
                              final tools = toolProvider.tools;
                              return _dropdown(
                                label: 'Select Tool *',
                                value: _selectedToolId.isEmpty ? null : _selectedToolId,
                                items: tools.map((tool) {
                                  return DropdownMenuItem(
                                    value: tool.id,
                                    child: Text(
                                      '${tool.name} (${tool.category})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedToolId = value ?? '';
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a tool';
                                  }
                                  return null;
                                },
                                icon: Icons.build,
                              );
                            },
                          ),
                        ),

                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                            // Issue Details Section
                        _SectionCard(
                          title: 'Issue Details',
                          child: Column(
                            children: [
                              _dropdown(
                                label: 'Issue Type',
                                value: _selectedIssueType,
                                items: _issueTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedIssueType = value!;
                                  });
                                },
                                icon: Icons.category,
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                              _dropdown(
                                label: 'Priority',
                                value: _selectedPriority,
                                items: _priorities.map((priority) {
                                  return DropdownMenuItem(
                                    value: priority,
                                    child: Text(
                                      priority,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriority = value!;
                                  });
                                },
                                icon: Icons.priority_high,
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                              ThemedTextField(
                                controller: _descriptionController,
                                label: 'Description *',
                                hint: 'Describe the issue in detail',
                                maxLines: 6,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please provide a description of the issue';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                            // Additional Information Section
                        _SectionCard(
                          title: 'Additional Information',
                          child: Column(
                            children: [
                              ThemedTextField(
                                controller: _locationController,
                                label: 'Location',
                                hint: 'Where did this occur? (optional)',
                                prefixIcon: Icons.location_on,
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                              ThemedTextField(
                                controller: _estimatedCostController,
                                label: 'Estimated Cost',
                                hint: 'Cost to fix/replace (optional)',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.attach_money,
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                              _buildImageAttachmentSection(),
                            ],
                          ),
                        ),

                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                            // Priority Guidelines
                            Container(
                              width: double.infinity,
                              padding: ResponsiveHelper.getResponsivePadding(
                                context,
                                all: 20,
                              ),
                              decoration: context.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: AppTheme.primaryColor,
                                        size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                      ),
                                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                                      Expanded(
                                        child: Text(
                                          'Priority Guidelines',
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                                  _buildPriorityGuideline(context, 'Critical', 'Safety hazard or complete tool failure'),
                                  _buildPriorityGuideline(context, 'High', 'Tool unusable but no safety risk'),
                                  _buildPriorityGuideline(context, 'Medium', 'Tool partially functional'),
                                  _buildPriorityGuideline(context, 'Low', 'Minor issue, tool still usable'),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ThemedButton(
                                onPressed: _isLoading ? null : _submitReport,
                                isLoading: _isLoading,
                                backgroundColor: Colors.red.shade600,
                                child: const Text('Submit Report'),
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

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    IconData? icon,
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
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      dropdownColor: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      icon: const Icon(Icons.keyboard_arrow_down),
      menuMaxHeight: 300,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildPriorityGuideline(BuildContext context, String priority, String description) {
    final theme = Theme.of(context);
    Color color;
    switch (priority) {
      case 'Critical':
        color = Colors.red;
        break;
      case 'High':
        color = Colors.orange;
        break;
      case 'Medium':
        color = Colors.yellow[700]!;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: Text(
              '$priority: $description',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final toolProvider = context.read<SupabaseToolProvider>();
      
      // Validate tool selection
      if (_selectedToolId.isEmpty) {
        AuthErrorHandler.showErrorSnackBar(context, 'Please select a tool');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Find the selected tool
      Tool? selectedTool;
      try {
        selectedTool = toolProvider.tools.firstWhere(
          (tool) => tool.id == _selectedToolId,
        );
      } catch (e) {
        debugPrint('❌ Tool not found: $_selectedToolId');
        AuthErrorHandler.showErrorSnackBar(context, 'Selected tool not found. Please refresh and try again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get technician info for proper reporting
      final technicianName = authProvider.userFullName ?? 'Unknown Technician';
      final technicianId = authProvider.userId;
      final reportedByInfo = technicianId != null 
          ? '$technicianName (ID: $technicianId)'
          : technicianName;

      debugPrint('📝 Creating tool issue:');
      debugPrint('   Tool ID: $_selectedToolId');
      debugPrint('   Tool Name: ${selectedTool.name}');
      debugPrint('   Reported By: $reportedByInfo');
      debugPrint('   Issue Type: $_selectedIssueType');
      debugPrint('   Priority: $_selectedPriority');
      debugPrint('   Description: ${_descriptionController.text.trim()}');

      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          final issueId = DateTime.now().millisecondsSinceEpoch.toString();
          for (var image in _selectedImages) {
            final imageUrl = await ImageUploadService.uploadImage(
              File(image.path),
              'issue_$issueId',
            );
            if (imageUrl != null) {
              imageUrls.add(imageUrl);
            }
          }
          debugPrint('✅ Uploaded ${imageUrls.length} image(s) for issue');
        } catch (e) {
          debugPrint('⚠️ Failed to upload some images: $e');
          // Continue with submission even if image upload fails
        }
      }

      final issue = ToolIssue(
        toolId: _selectedToolId,
        toolName: selectedTool.name,
        reportedBy: reportedByInfo,
        reportedByUserId: technicianId,
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: 'Open',
        reportedAt: DateTime.now(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        estimatedCost: _estimatedCostController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_estimatedCostController.text.trim()),
        attachments: imageUrls.isNotEmpty ? imageUrls : null,
      );

      debugPrint('📤 Submitting issue to Supabase...');
      await context.read<ToolIssueProvider>().addIssue(issue);
      debugPrint('✅ Issue submitted successfully!');

      if (mounted) {
        // Clear the form
        setState(() {
          _selectedToolId = '';
          _selectedIssueType = 'Faulty';
          _selectedPriority = 'Medium';
          _descriptionController.clear();
          _locationController.clear();
          _estimatedCostController.clear();
          _selectedImages.clear();
        });

        // Show success message
        AuthErrorHandler.showSuccessSnackBar(context, 'Issue reported successfully!');

        // Note: We don't call Navigator.pop() because this screen is embedded
        // as a tab in TechnicianHomeScreen. The form is cleared and the user
        // can navigate using the bottom navigation bar.
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error submitting tool issue: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        String errorMessage = 'Oops! Something went wrong. Please try again.';
        
        // Provide more specific error messages
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('relation "tool_issues" does not exist') ||
            errorString.contains('table') && errorString.contains('not found')) {
          errorMessage = 'Tool issues table not found. Please contact administrator.';
        } else if (errorString.contains('jwt') || errorString.contains('session') || errorString.contains('expired')) {
          errorMessage = 'Session expired. Please log in again.';
        } else if (errorString.contains('permission') || errorString.contains('denied') || errorString.contains('policy')) {
          errorMessage = 'Permission denied. You may not have permission to report issues.';
        } else if (errorString.contains('null') || errorString.contains('required')) {
          errorMessage = 'Please fill in all required fields.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }
        
        AuthErrorHandler.showErrorSnackBar(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                  'Attach photo (optional)',
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
      decoration: context.cardDecoration,
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
