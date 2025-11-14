import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_issue_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/auth_provider.dart';
import '../models/tool_issue.dart';
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

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
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        scrolledUnderElevation: 6,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // If embedded as tab, navigate to dashboard instead of popping
              if (widget.onNavigateToDashboard != null) {
                widget.onNavigateToDashboard!();
              } else {
                // Fallback: try to pop if it's a pushed screen
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
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
                color: Colors.grey[600],
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
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
                                    child: Text(type),
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
                                    child: Text(priority),
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
                              _multiline(
                                _descriptionController,
                                label: 'Description *',
                                hint: 'Describe the issue in detail',
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
                              _textField(
                                _locationController,
                                label: 'Location',
                                hint: 'Where did this occur? (optional)',
                                icon: Icons.location_on,
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                              _textField(
                                _estimatedCostController,
                                label: 'Estimated Cost',
                                hint: 'Cost to fix/replace (optional)',
                                keyboardType: TextInputType.number,
                                icon: Icons.attach_money,
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
                              decoration: BoxDecoration(
                                color: isDarkMode ? colorScheme.surface : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                ),
                                border: Border.all(
                                  color: isDarkMode 
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
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
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _submitReport,
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                                  ),
                                  child: Container(
                                    padding: ResponsiveHelper.getResponsivePadding(
                                      context,
                                      vertical: 16,
                                    ),
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Submit Report',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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

  Widget _textField(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
        ),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
        ),
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  color: Colors.grey[600],
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
        ),
      ),
    );
  }

  Widget _multiline(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
        ),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          ),
          prefixIcon: Icon(
            Icons.description,
            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            color: Colors.grey[600],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
        ),
        minLines: 3,
        maxLines: 6,
        validator: validator,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
        ),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          ),
          hintText: value == null ? 'Select...' : null,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            overflow: TextOverflow.ellipsis,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  color: Colors.grey[600],
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 16),
            ),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
        ),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
        dropdownColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
        ),
        menuMaxHeight: 300,
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a tool'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected tool not found. Please refresh and try again.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Issue reported successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );

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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        all: 20,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              color: theme.colorScheme.onSurface,
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
