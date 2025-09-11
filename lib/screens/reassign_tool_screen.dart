import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_provider.dart';
import '../providers/technician_provider.dart';
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
      body: Consumer<TechnicianProvider>(
        builder: (context, technicianProvider, child) {
          final technicians = technicianProvider.getActiveTechnicians();
          
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
                        const Row(
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
                        const SizedBox(height: 8),
                        Text(
                          'Currently assigned to: ${widget.tool.assignedTo ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tool Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: const Icon(
                            Icons.build,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tool.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${widget.tool.category} • ${widget.tool.brand ?? 'Unknown'}',
                                style: const TextStyle(
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
                const SizedBox(height: 24),

                // New Technician Selection
                const Text(
                  'Assign to New Technician',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (technicians.isEmpty)
                  const Card(
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '${technician.department ?? 'No Department'} • ${technician.employeeId ?? 'No ID'}',
                            style: const TextStyle(color: Colors.grey),
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
                const SizedBox(height: 24),

                // Reassignment Notes
                const Text(
                  'Reassignment Notes (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Add any notes about this reassignment...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

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
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
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
      // Update tool assignment
      final updatedTool = widget.tool.copyWith(
        assignedTo: _selectedTechnician!.name,
        notes: _notesController.text.trim().isEmpty 
            ? widget.tool.notes 
            : '${widget.tool.notes ?? ''}\nReassigned to ${_selectedTechnician!.name}: ${_notesController.text.trim()}',
      );

      await context.read<ToolProvider>().updateTool(updatedTool);

      if (mounted) {
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
