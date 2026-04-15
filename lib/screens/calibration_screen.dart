import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/certification.dart';
import '../models/maintenance_schedule.dart';
import '../models/tool.dart';
import '../providers/supabase_certification_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';

// ─── Status helpers ──────────────────────────────────────────────────────────

enum CalibrationStatus { calibrated, dueSoon, overdue, notCalibrated }

CalibrationStatus _certStatus(Certification? cert) {
  if (cert == null) return CalibrationStatus.notCalibrated;
  final days = cert.daysUntilExpiry;
  if (days < 0) return CalibrationStatus.overdue;
  if (days <= 30) return CalibrationStatus.dueSoon;
  return CalibrationStatus.calibrated;
}

String _statusLabel(CalibrationStatus s) {
  switch (s) {
    case CalibrationStatus.calibrated:    return 'Calibrated';
    case CalibrationStatus.dueSoon:       return 'Due Soon';
    case CalibrationStatus.overdue:       return 'Overdue';
    case CalibrationStatus.notCalibrated: return 'Not Calibrated';
  }
}

Color _statusColor(CalibrationStatus s) {
  switch (s) {
    case CalibrationStatus.calibrated:    return const Color(0xFF10B981);
    case CalibrationStatus.dueSoon:       return const Color(0xFFF59E0B);
    case CalibrationStatus.overdue:       return const Color(0xFFEF4444);
    case CalibrationStatus.notCalibrated: return const Color(0xFF9CA3AF);
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class CalibrationScreen extends StatefulWidget {
  /// When set, only shows tools assigned to this user (technician view).
  final String? filterUserId;

  const CalibrationScreen({super.key, this.filterUserId});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  String _filter = 'All';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseCertificationProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: Consumer<SupabaseCertificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load data', style: TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => provider.loadAll(), child: const Text('Retry')),
                ],
              ),
            );
          }

          final tools = widget.filterUserId != null
              ? provider.tools
                  .where((t) => t.assignedTo == widget.filterUserId)
                  .toList()
              : provider.tools;
          final certs = provider.calibrationCerts;
          final schedules = provider.calibrationSchedules;

          final certMap = <String, Certification>{};
          for (final c in certs) certMap.putIfAbsent(c.toolId, () => c);

          int calibrated = 0, dueSoon = 0, overdue = 0, notCalibrated = 0;
          for (final t in tools) {
            switch (_certStatus(certMap[t.id])) {
              case CalibrationStatus.calibrated:    calibrated++;    break;
              case CalibrationStatus.dueSoon:       dueSoon++;       break;
              case CalibrationStatus.overdue:       overdue++;       break;
              case CalibrationStatus.notCalibrated: notCalibrated++; break;
            }
          }
          final scheduledCount = schedules.where((s) => s.status == 'Scheduled').length;

          List<Tool> filtered = tools;
          if (_filter == 'Scheduled') {
            final ids = schedules.where((s) => s.status == 'Scheduled').map((s) => s.toolId).toSet();
            filtered = tools.where((t) => ids.contains(t.id)).toList();
          } else if (_filter != 'All') {
            filtered = tools.where((t) => _statusLabel(_certStatus(certMap[t.id])) == _filter).toList();
          }

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered.where((t) {
              final cert = certMap[t.id];
              return t.name.toLowerCase().contains(q) ||
                  (t.category?.toLowerCase().contains(q) ?? false) ||
                  (t.serialNumber?.toLowerCase().contains(q) ?? false) ||
                  (cert?.certificationNumber.toLowerCase().contains(q) ?? false);
            }).toList();
          }

          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            color: AppTheme.secondaryColor,
            child: CustomScrollView(
              slivers: [
                // ── Inline header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).maybePop(),
                              child: const Icon(Icons.chevron_left, size: 28),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Calibration',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _showRecordDialog(context, null, provider),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Record', style: TextStyle(fontSize: 13)),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tools.length} tools tracked',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        Row(children: [
                          _SummaryCard(label: 'Calibrated', count: calibrated,    color: const Color(0xFF10B981), icon: Icons.check_circle_outline),
                          const SizedBox(width: 12),
                          _SummaryCard(label: 'Due Soon',   count: dueSoon,       color: const Color(0xFFF59E0B), icon: Icons.warning_amber_outlined),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _SummaryCard(label: 'Overdue',        count: overdue,       color: const Color(0xFFEF4444), icon: Icons.cancel_outlined),
                          const SizedBox(width: 12),
                          _SummaryCard(label: 'Not Calibrated', count: notCalibrated, color: const Color(0xFF9CA3AF), icon: Icons.radio_button_unchecked),
                        ]),
                      ],
                    ),
                  ),
                ),

                // Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: context.chatGPTInputDecoration.copyWith(
                        hintText: 'Search tools...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF6B7280)),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () { _searchController.clear(); setState(() => _search = ''); },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Filter chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      children: [
                        for (final f in ['All', 'Calibrated', 'Due Soon', 'Overdue', 'Not Calibrated', 'Scheduled'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: f == 'All' ? 'All Tools' : f,
                              badge: f == 'All' ? tools.length
                                  : f == 'Calibrated' ? calibrated
                                  : f == 'Due Soon' ? dueSoon
                                  : f == 'Overdue' ? overdue
                                  : f == 'Not Calibrated' ? notCalibrated
                                  : scheduledCount,
                              selected: _filter == f,
                              onTap: () => setState(() => _filter = f),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Tool list
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      title: 'No tools found',
                      subtitle: _search.isNotEmpty ? 'No tools match your search' : 'No tools in this category',
                      icon: Icons.build_circle_outlined,
                      actionText: 'Clear Filter',
                      onAction: () => setState(() { _filter = 'All'; _search = ''; _searchController.clear(); }),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final tool = filtered[i];
                          final cert = certMap[tool.id];
                          final status = _certStatus(cert);
                          final toolSchedules = schedules.where((s) => s.toolId == tool.id && s.status == 'Scheduled').toList();
                          return _CalibrationToolCard(
                            tool: tool,
                            cert: cert,
                            status: status,
                            scheduledCount: toolSchedules.length,
                            onRecord: () => _showRecordDialog(context, tool, provider),
                            onSchedule: () => _showScheduleDialog(context, tool, provider),
                            onEdit: cert != null ? () => _showEditDialog(context, cert, provider) : null,
                            onDelete: cert != null ? () => _confirmDelete(context, cert, provider) : null,
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }


  void _showRecordDialog(BuildContext context, Tool? preselectedTool, SupabaseCertificationProvider provider) {
    final tools = widget.filterUserId != null
        ? provider.tools.where((t) => t.assignedTo == widget.filterUserId).toList()
        : provider.tools;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalibrationFormSheet(
        tools: tools,
        preselectedTool: preselectedTool,
        onSubmit: (cert) async {
          final created = await provider.addCertification(cert);
          if (context.mounted) {
            Navigator.pop(context);
            if (created != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Calibration recorded'), backgroundColor: AppTheme.successColor),
              );
            }
          }
        },
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, Tool tool, SupabaseCertificationProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFormSheet(
        tool: tool,
        onSubmit: (schedule) async {
          final created = await provider.addCalibrationSchedule(schedule);
          if (context.mounted) {
            Navigator.pop(context);
            if (created != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Calibration scheduled'), backgroundColor: AppTheme.successColor),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Certification cert, SupabaseCertificationProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalibrationEditSheet(
        cert: cert,
        onSubmit: (updates) async {
          final updated = await provider.updateCertification(cert.id!, updates);
          if (context.mounted) {
            Navigator.pop(context);
            if (updated != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Calibration updated'), backgroundColor: AppTheme.successColor),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Certification cert, SupabaseCertificationProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Calibration'),
        content: Text('Delete certificate ${cert.certificationNumber} for ${cert.toolName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.deleteCertification(cert.id!);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Calibration record deleted'), backgroundColor: AppTheme.errorColor),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Tool Card ───────────────────────────────────────────────────────────────

class _CalibrationToolCard extends StatelessWidget {
  final Tool tool;
  final Certification? cert;
  final CalibrationStatus status;
  final int scheduledCount;
  final VoidCallback onRecord;
  final VoidCallback onSchedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CalibrationToolCard({
    required this.tool, required this.cert, required this.status,
    required this.scheduledCount, required this.onRecord, required this.onSchedule,
    this.onEdit, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.build_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.colorScheme.onSurface)),
                      Text(tool.category ?? '', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(_statusLabel(status), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            if (cert != null) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: context.cardBorder),
              const SizedBox(height: 10),
              _InfoRow('Certificate #', cert!.certificationNumber),
              _InfoRow('Issued by', cert!.issuingAuthority),
              _InfoRow('Issue date', _fmt(cert!.issueDate)),
              _InfoRow('Expiry', '${_fmt(cert!.expiryDate)} (${cert!.expiryStatus})'),
              if (cert!.inspectorName != null) _InfoRow('Inspector', cert!.inspectorName!),
            ] else ...[
              const SizedBox(height: 8),
              Text('No calibration certificate on record',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontStyle: FontStyle.italic)),
            ],

            if (scheduledCount > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 13, color: AppTheme.secondaryColor),
                  const SizedBox(width: 4),
                  Text('$scheduledCount calibration${scheduledCount > 1 ? 's' : ''} scheduled',
                      style: TextStyle(fontSize: 12, color: AppTheme.secondaryColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(icon: Icons.verified_outlined, label: 'Record', onTap: onRecord),
                const SizedBox(width: 8),
                _ActionButton(icon: Icons.event_outlined, label: 'Schedule', onTap: onSchedule),
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, size: 18, color: AppTheme.secondaryColor),
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    tooltip: 'Delete',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.secondaryColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.secondaryColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.badge, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.secondaryColor
              : (Theme.of(context).brightness == Brightness.dark ? theme.colorScheme.onSurface.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.25) : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$badge', style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Record Calibration Form ──────────────────────────────────────────────────

class _CalibrationFormSheet extends StatefulWidget {
  final List<Tool> tools;
  final Tool? preselectedTool;
  final Future<void> Function(Certification) onSubmit;
  const _CalibrationFormSheet({required this.tools, this.preselectedTool, required this.onSubmit});

  @override
  State<_CalibrationFormSheet> createState() => _CalibrationFormSheetState();
}

class _CalibrationFormSheetState extends State<_CalibrationFormSheet> {
  Tool? _selectedTool;
  final _certNumCtrl   = TextEditingController();
  final _authorityCtrl = TextEditingController(text: 'Dubai Municipality');
  final _inspectorCtrl = TextEditingController();
  final _notesCtrl     = TextEditingController();
  DateTime _issueDate  = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedTool = widget.preselectedTool ?? (widget.tools.isNotEmpty ? widget.tools.first : null);
    _certNumCtrl.text = 'CAL-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _certNumCtrl.dispose(); _authorityCtrl.dispose(); _inspectorCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Record Calibration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(color: onSurface.withValues(alpha: 0.08)),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Tool search
                  Autocomplete<Tool>(
                    initialValue: TextEditingValue(text: _selectedTool?.name ?? ''),
                    displayStringForOption: (t) => t.name,
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return widget.tools;
                      final q = v.text.toLowerCase();
                      return widget.tools.where((t) =>
                        t.name.toLowerCase().contains(q) ||
                        (t.category?.toLowerCase().contains(q) ?? false));
                    },
                    onSelected: (t) => setState(() => _selectedTool = t),
                    fieldViewBuilder: (_, ctrl, fn, onSubmit) => TextFormField(
                      controller: ctrl,
                      focusNode: fn,
                      onFieldSubmitted: (_) => onSubmit(),
                      decoration: context.chatGPTInputDecoration.copyWith(
                        labelText: 'Tool *',
                        hintText: 'Search by name or category...',
                        prefixIcon: const Icon(Icons.handyman_outlined, size: 20, color: Color(0xFF6366F1)),
                        suffixIcon: const Icon(Icons.search, size: 20),
                      ),
                      style: TextStyle(color: onSurface),
                    ),
                    optionsViewBuilder: (_, onSelected, options) => _ToolSuggestionsList(
                      options: options, onSelected: onSelected,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _certNumCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Certificate Number *',
                      prefixIcon: const Icon(Icons.tag_outlined, size: 20, color: Color(0xFF0EA5E9)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _authorityCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Issuing Authority *',
                      prefixIcon: const Icon(Icons.business_outlined, size: 20, color: Color(0xFF10B981)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _inspectorCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Inspector Name',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFFF59E0B)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: _issueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _issueDate = p);
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(text: _fmtDate(_issueDate)),
                              decoration: context.chatGPTInputDecoration.copyWith(
                                labelText: 'Issue Date *',
                                prefixIcon: const Icon(Icons.event_outlined, size: 20, color: Color(0xFFF59E0B)),
                              ),
                              style: TextStyle(color: onSurface),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _expiryDate = p);
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(text: _fmtDate(_expiryDate)),
                              decoration: context.chatGPTInputDecoration.copyWith(
                                labelText: 'Expiry Date *',
                                prefixIcon: const Icon(Icons.event_busy_outlined, size: 20, color: Color(0xFFEF4444)),
                              ),
                              style: TextStyle(color: onSurface),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Notes',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF6B7280)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving || _selectedTool == null || _certNumCtrl.text.isEmpty ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Record Calibration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedTool == null) return;
    setState(() => _saving = true);
    final cert = Certification(
      toolId: _selectedTool!.id!,
      toolName: _selectedTool!.name,
      certificationType: 'Calibration Certificate',
      certificationNumber: _certNumCtrl.text.trim(),
      issuingAuthority: _authorityCtrl.text.trim(),
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      status: 'Valid',
      inspectorName: _inspectorCtrl.text.trim().isEmpty ? null : _inspectorCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await widget.onSubmit(cert);
  }
}

// ─── Schedule Calibration Form ────────────────────────────────────────────────

class _ScheduleFormSheet extends StatefulWidget {
  final Tool tool;
  final Future<void> Function(MaintenanceSchedule) onSubmit;
  const _ScheduleFormSheet({required this.tool, required this.onSubmit});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 90));
  int _intervalDays = 90;
  String _priority = 'High';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule Calibration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface)),
                      Text(widget.tool.name, style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(color: onSurface.withValues(alpha: 0.08)),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(context: context, initialDate: _scheduledDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (p != null) setState(() => _scheduledDate = p);
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: _fmtDate(_scheduledDate)),
                        decoration: context.chatGPTInputDecoration.copyWith(
                          labelText: 'Scheduled Date *',
                          prefixIcon: const Icon(Icons.event_outlined, size: 20, color: Color(0xFFF59E0B)),
                        ),
                        style: TextStyle(color: onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _intervalDays,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Interval',
                      prefixIcon: const Icon(Icons.repeat_outlined, size: 20, color: Color(0xFF8B5CF6)),
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: onSurface, fontSize: 14),
                    borderRadius: BorderRadius.circular(16),
                    items: [30, 60, 90, 180, 365].map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                    onChanged: (v) => setState(() => _intervalDays = v!),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Priority',
                      prefixIcon: const Icon(Icons.flag_outlined, size: 20, color: Color(0xFFEF4444)),
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: onSurface, fontSize: 14),
                    borderRadius: BorderRadius.circular(16),
                    items: ['Low', 'Medium', 'High', 'Critical'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Notes',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF6B7280)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Schedule Calibration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final schedule = MaintenanceSchedule(
      toolId: widget.tool.id!,
      toolName: widget.tool.name,
      maintenanceType: 'Calibration',
      description: 'Scheduled calibration for ${widget.tool.name}',
      scheduledDate: _scheduledDate,
      status: 'Scheduled',
      priority: _priority,
      intervalDays: _intervalDays,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await widget.onSubmit(schedule);
  }
}

// ─── Edit Calibration Form ────────────────────────────────────────────────────

class _CalibrationEditSheet extends StatefulWidget {
  final Certification cert;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  const _CalibrationEditSheet({required this.cert, required this.onSubmit});

  @override
  State<_CalibrationEditSheet> createState() => _CalibrationEditSheetState();
}

class _CalibrationEditSheetState extends State<_CalibrationEditSheet> {
  late final TextEditingController _certNumCtrl;
  late final TextEditingController _authorityCtrl;
  late final TextEditingController _inspectorCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _issueDate;
  late DateTime _expiryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _certNumCtrl   = TextEditingController(text: widget.cert.certificationNumber);
    _authorityCtrl = TextEditingController(text: widget.cert.issuingAuthority);
    _inspectorCtrl = TextEditingController(text: widget.cert.inspectorName ?? '');
    _notesCtrl     = TextEditingController(text: widget.cert.notes ?? '');
    _issueDate     = widget.cert.issueDate;
    _expiryDate    = widget.cert.expiryDate;
  }

  @override
  void dispose() {
    _certNumCtrl.dispose(); _authorityCtrl.dispose(); _inspectorCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Calibration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface)),
                      Text(widget.cert.toolName, style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(color: onSurface.withValues(alpha: 0.08)),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  TextField(
                    controller: _certNumCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Certificate Number *',
                      prefixIcon: const Icon(Icons.tag_outlined, size: 20, color: Color(0xFF0EA5E9)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _authorityCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Issuing Authority *',
                      prefixIcon: const Icon(Icons.business_outlined, size: 20, color: Color(0xFF10B981)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _inspectorCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Inspector Name',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFFF59E0B)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: _issueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _issueDate = p);
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(text: _fmtDate(_issueDate)),
                              decoration: context.chatGPTInputDecoration.copyWith(
                                labelText: 'Issue Date',
                                prefixIcon: const Icon(Icons.event_outlined, size: 20, color: Color(0xFFF59E0B)),
                              ),
                              style: TextStyle(color: onSurface),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _expiryDate = p);
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(text: _fmtDate(_expiryDate)),
                              decoration: context.chatGPTInputDecoration.copyWith(
                                labelText: 'Expiry Date',
                                prefixIcon: const Icon(Icons.event_busy_outlined, size: 20, color: Color(0xFFEF4444)),
                              ),
                              style: TextStyle(color: onSurface),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Notes',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF6B7280)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving || _certNumCtrl.text.isEmpty ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    await widget.onSubmit({
      'certification_number': _certNumCtrl.text.trim(),
      'issuing_authority': _authorityCtrl.text.trim(),
      'inspector_name': _inspectorCtrl.text.trim().isEmpty ? null : _inspectorCtrl.text.trim(),
      'issue_date': _issueDate.toIso8601String(),
      'expiry_date': _expiryDate.toIso8601String(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    });
  }
}


// ─── Shared: Tool suggestions overlay ────────────────────────────────────────

class _ToolSuggestionsList extends StatelessWidget {
  final Iterable<Tool> options;
  final void Function(Tool) onSelected;
  const _ToolSuggestionsList({required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (_, i) {
              final tool = options.elementAt(i);
              return InkWell(
                onTap: () => onSelected(tool),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.handyman_outlined, size: 16, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tool.name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                            if (tool.category != null)
                              Text(tool.category!,
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
