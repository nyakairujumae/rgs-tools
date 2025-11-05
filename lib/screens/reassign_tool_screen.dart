import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';

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
        backgroundColor: Colors.white,
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
      // Update tool assignment using technician UUID
      if (_selectedTechnician!.id != null && widget.tool.id != null) {
        await context.read<SupabaseToolProvider>().assignTool(
          widget.tool.id!,
          _selectedTechnician!.id!,
          'Permanent',
        );
        
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
