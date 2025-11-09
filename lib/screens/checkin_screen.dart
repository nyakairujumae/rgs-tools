import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/tool.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../utils/error_handler.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> with ErrorHandlingMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _searchQuery = '';
  Tool? _selectedTool;
  DateTime? _checkinDate;
  String _returnCondition = 'Good';
  bool _isSaving = false;

  final List<String> _conditions = const ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradientFor(context)),
        child: SafeArea(
          child: Consumer3<SupabaseToolProvider, AuthProvider, SupabaseTechnicianProvider>(
            builder: (context, toolProvider, authProvider, technicianProvider, child) {
              final currentUserId = authProvider.userId;
              final filteredTools = toolProvider.tools.where((tool) {
                final belongsToTechnician = currentUserId != null && tool.assignedTo == currentUserId;
                final statusEligible = tool.status == 'Assigned' || tool.status == 'In Use';
                final matchesQuery = _searchQuery.isEmpty ||
                    tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (tool.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                    (tool.serialNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                return belongsToTechnician && statusEligible && matchesQuery;
              }).toList();

              return Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await toolProvider.loadTools();
                      },
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        children: [
                          _buildSearchCard(context),
                          const SizedBox(height: 24),
                          _buildToolList(context, filteredTools, technicianProvider),
                          if (_selectedTool != null) ...[
                            const SizedBox(height: 24),
                            _buildSelectedToolCard(context, technicianProvider),
                            const SizedBox(height: 16),
                            _buildCheckinForm(context),
                          ],
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActions(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check In Tool',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan or search for tools you currently hold, review their condition, and return them to the inventory.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by tool name, brand, or serial number',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _openScanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                child: const Icon(Icons.qr_code_scanner, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Only tools currently assigned to you are listed below. Use the scanner to speed up the search.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildToolList(BuildContext context, List<Tool> tools, SupabaseTechnicianProvider technicianProvider) {
    if (tools.isEmpty) {
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradientFor(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      child: Column(
        children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              'No tools to check in',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You currently do not have any tools assigned to you. Badge a shared tool or request one from the admin team.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tools Assigned to You',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
        ),
        const SizedBox(height: 12),
        ...tools.map((tool) {
          final bool isSelected = _selectedTool?.id == tool.id;
          final technicianName = technicianProvider.getTechnicianNameById(tool.assignedTo) ?? 'You';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTool = tool;
                _checkinDate = DateTime.now();
                _returnCondition = 'Good';
                _notesController.clear();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradientFor(context),
                borderRadius: BorderRadius.circular(24),
                border: isSelected ? Border.all(color: AppTheme.primaryColor, width: 1.8) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade100, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.build, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            StatusChip(status: tool.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${tool.category}${tool.brand != null && tool.brand!.isNotEmpty ? ' • ${tool.brand}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              tool.serialNumber ?? 'No serial number',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Assigned to: $technicianName',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ],
      ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedToolCard(BuildContext context, SupabaseTechnicianProvider technicianProvider) {
    final tool = _selectedTool!;
    final technicianName = technicianProvider.getTechnicianNameById(tool.assignedTo) ?? 'You';

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
              Icon(Icons.assignment_turned_in_outlined, color: Colors.green.shade600),
              const SizedBox(width: 8),
                  Text(
                'Selected Tool',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 16),
          _buildDetailRow('Name', tool.name),
          _buildDetailRow('Category', tool.category),
          if (tool.brand != null && tool.brand!.isNotEmpty)
            _buildDetailRow('Brand', tool.brand!),
          if (tool.serialNumber != null && tool.serialNumber!.isNotEmpty)
            _buildDetailRow('Serial Number', tool.serialNumber!),
          _buildDetailRow('Currently Assigned', technicianName),
          Row(
            children: [
              const SizedBox(width: 110, child: Text('Status', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
              StatusChip(status: tool.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinForm(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.blue.shade600),
              const SizedBox(width: 8),
          Text(
                'Check-In Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selectCheckinDate,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blue.shade100),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.event_available, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Text(
                _checkinDate != null
                    ? '${_checkinDate!.day}/${_checkinDate!.month}/${_checkinDate!.year}'
                        : 'Select check-in date',
                style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _checkinDate != null ? Colors.black : Colors.grey[500],
                    ),
                ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Returned Condition',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _conditions.map((condition) {
              final bool isSelected = _returnCondition == condition;
              final colors = isSelected
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.grey.shade200, Colors.grey.shade200];
              return ChoiceChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (_) => setState(() => _returnCondition = condition),
                backgroundColor: colors.first,
                selectedColor: colors.last,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any issues, damage, or additional information...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final canSubmit = _selectedTool != null && _checkinDate != null && !_isSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: canSubmit
                  ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)])
                  : const LinearGradient(colors: [Colors.grey, Colors.grey]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (canSubmit)
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: ElevatedButton(
              onPressed: canSubmit ? _performCheckin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.assignment_turned_in, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Check In Tool',
                      style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                        fontSize: 16,
                          ),
                      ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _openScanner() async {
    final scannedCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Stack(
        children: [
                MobileScanner(
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.noDuplicates,
                    facing: CameraFacing.back,
                  ),
                  onDetect: (capture) {
                    final code = capture.barcodes.first.rawValue;
                    if (code != null) {
                      Navigator.of(context).pop(code);
                    }
                  },
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (scannedCode != null) {
      _searchController.text = scannedCode;
      setState(() {
        _searchQuery = scannedCode;
      });
    }
  }

  Future<void> _selectCheckinDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkinDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _checkinDate = picked);
    }
  }

  Future<void> _performCheckin() async {
    if (_selectedTool == null || _checkinDate == null) return;

    setState(() => _isSaving = true);

    try {
      String newStatus = 'Available';
      if (_returnCondition == 'Poor' || _returnCondition == 'Needs Repair') {
        newStatus = 'Maintenance';
      }

      final updatedTool = _selectedTool!.copyWith(
        status: newStatus,
        condition: _returnCondition,
        assignedTo: null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await context.read<SupabaseToolProvider>().updateTool(updatedTool);
      await context.read<SupabaseToolProvider>().loadTools();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedTool!.name} checked in successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}