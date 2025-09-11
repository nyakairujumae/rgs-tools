import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import '../models/location.dart';
import '../models/permanent_assignment.dart';
import '../providers/tool_provider.dart';
import '../providers/technician_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';

class PermanentAssignmentScreen extends StatefulWidget {
  final Tool tool;

  const PermanentAssignmentScreen({super.key, required this.tool});

  @override
  State<PermanentAssignmentScreen> createState() => _PermanentAssignmentScreenState();
}

class _PermanentAssignmentScreenState extends State<PermanentAssignmentScreen> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  Technician? _selectedTechnician;
  Location? _selectedLocation;
  DateTime? _assignmentDate;
  String _assignmentType = 'Permanent';
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
        title: Text('Assign ${widget.tool.name}'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool Information Card
              _buildToolInfoCard(),
              const SizedBox(height: 24),

              // Assignment Type
              _buildAssignmentTypeSection(),
              const SizedBox(height: 24),

              // Technician Selection
              _buildTechnicianSelection(),
              const SizedBox(height: 24),

              // Location Selection
              _buildLocationSelection(),
              const SizedBox(height: 24),

              // Assignment Date
              _buildAssignmentDateSection(),
              const SizedBox(height: 24),

              // Notes
              _buildNotesSection(),
              const SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Tool Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', widget.tool.name),
            _buildInfoRow('Category', widget.tool.category),
            if (widget.tool.brand != null) _buildInfoRow('Brand', widget.tool.brand!),
            if (widget.tool.serialNumber != null) _buildInfoRow('Serial Number', widget.tool.serialNumber!),
            _buildInfoRow('Current Status', widget.tool.status, statusWidget: StatusChip(status: widget.tool.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Permanent Assignment'),
                  subtitle: const Text('Tool assigned to technician long-term'),
                  value: 'Permanent',
                  groupValue: _assignmentType,
                  onChanged: (value) {
                    setState(() {
                      _assignmentType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Temporary Assignment'),
                  subtitle: const Text('Tool assigned for specific project/duration'),
                  value: 'Temporary',
                  groupValue: _assignmentType,
                  onChanged: (value) {
                    setState(() {
                      _assignmentType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Technician',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<TechnicianProvider>(
          builder: (context, technicianProvider, child) {
            final activeTechnicians = technicianProvider.technicians
                .where((tech) => tech.status == 'Active')
                .toList();

            return DropdownButtonFormField<Technician>(
              value: _selectedTechnician,
              decoration: const InputDecoration(
                labelText: 'Technician *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: activeTechnicians.map((technician) {
                return DropdownMenuItem(
                  value: technician,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(technician.name),
                      if (technician.department != null)
                        Text(
                          technician.department!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTechnician = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a technician';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Location>(
          value: _selectedLocation,
          decoration: const InputDecoration(
            labelText: 'Location (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          items: _getMockLocations().map((location) {
            return DropdownMenuItem(
              value: location,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.name),
                  Text(
                    location.fullAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLocation = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAssignmentDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectAssignmentDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Assignment Date *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _assignmentDate != null
                  ? '${_assignmentDate!.day}/${_assignmentDate!.month}/${_assignmentDate!.year}'
                  : 'Select date',
              style: TextStyle(
                color: _assignmentDate != null ? AppTheme.textPrimary : AppTheme.textHint,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            border: OutlineInputBorder(),
            hintText: 'Any special instructions or notes...',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _canAssign() ? _performAssignment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _assignmentType == 'Permanent' 
                        ? 'Assign Permanently' 
                        : 'Assign Temporarily',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? statusWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  List<Location> _getMockLocations() {
    return [
      Location(
        id: 1,
        name: 'Main Office',
        address: '123 Business St',
        city: 'Dubai',
        state: 'Dubai',
        country: 'UAE',
        postalCode: '12345',
        phone: '+971-4-123-4567',
        managerName: 'Ahmed Al-Rashid',
      ),
      Location(
        id: 2,
        name: 'Site A - Downtown',
        address: '456 Construction Ave',
        city: 'Dubai',
        state: 'Dubai',
        country: 'UAE',
        postalCode: '54321',
        phone: '+971-4-234-5678',
        managerName: 'Mohammed Hassan',
      ),
      Location(
        id: 3,
        name: 'Site B - Marina',
        address: '789 Marina Walk',
        city: 'Dubai',
        state: 'Dubai',
        country: 'UAE',
        postalCode: '67890',
        phone: '+971-4-345-6789',
        managerName: 'Omar Al-Zahra',
      ),
    ];
  }

  Future<void> _selectAssignmentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _assignmentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _assignmentDate = date;
      });
    }
  }

  bool _canAssign() {
    return _selectedTechnician != null && 
           _assignmentDate != null &&
           !_isLoading;
  }

  Future<void> _performAssignment() async {
    if (!_canAssign()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update tool status and assignment
      final updatedTool = widget.tool.copyWith(
        status: 'In Use',
        assignedTo: _selectedTechnician!.name,
        location: _selectedLocation?.name,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await context.read<ToolProvider>().updateTool(updatedTool);

      // TODO: Create permanent assignment record in database
      // This would typically be done through a service layer

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.tool.name} assigned to ${_selectedTechnician!.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
