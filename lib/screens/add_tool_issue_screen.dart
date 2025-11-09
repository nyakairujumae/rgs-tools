import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_issue_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/auth_provider.dart';
import '../models/tool_issue.dart';
import '../models/tool.dart';
import '../theme/app_theme.dart';

class AddToolIssueScreen extends StatefulWidget {
  const AddToolIssueScreen({super.key});

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.black87),
                              onPressed: () {
                                // Since this screen is embedded as a tab, we can't pop
                                // Instead, navigate to dashboard tab (index 0) if possible
                                try {
                                  // Try to find the parent TechnicianHomeScreen and switch to dashboard
                                  final navigator = Navigator.of(context, rootNavigator: false);
                                  if (navigator.canPop()) {
                                    navigator.pop();
                                  } else {
                                    // If we can't pop, just do nothing (user can use bottom nav)
                                    debugPrint('Cannot pop - screen is embedded as tab');
                                  }
                                } catch (e) {
                                  debugPrint('Navigation error: $e');
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Report Tool Issue',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help us track and resolve tool problems quickly',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 32),

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

                        const SizedBox(height: 24),

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
                              const SizedBox(height: 16),
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
                              const SizedBox(height: 16),
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

                        const SizedBox(height: 24),

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
                              const SizedBox(height: 16),
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

                        const SizedBox(height: 24),

                        // Priority Guidelines
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradientFor(context),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Priority Guidelines',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPriorityGuideline('Critical', 'Safety hazard or complete tool failure'),
                              _buildPriorityGuideline('High', 'Tool unusable but no safety risk'),
                              _buildPriorityGuideline('Medium', 'Tool partially functional'),
                              _buildPriorityGuideline('Low', 'Minor issue, tool still usable'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade600, Colors.red.shade700],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _submitReport,
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Submit Report',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: Colors.black87, fontSize: 16),
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 15),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
          prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey[600]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 15),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
          prefixIcon: Icon(Icons.description, size: 20, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 15),
          hintText: value == null ? 'Select...' : null,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
            overflow: TextOverflow.ellipsis,
          ),
          prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey[600]) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((DropdownMenuItem<String> item) {
            if (item.value != value) {
              return SizedBox.shrink();
            }
            // Return the child with proper overflow handling
            return Container(
              alignment: AlignmentDirectional.centerStart,
              child: item.child,
            );
          }).toList();
        },
        dropdownColor: AppTheme.cardSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        menuMaxHeight: 300,
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildPriorityGuideline(String priority, String description) {
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$priority: $description',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
