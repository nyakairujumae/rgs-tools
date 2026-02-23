import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import '../models/location.dart';
import '../models/permanent_assignment.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';

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
  void initState() {
    super.initState();
    // Load technicians when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Assign ${widget.tool.name}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            labelStyle: TextStyle(color: Colors.grey),
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            bodyMedium: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool Information Card
              _buildToolInfoCard(),
              SizedBox(height: 24),

              // Assignment Type
              _buildAssignmentTypeSection(),
              SizedBox(height: 24),

              // Technician Selection
              _buildTechnicianSelection(),
              SizedBox(height: 24),

              // Location Selection
              _buildLocationSelection(),
              SizedBox(height: 24),

              // Assignment Date
              _buildAssignmentDateSection(),
              SizedBox(height: 24),

              // Notes
              _buildNotesSection(),
              SizedBox(height: 32),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildToolInfoCard() {
    return Card(
      color: Theme.of(context).cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: AppTheme.primaryColor),
                SizedBox(width: 8),
        Text(
          'Tool Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
              ],
            ),
            SizedBox(height: 12),
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
        Text(
          'Assignment Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12),
        Card(
          color: Theme.of(context).cardTheme.color,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('Permanent Assignment', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  subtitle: Text('Tool assigned to technician long-term', style: TextStyle(color: Colors.grey)),
                  value: 'Permanent',
                  groupValue: _assignmentType,
                  onChanged: (value) {
                    setState(() {
                      _assignmentType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text('Temporary Assignment', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  subtitle: Text('Tool assigned for specific project/duration', style: TextStyle(color: Colors.grey)),
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
        Text(
          'Select Technician',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12),
        Consumer<SupabaseTechnicianProvider>(
          builder: (context, technicianProvider, child) {
            // Debug: Print technician count
            Logger.debug('Total technicians: ${technicianProvider.technicians.length}');
            Logger.debug('Technician provider loading: ${technicianProvider.isLoading}');
            
            if (technicianProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final activeTechnicians = technicianProvider.technicians
                .where((tech) => tech.status == 'Active')
                .toList();

            Logger.debug('Active technicians: ${activeTechnicians.length}');

            if (activeTechnicians.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 20, color: Colors.orange[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No technicians available. Add technicians first.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

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
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 50, // Fixed height to prevent overflow
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Prevent overflow
                      children: [
                        Text(
                          technician.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (technician.department != null)
                          Text(
                            technician.department!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
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
        Text(
          'Assignment Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedLocation?.id,
          decoration: const InputDecoration(
            labelText: 'Location (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          items: _getMockLocations().map((location) {
            return DropdownMenuItem(
              value: location.id,
              child: Text(
                location.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              if (value != null) {
                _selectedLocation = _getMockLocations().firstWhere((loc) => loc.id == value);
              } else {
                _selectedLocation = null;
              }
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
        Text(
          'Assignment Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
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
        Text(
          'Assignment Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12),
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
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Theme.of(context).textTheme.bodyLarge?.color)
                : Text(
                    _assignmentType == 'Permanent' 
                        ? 'Assign Permanently' 
                        : 'Assign Temporarily',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12),
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
            child: Text('Cancel'),
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
              value,
              style: TextStyle(color: AppTheme.textPrimary),
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
      // Update tool status and assignment using user ID (check approval record first, then users table)
      if (_selectedTechnician!.email != null && _selectedTechnician!.email!.isNotEmpty) {
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
            _assignmentType,
          );
        } else {
          throw Exception('Could not find user account for ${_selectedTechnician!.name}. Please ensure they have registered and been approved by admin.');
        }
      } else {
        throw Exception('Technician email is required');
      }

      // TODO: Create permanent assignment record in database
      // This would typically be done through a service layer

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.tool.name} assigned to ${_selectedTechnician!.name}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Refresh tools to get updated data
        await context.read<SupabaseToolProvider>().loadTools();
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
