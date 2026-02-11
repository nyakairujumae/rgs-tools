import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import "../providers/supabase_technician_provider.dart";
import '../models/tool.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
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

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Temporary Return: ${widget.tool.name}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: context.appBarBackground,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool Info Card
              Container(
                width: double.infinity,
                padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
                decoration: context.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveIconSize(context, 56),
                          height: ResponsiveHelper.getResponsiveIconSize(context, 56),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                          ),
                          child: Icon(
                            Icons.build,
                            color: AppTheme.primaryColor,
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
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                              Text(
                                '${widget.tool.category} • ${widget.tool.brand ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                                          color: AppTheme.primaryColor,
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                'This tool will be temporarily returned to the company. The technician will get it back when they return.',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

              // Return Reason
              Text(
                'Reason for Return',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Container(
                decoration: context.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
                  child: DropdownButtonFormField<String>(
                    value: _returnReason,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Select reason',
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    dropdownColor: context.cardBackground,
                    items: _returnReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
              Text(
                'When will the technician return?',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Container(
                decoration: context.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _selectReturnDate,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                  child: InputDecorator(
                    decoration: InputDecoration(
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
                            ? theme.colorScheme.onSurface 
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Container(
                decoration: context.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: TextField(
                  controller: _notesController,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add any notes about this temporary return...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
              SizedBox(
                width: double.infinity,
                height: ResponsiveHelper.getResponsiveSpacing(context, 56),
                child: FilledButton(
                  onPressed: _expectedReturnDate != null && !_isLoading
                      ? _temporaryReturn
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: ResponsiveHelper.getResponsiveIconSize(context, 24),
                          height: ResponsiveHelper.getResponsiveIconSize(context, 24),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Temporary Return',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
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
            backgroundColor: AppTheme.secondaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing return: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
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
