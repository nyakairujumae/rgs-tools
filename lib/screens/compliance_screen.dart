import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/certification.dart';
import '../models/tool.dart';
import '../providers/supabase_certification_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
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
      appBar: AppBar(
        title: const Text('Compliance & Certifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: AppTheme.secondaryColor,
            onPressed: () => _showAddDialog(context, context.read<SupabaseCertificationProvider>()),
          ),
        ],
      ),
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

          final certs = provider.complianceCerts;

          // Counts
          final validCount = certs.where((c) => c.isValid && !c.isExpiringSoon).length;
          final expiringCount = certs.where((c) => c.isExpiringSoon).length;
          final expiredCount = certs.where((c) => c.isExpired).length;
          final revokedCount = certs.where((c) => c.status == 'Revoked').length;

          // Filter
          List<Certification> filtered;
          switch (_filter) {
            case 'Valid':       filtered = certs.where((c) => c.isValid && !c.isExpiringSoon).toList(); break;
            case 'Expiring':    filtered = certs.where((c) => c.isExpiringSoon).toList(); break;
            case 'Expired':     filtered = certs.where((c) => c.isExpired).toList(); break;
            case 'Revoked':     filtered = certs.where((c) => c.status == 'Revoked').toList(); break;
            default:            filtered = certs;
          }

          // Search
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered.where((c) =>
              c.toolName.toLowerCase().contains(q) ||
              c.certificationNumber.toLowerCase().contains(q) ||
              c.issuingAuthority.toLowerCase().contains(q) ||
              c.certificationType.toLowerCase().contains(q)
            ).toList();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: CustomScrollView(
              slivers: [
                // Overview cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StatCard(label: 'Valid', count: validCount, color: const Color(0xFF10B981), icon: Icons.check_circle),
                            const SizedBox(width: 12),
                            _StatCard(label: 'Expiring Soon', count: expiringCount, color: const Color(0xFFF59E0B), icon: Icons.warning_amber),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatCard(label: 'Expired', count: expiredCount, color: const Color(0xFFEF4444), icon: Icons.cancel),
                            const SizedBox(width: 12),
                            _StatCard(label: 'Total', count: certs.length, color: AppTheme.secondaryColor, icon: Icons.assignment),
                          ],
                        ),
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
                      decoration: InputDecoration(
                        hintText: 'Search certifications...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () { _searchController.clear(); setState(() => _search = ''); },
                              )
                            : null,
                        filled: true,
                        fillColor: context.cardBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.secondaryColor)),
                      ),
                    ),
                  ),
                ),

                // Filter tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final entry in {
                            'All': certs.length,
                            'Valid': validCount,
                            'Expiring': expiringCount,
                            'Expired': expiredCount,
                            'Revoked': revokedCount,
                          }.entries)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: entry.key == 'Expiring' ? 'Expiring Soon' : entry.key,
                                badge: entry.value,
                                selected: _filter == entry.key,
                                onTap: () => setState(() => _filter = entry.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // List
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      title: 'No certifications found',
                      subtitle: _search.isNotEmpty ? 'No results match your search' : 'Add a certification to get started',
                      icon: Icons.assignment_outlined,
                      actionText: 'Add Certification',
                      onAction: () => _showAddDialog(context, provider),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _CertCard(
                          cert: filtered[i],
                          onEdit: () => _showEditDialog(context, filtered[i], provider),
                          onDelete: () => _confirmDelete(context, filtered[i], provider),
                        ),
                        childCount: filtered.length,
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

  void _showAddDialog(BuildContext context, SupabaseCertificationProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CertFormSheet(
        tools: provider.tools,
        onSubmit: (cert) async {
          final created = await provider.addCertification(cert);
          if (context.mounted) {
            Navigator.pop(context);
            if (created != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Certification added'), backgroundColor: AppTheme.successColor),
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
      builder: (_) => _CertEditSheet(
        cert: cert,
        tools: provider.tools,
        onSubmit: (updates) async {
          final updated = await provider.updateCertification(cert.id!, updates);
          if (context.mounted) {
            Navigator.pop(context);
            if (updated != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Certification updated'), backgroundColor: AppTheme.successColor),
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
        title: const Text('Delete Certification'),
        content: Text('Delete ${cert.certificationNumber} for ${cert.toolName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.deleteCertification(cert.id!);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Certification deleted'), backgroundColor: AppTheme.errorColor),
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

// ─── Cert Card ────────────────────────────────────────────────────────────────

class _CertCard extends StatelessWidget {
  final Certification cert;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CertCard({required this.cert, required this.onEdit, required this.onDelete});

  Color get _color {
    if (cert.status == 'Revoked') return const Color(0xFF9CA3AF);
    if (cert.isExpired) return const Color(0xFFEF4444);
    if (cert.isExpiringSoon) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get _statusLabel {
    if (cert.status == 'Revoked') return 'Revoked';
    if (cert.isExpired) return 'Expired';
    if (cert.isExpiringSoon) return 'Expiring Soon';
    return 'Valid';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.verified_outlined, color: _color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert.toolName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(cert.certificationType, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusLabel, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _Row('Certificate #', cert.certificationNumber),
            _Row('Issued by', cert.issuingAuthority),
            _Row('Issue date', _fmt(cert.issueDate)),
            _Row('Expiry', '${_fmt(cert.expiryDate)}  •  ${cert.expiryStatus}'),
            if (cert.inspectorName != null) _Row('Inspector', cert.inspectorName!),
            if (cert.location != null) _Row('Location', cert.location!),
            if (cert.notes != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(cert.notes!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2128) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF2D3139) : const Color(0xFFE8EAED)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondaryColor.withOpacity(0.1) : context.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.secondaryColor : Colors.black.withOpacity(0.08), width: selected ? 1.2 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppTheme.secondaryColor : AppTheme.textSecondary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: selected ? AppTheme.secondaryColor : Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', style: TextStyle(fontSize: 10, color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Certification Form ───────────────────────────────────────────────────

class _CertFormSheet extends StatefulWidget {
  final List<Tool> tools;
  final Future<void> Function(Certification) onSubmit;
  const _CertFormSheet({required this.tools, required this.onSubmit});

  @override
  State<_CertFormSheet> createState() => _CertFormSheetState();
}

class _CertFormSheetState extends State<_CertFormSheet> {
  Tool? _tool;
  String _type = 'Safety Inspection';
  final _certNumCtrl = TextEditingController();
  final _authorityCtrl = TextEditingController();
  final _inspectorCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tool = widget.tools.isNotEmpty ? widget.tools.first : null;
    _certNumCtrl.text = 'CERT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000}';
    _authorityCtrl.text = CertificationTypes.defaultAuthorities[_type] ?? '';
  }

  @override
  void dispose() {
    _certNumCtrl.dispose(); _authorityCtrl.dispose(); _inspectorCtrl.dispose();
    _locationCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Add Certification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _Lbl('Tool *'),
                  DropdownButtonFormField<Tool>(
                    value: _tool,
                    decoration: _dec(),
                    items: widget.tools.map((t) => DropdownMenuItem(value: t, child: Text(t.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (t) => setState(() => _tool = t),
                  ),
                  const SizedBox(height: 14),

                  _Lbl('Certification Type *'),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: _dec(),
                    items: CertificationTypes.types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (t) {
                      setState(() {
                        _type = t!;
                        _authorityCtrl.text = CertificationTypes.defaultAuthorities[_type] ?? '';
                        final validity = CertificationTypes.defaultValidityPeriods[_type] ?? 365;
                        _expiryDate = _issueDate.add(Duration(days: validity));
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  _Lbl('Certificate Number *'),
                  TextField(controller: _certNumCtrl, decoration: _dec()),
                  const SizedBox(height: 14),

                  _Lbl('Issuing Authority *'),
                  TextField(controller: _authorityCtrl, decoration: _dec()),
                  const SizedBox(height: 14),

                  _Lbl('Inspector Name'),
                  TextField(controller: _inspectorCtrl, decoration: _dec(hint: 'Optional')),
                  const SizedBox(height: 14),

                  _Lbl('Location'),
                  TextField(controller: _locationCtrl, decoration: _dec(hint: 'Optional')),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Lbl('Issue Date *'),
                          _DatePicker(date: _issueDate, onPick: () async {
                            final p = await showDatePicker(context: context, initialDate: _issueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _issueDate = p);
                          }),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Lbl('Expiry Date *'),
                          _DatePicker(date: _expiryDate, onPick: () async {
                            final p = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                            if (p != null) setState(() => _expiryDate = p);
                          }),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _Lbl('Notes'),
                  TextField(controller: _notesCtrl, maxLines: 2, decoration: _dec(hint: 'Optional')),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving || _tool == null || _certNumCtrl.text.isEmpty ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Add Certification', style: TextStyle(fontWeight: FontWeight.w600)),
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
    if (_tool == null) return;
    setState(() => _saving = true);
    final cert = Certification(
      toolId: _tool!.id!,
      toolName: _tool!.name,
      certificationType: _type,
      certificationNumber: _certNumCtrl.text.trim(),
      issuingAuthority: _authorityCtrl.text.trim(),
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      status: 'Valid',
      inspectorName: _inspectorCtrl.text.trim().isEmpty ? null : _inspectorCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await widget.onSubmit(cert);
  }

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.primaryColor)),
      );
}

// ─── Edit Certification Form ──────────────────────────────────────────────────

class _CertEditSheet extends StatefulWidget {
  final Certification cert;
  final List<Tool> tools;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  const _CertEditSheet({required this.cert, required this.tools, required this.onSubmit});

  @override
  State<_CertEditSheet> createState() => _CertEditSheetState();
}

class _CertEditSheetState extends State<_CertEditSheet> {
  late final TextEditingController _certNumCtrl;
  late final TextEditingController _authorityCtrl;
  late final TextEditingController _inspectorCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _issueDate;
  late DateTime _expiryDate;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _certNumCtrl = TextEditingController(text: widget.cert.certificationNumber);
    _authorityCtrl = TextEditingController(text: widget.cert.issuingAuthority);
    _inspectorCtrl = TextEditingController(text: widget.cert.inspectorName ?? '');
    _locationCtrl = TextEditingController(text: widget.cert.location ?? '');
    _notesCtrl = TextEditingController(text: widget.cert.notes ?? '');
    _issueDate = widget.cert.issueDate;
    _expiryDate = widget.cert.expiryDate;
    _status = widget.cert.status;
  }

  @override
  void dispose() {
    _certNumCtrl.dispose(); _authorityCtrl.dispose(); _inspectorCtrl.dispose();
    _locationCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Certification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(widget.cert.toolName, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _Lbl('Certificate Number *'),
                  TextField(controller: _certNumCtrl, decoration: _dec()),
                  const SizedBox(height: 14),

                  _Lbl('Issuing Authority *'),
                  TextField(controller: _authorityCtrl, decoration: _dec()),
                  const SizedBox(height: 14),

                  _Lbl('Status'),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _dec(),
                    items: ['Valid', 'Revoked'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 14),

                  _Lbl('Inspector Name'),
                  TextField(controller: _inspectorCtrl, decoration: _dec(hint: 'Optional')),
                  const SizedBox(height: 14),

                  _Lbl('Location'),
                  TextField(controller: _locationCtrl, decoration: _dec(hint: 'Optional')),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Lbl('Issue Date'),
                          _DatePicker(date: _issueDate, onPick: () async {
                            final p = await showDatePicker(context: context, initialDate: _issueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _issueDate = p);
                          }),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Lbl('Expiry Date'),
                          _DatePicker(date: _expiryDate, onPick: () async {
                            final p = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                            if (p != null) setState(() => _expiryDate = p);
                          }),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _Lbl('Notes'),
                  TextField(controller: _notesCtrl, maxLines: 2, decoration: _dec(hint: 'Optional')),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving || _certNumCtrl.text.isEmpty ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
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
      'status': _status,
      'inspector_name': _inspectorCtrl.text.trim().isEmpty ? null : _inspectorCtrl.text.trim(),
      'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'issue_date': _issueDate.toIso8601String(),
      'expiry_date': _expiryDate.toIso8601String(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    });
  }

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.primaryColor)),
      );
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _Lbl(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
);

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPick;
  const _DatePicker({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14),
            const SizedBox(width: 8),
            Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
