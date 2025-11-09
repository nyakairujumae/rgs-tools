import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../providers/supabase_tool_provider.dart";
import "../providers/supabase_technician_provider.dart";
import '../models/tool.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Temporary Return: ${widget.tool.name}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                              if (widget.tool.assignedTo != null)
                                Consumer<SupabaseTechnicianProvider>(
                                  builder: (context, technicianProvider, child) {
                                    final technicianName = technicianProvider.getTechnicianNameById(widget.tool.assignedTo) ?? 'Unknown';
                                    return Text(
                                      'Currently assigned to: $technicianName',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
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
            ),
            SizedBox(height: 24),

            // Return Info
            Text(
              'Temporary Return',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This tool will be temporarily returned to the company. The technician will get it back when they return.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),

            // Return Reason
            Text(
              'Reason for Return',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _returnReason,
                  decoration: const InputDecoration(
                    labelText: 'Select reason',
                    border: OutlineInputBorder(),
                  ),
                  items: _returnReasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
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
            SizedBox(height: 24),

            // Expected Return Date
            Text(
              'Expected Return Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            InkWell(
              onTap: _selectReturnDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'When will the technician return?',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _expectedReturnDate != null
                      ? '${_expectedReturnDate!.day}/${_expectedReturnDate!.month}/${_expectedReturnDate!.year}'
                      : 'Select expected return date',
                  style: TextStyle(
                    color: _expectedReturnDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Notes
            Text(
              'Return Notes (Optional)',
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
                hintText: 'Add any notes about this temporary return...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 32),

            // Return Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _expectedReturnDate != null && !_isLoading
                    ? _temporaryReturn
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
                        'Temporary Return',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
