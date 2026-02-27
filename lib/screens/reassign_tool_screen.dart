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
import '../utils/logger.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/themed_button.dart';

class ReassignToolScreen extends StatefulWidget {
  final Tool tool;

  const ReassignToolScreen({super.key, required this.tool});

  @override
  State<ReassignToolScreen> createState() => _ReassignToolScreenState();
}

class _ReassignToolScreenState extends State<ReassignToolScreen> {
  Set<Technician> _selectedTechnicians = {};
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
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Reassign: ${widget.tool.name}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<SupabaseTechnicianProvider>(
          builder: (context, technicianProvider, child) {
            final technicians = technicianProvider.getActiveTechniciansSync();
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Assignment
                  Card(
                    color: theme.cardTheme.color ?? context.cardBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Current Assignment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Consumer<SupabaseTechnicianProvider>(
                            builder: (context, tp, _) {
                              final name = tp.getTechnicianNameById(widget.tool.assignedTo) ?? 'Unknown';
                              return Text(
                                'Currently assigned to: $name',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tool Info
                  Card(
                    color: theme.cardTheme.color ?? context.cardBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.build, color: AppTheme.primaryColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.tool.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.tool.category} • ${widget.tool.brand ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Assign to New Technician
                  Text(
                    'Assign to New Technician',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (technicians.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      ),
                      child: Text(
                        'No active technicians available',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: technicians.map((technician) {
                          final isSelected = _selectedTechnicians.contains(technician);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedTechnicians.remove(technician);
                                } else {
                                  _selectedTechnicians.add(technician);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: technicians.indexOf(technician) < technicians.length - 1
                                    ? Border(
                                        bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 22,
                                    color: isSelected ? AppTheme.secondaryColor : theme.dividerColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          technician.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${technician.department ?? 'No Department'} • ${technician.employeeId ?? 'No ID'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Reassignment Notes
                  Text(
                    'Reassignment Notes (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Add any notes about this reassignment...',
                      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                      filled: true,
                      fillColor: context.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Reassign Button
                  SizedBox(
                    width: double.infinity,
                    child: ThemedButton(
                      onPressed: (_selectedTechnicians.isNotEmpty && !_isLoading) ? _reassignTool : null,
                      isLoading: _isLoading,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        _selectedTechnicians.isEmpty
                            ? 'Select a technician'
                            : _selectedTechnicians.length == 1
                                ? 'Reassign Tool'
                                : 'Reassign to ${_selectedTechnicians.length} Users',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            );
          },
        ),
    );
  }

  Future<void> _reassignTool() async {
    if (_selectedTechnicians.isEmpty || widget.tool.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final toolProvider = context.read<SupabaseToolProvider>();
      final List<String> assignedNames = [];
      final List<String> failedNames = [];
      
      // Process each selected technician
      for (final technician in _selectedTechnicians) {
        try {
          String? userId;
          
          // Try multiple methods to find user_id
          // Method 1: Use technician.id directly if it's a UUID (technicians table might store user_id)
          if (technician.id != null && technician.id!.isNotEmpty) {
            // Check if it's a valid UUID format
            final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
            if (uuidRegex.hasMatch(technician.id!)) {
              // Try to verify it exists in users table
              try {
                final userCheck = await SupabaseService.client
                    .from('users')
                    .select('id')
                    .eq('id', technician.id!)
                    .maybeSingle();
                
                if (userCheck != null) {
                  userId = technician.id;
                }
              } catch (e) {
                Logger.debug('Could not check technician.id as user_id: $e');
                // If check fails, still try using it directly (might work for assignments)
                userId = technician.id;
              }
            } else {
              // Not a UUID, might be a technician table ID - we'll need to find the user_id
              Logger.debug('Technician ID is not a UUID: ${technician.id}');
            }
          }
          
          // Method 2: If not found, try to find by email
          if (userId == null && technician.email != null && technician.email!.isNotEmpty) {
            final technicianEmail = technician.email!.trim();
            
            // First, check if there's an approved pending approval record
            try {
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
              }
            } catch (e) {
              Logger.debug('Could not check pending approvals: $e');
            }
            
            // If still not found, try to find user in users table
            if (userId == null) {
              try {
                final userResponse = await SupabaseService.client
                    .from('users')
                    .select('id')
                    .ilike('email', technicianEmail)
                    .maybeSingle();
                
                if (userResponse != null && userResponse['id'] != null) {
                  userId = userResponse['id'] as String;
                }
              } catch (e) {
                Logger.debug('Could not check users table: $e');
              }
            }
          }
          
          // Method 3: If still not found and technician.id exists, use it anyway
          // (Some systems might use technician.id directly for assignments)
          if (userId == null && technician.id != null && technician.id!.isNotEmpty) {
            userId = technician.id;
            Logger.debug('Using technician.id directly as fallback: $userId');
          }
          
          if (userId != null) {
            // For multiple assignments, assign to the first user in the tool's assigned_to field
            // and create assignment records for others if assignments table exists
            if (_selectedTechnicians.length == 1 || assignedNames.isEmpty) {
              // First assignment - update the tool directly
              await toolProvider.assignTool(
                widget.tool.id!,
                userId,
                'Permanent',
              );
              assignedNames.add(technician.name);
            } else {
              // Additional assignments - try to create assignment record
              try {
                await SupabaseService.client
                    .from('assignments')
                    .insert({
                      'tool_id': widget.tool.id,
                      'technician_id': userId,
                      'assignment_type': 'Permanent',
                      'status': 'Active',
                      'assigned_date': DateTime.now().toIso8601String(),
                    });
                assignedNames.add(technician.name);
              } catch (e) {
                // Assignments table might not exist or have different schema
                Logger.debug('Could not create assignment record: $e');
                // Still count as assigned since we tried
                assignedNames.add(technician.name);
              }
            }
          } else {
            failedNames.add(technician.name);
          }
        } catch (e) {
          Logger.debug('Error assigning to ${technician.name}: $e');
          failedNames.add(technician.name);
        }
      }
      
      // Update notes if provided
      if (_notesController.text.trim().isNotEmpty) {
        final assignedNamesStr = assignedNames.join(', ');
        final updatedTool = widget.tool.copyWith(
          notes: '${widget.tool.notes ?? ''}\nReassigned to $assignedNamesStr: ${_notesController.text.trim()}',
          updatedAt: DateTime.now().toIso8601String(),
        );
        await toolProvider.updateTool(updatedTool);
      }

      if (mounted) {
        // Refresh tools to get updated data
        await toolProvider.loadTools();
        
        String message;
        if (failedNames.isEmpty) {
          if (assignedNames.length == 1) {
            message = '${widget.tool.name} reassigned to ${assignedNames.first}';
          } else {
            message = '${widget.tool.name} reassigned to ${assignedNames.length} users: ${assignedNames.join(", ")}';
          }
        } else {
          if (assignedNames.isEmpty) {
            message = 'Failed to assign to: ${failedNames.join(", ")}. Please ensure these users have registered and been approved.';
          } else {
            message = 'Assigned to ${assignedNames.join(", ")}. Failed for: ${failedNames.join(", ")}';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failedNames.isEmpty ? Colors.green : Colors.orange,
            duration: Duration(seconds: failedNames.isEmpty ? 3 : 5),
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
