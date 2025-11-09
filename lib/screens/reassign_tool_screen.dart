import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import '../services/supabase_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Reassign: ${widget.tool.name}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<SupabaseTechnicianProvider>(
        builder: (context, technicianProvider, child) {
          final technicians = technicianProvider.getActiveTechniciansSync();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Assignment Info
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Current Assignment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Consumer<SupabaseTechnicianProvider>(
                          builder: (context, technicianProvider, child) {
                            final technicianName = technicianProvider.getTechnicianNameById(widget.tool.assignedTo) ?? 'Unknown';
                            return Text(
                              'Currently assigned to: $technicianName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Tool Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.build,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tool.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${widget.tool.category} • ${widget.tool.brand ?? 'Unknown'}',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // New Technician Selection
                Text(
                  'Assign to New Technician',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                
                if (technicians.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No active technicians available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      children: technicians.map((technician) {
                        return RadioListTile<Technician>(
                          title: Text(
                            technician.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '${technician.department ?? 'No Department'} • ${technician.employeeId ?? 'No ID'}',
                            style: TextStyle(color: Colors.grey),
                          ),
                          value: technician,
                          groupValue: _selectedTechnician,
                          onChanged: (Technician? value) {
                            setState(() {
                              _selectedTechnician = value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: 24),

                // Reassignment Notes
                Text(
                  'Reassignment Notes (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Add any notes about this reassignment...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 32),

                // Reassign Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedTechnician != null && !_isLoading
                        ? _reassignTool
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Reassign Tool',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
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
