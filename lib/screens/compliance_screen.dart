import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/certification.dart';
import '../models/tool.dart';
import '../providers/supabase_certification_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/empty_state.dart';

class ComplianceScreen extends StatefulWidget {
  /// When set, only shows certs for tools assigned to this user (technician view).
  final String? filterUserId;

  const ComplianceScreen({super.key, this.filterUserId});

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

          final _myToolIds = widget.filterUserId != null
              ? provider.tools
                  .where((t) => t.assignedTo == widget.filterUserId)
                  .map((t) => t.id)
                  .whereType<String>()
                  .toSet()
              : null;
          final certs = _myToolIds != null
              ? provider.complianceCerts
                  .where((c) => _myToolIds.contains(c.toolId))
                  .toList()
              : provider.complianceCerts;
          final validCount    = certs.where((c) => c.isValid && !c.isExpiringSoon).length;
          final expiringCount = certs.where((c) => c.isExpiringSoon).length;
          final expiredCount  = certs.where((c) => c.isExpired).length;
          final revokedCount  = certs.where((c) => c.status == 'Revoked').length;

          List<Certification> filtered;
          switch (_filter) {
            case 'Valid':    filtered = certs.where((c) => c.isValid && !c.isExpiringSoon).toList(); break;
            case 'Expiring': filtered = certs.where((c) => c.isExpiringSoon).toList(); break;
            case 'Expired':  filtered = certs.where((c) => c.isExpired).toList(); break;
            case 'Revoked':  filtered = certs.where((c) => c.status == 'Revoked').toList(); break;
            default:         filtered = certs;
          }

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered.where((c) =>
              c.toolName.toLowerCase().contains(q) ||
              c.certificationNumber.toLowerCase().contains(q) ||
              c.issuingAuthority.toLowerCase().contains(q) ||
              c.certificationType.toLowerCase().contains(q)
            ).toList();
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
                                'Compliance',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _showAddDialog(context, provider),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add', style: TextStyle(fontSize: 13)),
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
                          '${certs.length} certifications',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stat cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        Row(children: [
                          _StatCard(label: 'Valid',         count: validCount,    color: const Color(0xFF10B981), icon: Icons.check_circle_outline),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Expiring Soon', count: expiringCount, color: const Color(0xFFF59E0B), icon: Icons.warning_amber_outlined),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _StatCard(label: 'Expired', count: expiredCount,  color: const Color(0xFFEF4444), icon: Icons.cancel_outlined),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Total',   count: certs.length,  color: AppTheme.secondaryColor, icon: Icons.assignment_outlined),
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
                        hintText: 'Search certifications...',
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
          ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, SupabaseCertificationProvider provider) {
    final myTools = widget.filterUserId != null
        ? provider.tools.where((t) => t.assignedTo == widget.filterUserId).toList()
        : provider.tools;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CertFormSheet(
        tools: myTools,
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
    final myTools = widget.filterUserId != null
        ? provider.tools.where((t) => t.assignedTo == widget.filterUserId).toList()
        : provider.tools;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CertEditSheet(
        cert: cert,
        tools: myTools,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
    final theme = Theme.of(context);
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
                  decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.verified_outlined, color: _color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert.toolName,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.colorScheme.onSurface)),
                      Text(cert.certificationType,
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(_statusLabel, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: context.cardBorder),
            const SizedBox(height: 10),
            _InfoRow('Certificate #', cert.certificationNumber),
            _InfoRow('Issued by', cert.issuingAuthority),
            _InfoRow('Issue date', _fmt(cert.issueDate)),
            _InfoRow('Expiry', '${_fmt(cert.expiryDate)}  •  ${cert.expiryStatus}'),
            if (cert.inspectorName != null) _InfoRow('Inspector', cert.inspectorName!),
            if (cert.location != null) _InfoRow('Location', cert.location!),
            if (cert.notes != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(cert.notes!,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
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
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))),
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
  final _certNumCtrl   = TextEditingController();
  final _authorityCtrl = TextEditingController();
  final _inspectorCtrl = TextEditingController();
  final _locationCtrl  = TextEditingController();
  final _notesCtrl     = TextEditingController();
  DateTime _issueDate  = DateTime.now();
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

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                  Text('Add Certification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface)),
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
                    initialValue: TextEditingValue(text: _tool?.name ?? ''),
                    displayStringForOption: (t) => t.name,
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return widget.tools;
                      final q = v.text.toLowerCase();
                      return widget.tools.where((t) =>
                        t.name.toLowerCase().contains(q) ||
                        (t.category?.toLowerCase().contains(q) ?? false));
                    },
                    onSelected: (t) => setState(() => _tool = t),
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

                  // Certification Type
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Certification Type *',
                      prefixIcon: const Icon(Icons.verified_outlined, size: 20, color: Color(0xFF8B5CF6)),
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: onSurface, fontSize: 14),
                    borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 16),

                  // Certificate Number
                  TextField(
                    controller: _certNumCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Certificate Number *',
                      prefixIcon: const Icon(Icons.tag_outlined, size: 20, color: Color(0xFF0EA5E9)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  // Issuing Authority
                  TextField(
                    controller: _authorityCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Issuing Authority *',
                      prefixIcon: const Icon(Icons.business_outlined, size: 20, color: Color(0xFF10B981)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  // Inspector Name
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

                  // Location
                  TextField(
                    controller: _locationCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Location',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.place_outlined, size: 20, color: Color(0xFFEF4444)),
                    ),
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 16),

                  // Dates row
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
                            final p = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
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

                  // Notes
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
                      onPressed: _saving || _tool == null || _certNumCtrl.text.isEmpty ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Add Certification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
    _certNumCtrl   = TextEditingController(text: widget.cert.certificationNumber);
    _authorityCtrl = TextEditingController(text: widget.cert.issuingAuthority);
    _inspectorCtrl = TextEditingController(text: widget.cert.inspectorName ?? '');
    _locationCtrl  = TextEditingController(text: widget.cert.location ?? '');
    _notesCtrl     = TextEditingController(text: widget.cert.notes ?? '');
    _issueDate     = widget.cert.issueDate;
    _expiryDate    = widget.cert.expiryDate;
    _status        = widget.cert.status;
  }

  @override
  void dispose() {
    _certNumCtrl.dispose(); _authorityCtrl.dispose(); _inspectorCtrl.dispose();
    _locationCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                      Text('Edit Certification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface)),
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

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.toggle_on_outlined, size: 20, color: Color(0xFF3B82F6)),
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: onSurface, fontSize: 14),
                    borderRadius: BorderRadius.circular(16),
                    items: ['Valid', 'Revoked'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
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

                  TextField(
                    controller: _locationCtrl,
                    decoration: context.chatGPTInputDecoration.copyWith(
                      labelText: 'Location',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.place_outlined, size: 20, color: Color(0xFFEF4444)),
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
                            final p = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
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
      'status': _status,
      'inspector_name': _inspectorCtrl.text.trim().isEmpty ? null : _inspectorCtrl.text.trim(),
      'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
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
