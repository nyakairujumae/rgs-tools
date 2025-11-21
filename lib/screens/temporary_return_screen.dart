import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import "../providers/supabase_technician_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class TemporaryReturnScreen extends StatefulWidget {
  final Tool tool;

  const TemporaryReturnScreen({super.key, required this.tool});

  @override
  State<TemporaryReturnScreen> createState() => _TemporaryReturnScreenState();
}

class _TemporaryReturnScreenState extends State<TemporaryReturnScreen> {
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String _returnReason = 'Leave/Vacation';
  DateTime? _expectedReturnDate;
  bool _isLoading = false;

  final List<String> _returnReasons = [
    'Leave/Vacation',
    'Sick Leave',
    'Training',
    'Other Assignment',
    'Tool Maintenance',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Temporary Return: ${widget.tool.name}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool Info Card
              Container(
                width: double.infinity,
                padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradientFor(context),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
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
                        Container(
                          width: ResponsiveHelper.getResponsiveIconSize(context, 56),
                          height: ResponsiveHelper.getResponsiveIconSize(context, 56),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade600, Colors.blue.shade700],
                            ),
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                          ),
                          child: Icon(
                            Icons.build,
                            color: Colors.white,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 28),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tool.name,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                              Text(
                                '${widget.tool.category} • ${widget.tool.brand ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              if (widget.tool.assignedTo != null)
                                Consumer<SupabaseTechnicianProvider>(
                                  builder: (context, technicianProvider, child) {
                                    final technicianName = technicianProvider.getTechnicianNameById(widget.tool.assignedTo) ?? 'Unknown';
                                    return Padding(
                                      padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                                      child: Text(
                                        'Currently assigned to: $technicianName',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                                          color: Colors.blue.shade400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

              // Return Info
              Text(
                'Temporary Return',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                'This tool will be temporarily returned to the company. The technician will get it back when they return.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

              // Return Reason
              Text(
                'Reason for Return',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradientFor(context),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
                  child: DropdownButtonFormField<String>(
                    value: _returnReason,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Select reason',
                      labelStyle: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    dropdownColor: isDarkMode ? AppTheme.cardColor : Colors.white,
                    items: _returnReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _returnReason = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

              // Expected Return Date
              Text(
                'Expected Return Date',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradientFor(context),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _selectReturnDate,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'When will the technician return?',
                      labelStyle: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: ResponsiveHelper.getResponsivePadding(context, all: 16),
                    ),
                    child: Text(
                      _expectedReturnDate != null
                          ? '${_expectedReturnDate!.day}/${_expectedReturnDate!.month}/${_expectedReturnDate!.year}'
                          : 'Select expected return date',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: _expectedReturnDate != null 
                            ? theme.textTheme.bodyLarge?.color 
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

              // Notes
              Text(
                'Return Notes (Optional)',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradientFor(context),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _notesController,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add any notes about this temporary return...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: ResponsiveHelper.getResponsivePadding(context, all: 16),
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

              // Return Button
              Container(
                width: double.infinity,
                height: ResponsiveHelper.getResponsiveSpacing(context, 56),
                decoration: BoxDecoration(
                  gradient: _expectedReturnDate != null && !_isLoading
                      ? LinearGradient(
                          colors: [Colors.orange.shade600, Colors.orange.shade700],
                        )
                      : null,
                  color: _expectedReturnDate == null || _isLoading
                      ? Colors.grey.withOpacity(0.3)
                      : null,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                  boxShadow: _expectedReturnDate != null && !_isLoading
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _expectedReturnDate != null && !_isLoading
                        ? _temporaryReturn
                        : null,
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: ResponsiveHelper.getResponsiveIconSize(context, 24),
                              height: ResponsiveHelper.getResponsiveIconSize(context, 24),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Temporary Return',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectReturnDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expectedReturnDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _expectedReturnDate = date;
      });
    }
  }

  Future<void> _temporaryReturn() async {
    if (_expectedReturnDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update tool status to temporarily available
      final updatedTool = widget.tool.copyWith(
        status: 'Available',
        assignedTo: null,
        notes: 'Temporarily returned - ${_returnReason}. Expected return: ${_expectedReturnDate!.toIso8601String().split('T')[0]}',
      );

      await context.read<SupabaseToolProvider>().updateTool(updatedTool);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.tool.name} temporarily returned. Expected back: ${_expectedReturnDate!.toIso8601String().split('T')[0]}'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing return: $e'),
            backgroundColor: Colors.red,
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
