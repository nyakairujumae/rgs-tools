import 'package:flutter/material.dart';
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
        backgroundColor: isDarkMode ? colorScheme.surface : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
              color: Colors.black87,
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
                            ThemedButton(
                              onPressed: _isLoading ? null : _submitReport,
                              isLoading: _isLoading,
                              backgroundColor: Colors.red.shade600,
                              child: const Text('Submit Report'),
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
      dropdownColor: Colors.white,
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
