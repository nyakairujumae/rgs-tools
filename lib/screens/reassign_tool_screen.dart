import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';

class ReassignToolScreen extends StatefulWidget {
  final Tool tool;

  const ReassignToolScreen({super.key, required this.tool});

  @override
  State<ReassignToolScreen> createState() => _ReassignToolScreenState();
}

class _ReassignToolScreenState extends State<ReassignToolScreen> {
  Technician? _selectedTechnician;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Reassign: ${widget.tool.name}',
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
        child: Consumer<SupabaseTechnicianProvider>(
          builder: (context, technicianProvider, child) {
            final technicians = technicianProvider.getActiveTechniciansSync();
            
            return SingleChildScrollView(
              padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Assignment Info
                  Container(
                    width: double.infinity,
                    padding: ResponsiveHelper.getResponsivePadding(context, all: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)]
                            : [Colors.orange.shade50, Colors.orange.shade100],
                      ),
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
                              padding: ResponsiveHelper.getResponsivePadding(context, all: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            Text(
                              'Current Assignment',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        Consumer<SupabaseTechnicianProvider>(
                          builder: (context, technicianProvider, child) {
                            final technicianName = technicianProvider.getTechnicianNameById(widget.tool.assignedTo) ?? 'Unknown';
                            return Text(
                              'Currently assigned to: $technicianName',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                color: theme.textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

                  // Tool Info
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
                    child: Row(
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                  // New Technician Selection
                  Text(
                    'Assign to New Technician',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  if (technicians.isEmpty)
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
                      child: Center(
                        child: Text(
                          'No active technicians available',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
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
                        children: technicians.map((technician) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: RadioListTile<Technician>(
                              title: Text(
                                technician.name,
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              subtitle: Text(
                                '${technician.department ?? 'No Department'} • ${technician.employeeId ?? 'No ID'}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              value: technician,
                              groupValue: _selectedTechnician,
                              activeColor: Colors.blue,
                              onChanged: (Technician? value) {
                                setState(() {
                                  _selectedTechnician = value;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                  // Reassignment Notes
                  Text(
                    'Reassignment Notes (Optional)',
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
                        hintText: 'Add any notes about this reassignment...',
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

                  // Reassign Button
                  Container(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveSpacing(context, 56),
                    decoration: BoxDecoration(
                      gradient: _selectedTechnician != null && !_isLoading
                          ? LinearGradient(
                              colors: [Colors.orange.shade600, Colors.orange.shade700],
                            )
                          : null,
                      color: _selectedTechnician == null || _isLoading
                          ? Colors.grey.withOpacity(0.3)
                          : null,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      boxShadow: _selectedTechnician != null && !_isLoading
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
                        onTap: _selectedTechnician != null && !_isLoading
                            ? _reassignTool
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
                                  'Reassign Tool',
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _reassignTool() async {
    if (_selectedTechnician == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update tool assignment using user ID (check approval record first, then users table)
      if (_selectedTechnician!.email != null && _selectedTechnician!.email!.isNotEmpty && widget.tool.id != null) {
        final technicianEmail = _selectedTechnician!.email!.trim();
        String? userId;
        
        // First, check if there's an approved pending approval record (this has the user_id)
        final approvalRecord = await SupabaseService.client
            .from('pending_user_approvals')
            .select('user_id, status')
            .eq('email', technicianEmail)
            .eq('status', 'approved')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (approvalRecord != null && approvalRecord['user_id'] != null) {
          userId = approvalRecord['user_id'] as String;
        } else {
          // If no approval record, try to find user in users table
          final userResponse = await SupabaseService.client
              .from('users')
              .select('id')
              .ilike('email', technicianEmail)
              .maybeSingle();
          
          if (userResponse != null && userResponse['id'] != null) {
            userId = userResponse['id'] as String;
          }
        }
        
        if (userId != null) {
          await context.read<SupabaseToolProvider>().assignTool(
            widget.tool.id!,
            userId,
            'Permanent',
          );
        } else {
          throw Exception('Could not find user account for ${_selectedTechnician!.name}. Please ensure they have registered and been approved by admin.');
        }
        
        // Update notes if provided
        if (_notesController.text.trim().isNotEmpty) {
      final updatedTool = widget.tool.copyWith(
            notes: '${widget.tool.notes ?? ''}\nReassigned to ${_selectedTechnician!.name}: ${_notesController.text.trim()}',
            updatedAt: DateTime.now().toIso8601String(),
      );
      await context.read<SupabaseToolProvider>().updateTool(updatedTool);
        }
      } else {
        throw Exception('Technician ID or Tool ID is required');
      }

      if (mounted) {
        // Refresh tools to get updated data
        await context.read<SupabaseToolProvider>().loadTools();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.tool.name} reassigned to ${_selectedTechnician!.name}'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reassigning tool: $e'),
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
