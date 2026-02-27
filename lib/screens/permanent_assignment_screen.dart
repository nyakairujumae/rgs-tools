import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool.dart';
import '../models/technician.dart';
import '../models/location.dart';
import '../models/permanent_assignment.dart';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/technician_notification_provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';

class PermanentAssignmentScreen extends StatefulWidget {
  /// Single tool (e.g. from tool detail "Assign to Technician").
  final Tool? tool;
  /// Multiple tools (e.g. from Select Tools → "Assign X Tools").
  final List<Tool>? tools;

  const PermanentAssignmentScreen({
    super.key,
    this.tool,
    this.tools,
  }) : assert(tool != null || (tools != null && tools.length > 0),
          'Provide either tool or a non-empty tools list');

  List<Tool> get _toolsList =>
      (tools != null && tools!.isNotEmpty) ? tools! : [tool!];

  @override
  State<PermanentAssignmentScreen> createState() => _PermanentAssignmentScreenState();
}

class _PermanentAssignmentScreenState extends State<PermanentAssignmentScreen> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _technicianController = TextEditingController();

  final List<Technician> _selectedTechnicians = [];
  Location? _selectedLocation;
  DateTime? _assignmentDate;
  String _assignmentType = 'Permanent';
  bool _isLoading = false;
  String? _technicianError;

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
    _dateController.dispose();
    _technicianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          widget._toolsList.length == 1
              ? 'Assign ${widget._toolsList.first.name}'
              : 'Assign ${widget._toolsList.length} Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: context.scaffoldBackground,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToolInfoCard(),
              const SizedBox(height: 24),
              _buildAssignmentTypeSection(),
              const SizedBox(height: 24),
              _buildTechnicianSelection(),
              const SizedBox(height: 24),
              _buildLocationSelection(),
              const SizedBox(height: 24),
              _buildAssignmentDateSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolInfoCard() {
    final theme = Theme.of(context);
    final list = widget._toolsList;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_outlined, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(
                'Tool Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (list.length == 1) ...[
            _buildInfoRow('Name', list.first.name),
            _buildInfoRow('Category', list.first.category),
            if (list.first.brand != null) _buildInfoRow('Brand', list.first.brand!),
            if (list.first.serialNumber != null) _buildInfoRow('Serial Number', list.first.serialNumber!),
            _buildInfoRow('Current Status', list.first.status, statusWidget: StatusChip(status: list.first.status)),
          ] else ...[
            _buildInfoRow('Tools selected', '${list.length} tools'),
            const SizedBox(height: 8),
            ...list.take(5).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.name, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface))),
                  if (t.status.isNotEmpty)
                    StatusChip(status: t.status),
                ],
              ),
            )),
            if (list.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'and ${list.length - 5} more',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentTypeSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: context.cardDecoration,
          child: Column(
            children: [
              RadioListTile<String>(
                title: Text(
                  'Permanent Assignment',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Tool assigned to technician long-term',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                value: 'Permanent',
                groupValue: _assignmentType,
                activeColor: AppTheme.secondaryColor,
                onChanged: (value) {
                  setState(() => _assignmentType = value!);
                },
              ),
              RadioListTile<String>(
                title: Text(
                  'Temporary Assignment',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Tool assigned for specific project/duration',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                value: 'Temporary',
                groupValue: _assignmentType,
                activeColor: AppTheme.secondaryColor,
                onChanged: (value) {
                  setState(() => _assignmentType = value!);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianSelection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Technician',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<SupabaseTechnicianProvider>(
          builder: (context, technicianProvider, child) {
            Logger.debug('Total technicians: ${technicianProvider.technicians.length}');
            if (technicianProvider.isLoading) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: context.cardDecoration,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final activeTechnicians = technicianProvider.technicians
                .where((tech) => tech.status == 'Active')
                .toList();

            if (activeTechnicians.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(context.borderRadiusLarge),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, size: 20, color: AppTheme.warningColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No technicians available. Add technicians first.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  readOnly: true,
                  onTap: () => _showTechnicianPicker(context, activeTechnicians),
                  controller: _technicianController,
                  decoration: context.chatGPTInputDecoration.copyWith(
                    labelText: 'Technician *',
                    hintText: 'Tap to select one or more technicians',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      size: 22,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 24,
                    ),
                    errorText: _technicianError,
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                if (_selectedTechnicians.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedTechnicians.map((t) {
                      return Chip(
                        label: Text(
                          t.name,
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16, color: theme.colorScheme.onSurface),
                        onDeleted: () {
                          setState(() {
                            _selectedTechnicians.remove(t);
                            _technicianError = null;
                            _updateTechnicianController();
                          });
                        },
                        backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showTechnicianPicker(BuildContext context, List<Technician> activeTechnicians) async {
    final selected = List<Technician>.from(_selectedTechnicians);
    final result = await showModalBottomSheet<List<Technician>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetTheme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: ctx.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: ctx.cardBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Technicians',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: sheetTheme.colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, selected),
                          child: Text('Done', style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: activeTechnicians.length,
                      itemBuilder: (_, index) {
                        final tech = activeTechnicians[index];
                        final isSelected = selected.any((t) => t.id == tech.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setSheetState(() {
                              if (value == true) {
                                selected.add(tech);
                              } else {
                                selected.removeWhere((t) => t.id == tech.id);
                              }
                            });
                          },
                          title: Text(
                            tech.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: sheetTheme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: tech.department != null
                              ? Text(
                                  tech.department!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: sheetTheme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                )
                              : null,
                          activeColor: AppTheme.secondaryColor,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result != null && mounted) {
      setState(() {
        _selectedTechnicians
          ..clear()
          ..addAll(result);
        _technicianError = null;
        _updateTechnicianController();
      });
    }
  }

  void _updateTechnicianController() {
    if (_selectedTechnicians.isEmpty) {
      _technicianController.text = '';
    } else if (_selectedTechnicians.length == 1) {
      _technicianController.text = _selectedTechnicians.first.name;
    } else {
      _technicianController.text = '${_selectedTechnicians.length} technicians selected';
    }
  }

  Widget _buildLocationSelection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedLocation?.id,
          decoration: context.chatGPTInputDecoration.copyWith(
            labelText: 'Location (Optional)',
            prefixIcon: Icon(
              Icons.location_on_outlined,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          dropdownColor: context.cardBackground,
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
          items: _getMockLocations().map((location) {
            return DropdownMenuItem(
              value: location.id,
              child: Text(
                location.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          readOnly: true,
          onTap: _selectAssignmentDate,
          controller: _dateController,
          decoration: context.chatGPTInputDecoration.copyWith(
            labelText: 'Assignment Date *',
            hintText: 'Select date',
            prefixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: context.chatGPTInputDecoration.copyWith(
            labelText: 'Notes (Optional)',
            hintText: 'Any special instructions or notes...',
            prefixIcon: Icon(
              Icons.note_outlined,
              size: 22,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          maxLines: 3,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _canAssign() ? _performAssignment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusLarge),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _assignmentType == 'Permanent'
                        ? 'Assign Permanently'
                        : 'Assign Temporarily',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              side: const BorderSide(color: AppTheme.secondaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusLarge),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? statusWidget}) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurface),
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
        _dateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  bool _canAssign() {
    return _selectedTechnicians.isNotEmpty &&
           _assignmentDate != null &&
           !_isLoading;
  }

  Future<void> _performAssignment() async {
    if (!_canAssign()) return;

    // Validate at least one technician has a linked account (we assign to first)
    final primary = _selectedTechnicians.first;
    final userId = primary.userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _technicianError = 'No linked account for ${primary.name}. Ensure they are registered and approved.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _technicianError = null;
    });

    try {
      final toolsList = widget._toolsList;
      Logger.debug('🔧 Assigning ${toolsList.length} tool(s) to ${_selectedTechnicians.length} technician(s), primary: $userId');

      final toolProvider = context.read<SupabaseToolProvider>();
      final adminName = context.read<AuthProvider>().userFullName ?? 'Admin';
      final assignedByName = context.read<AuthProvider>().userId;

      for (final tool in toolsList) {
        if (tool.id == null) continue;
        await SupabaseService.client.from('tools').update({
          'status': 'Pending Acceptance',
          'assigned_to': userId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', tool.id!);

        final notificationData = {
          'tool_id': tool.id!,
          'tool_name': tool.name,
          'assigned_by_name': adminName,
          'assigned_by_id': assignedByName,
          'assignment_type': _assignmentType,
        };

        for (final tech in _selectedTechnicians) {
          final uid = tech.userId;
          if (uid == null || uid.isEmpty) continue;

          await SupabaseService.client.from('technician_notifications').insert({
            'user_id': uid,
            'title': 'Tool Assignment: ${tool.name}',
            'message': '$adminName wants to assign "${tool.name}" to you. Please accept to take ownership.',
            'type': 'tool_assigned',
            'is_read': false,
            'timestamp': DateTime.now().toIso8601String(),
            'data': notificationData,
          });

          try {
            await PushNotificationService.sendToUser(
              userId: uid,
              title: 'Tool Assignment: ${tool.name}',
              body: '$adminName wants to assign "${tool.name}" to you. Tap to accept.',
              data: {'type': 'tool_assigned', ...notificationData},
            );
          } catch (pushError) {
            Logger.debug('⚠️ Push notification failed for ${tech.name}: $pushError');
          }
        }
      }

      await toolProvider.loadTools();

      if (mounted) {
        final toolLabel = toolsList.length == 1 ? toolsList.first.name : '${toolsList.length} tools';
        final techLabel = _selectedTechnicians.length == 1
            ? _selectedTechnicians.first.name
            : '${_selectedTechnicians.length} technicians';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$toolLabel sent to $techLabel for acceptance'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
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
