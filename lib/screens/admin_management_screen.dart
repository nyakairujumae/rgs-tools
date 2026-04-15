import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/admin_position.dart';
import '../providers/auth_provider.dart';
import '../services/admin_position_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/logger.dart';
import '../utils/navigation_helper.dart';
import '../utils/responsive_helper.dart';
import 'add_admin_screen.dart';

/// Admin list — layout aligned with web `dashboard/admin-management`:
/// header + stats row + table in a card (horizontal scroll on narrow widths).
class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<Map<String, dynamic>> _admins = [];
  Map<String, AdminPosition> _positionsById = {};
  bool _canManageAdmins = false;
  bool _dataLoaded = false;
  bool _permissionLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAdmins(),
      _loadPermissions(),
    ]);
  }

  Future<void> _loadPermissions() async {
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _canManageAdmins = false;
          _permissionLoaded = true;
        });
        return;
      }
      final canManageAdmins =
          await AdminPositionService.userCanManageAdmins(userId);
      if (!mounted) return;
      setState(() {
        _canManageAdmins = canManageAdmins;
        _permissionLoaded = true;
      });
    } catch (e) {
      Logger.debug('❌ Error loading admin permissions: $e');
      if (!mounted) return;
      setState(() {
        _permissionLoaded = true;
      });
    }
  }

  Future<void> _loadAdmins() async {
    try {
      final positions = await AdminPositionService.getAllPositions();
      final positionsById = <String, AdminPosition>{};
      for (final position in positions) {
        positionsById[position.id] = position;
      }

      final response = await SupabaseService.client
          .from('users')
          .select('id, email, full_name, role, position_id, status, created_at')
          .eq('role', 'admin')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _positionsById = positionsById;
        _admins = List<Map<String, dynamic>>.from(response);
        _dataLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  int get _activeCount => _admins.where((a) {
        final s = a['status']?.toString().trim() ?? '';
        return s.isEmpty || s == 'Active';
      }).length;

  Future<void> _openAddAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAdminScreen(),
      ),
    );
    if (!mounted) return;
    await _loadAdmins();
  }

  Future<void> _openEditAdmin(Map<String, dynamic> admin) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdminScreen(existingAdmin: admin),
      ),
    );
    if (!mounted) return;
    await _loadAdmins();
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    final adminId = admin['id']?.toString();
    final name = admin['full_name']?.toString() ?? 'Admin';
    if (adminId == null) return;

    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(l10n.adminManagement_removeAdmin),
        content: Text(
          '${l10n.adminManagement_removeConfirm(name)}\n\n'
          '${l10n.adminManagement_removeNote}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _admins.removeWhere((a) => a['id']?.toString() == adminId);
      });

      await SupabaseService.client.from('users').delete().eq('id', adminId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminManagement_removed(name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      await _loadAdmins();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.adminManagement_removeFailed}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _positionName(String? positionId) {
    if (positionId == null || positionId.isEmpty) return 'No Position';
    return _positionsById[positionId]?.name ?? 'Unknown';
  }

  String _formatJoined(dynamic createdAt) {
    if (createdAt == null) return '—';
    DateTime? dt;
    if (createdAt is DateTime) {
      dt = createdAt;
    } else {
      dt = DateTime.tryParse(createdAt.toString());
    }
    if (dt == null) return '—';
    return MaterialLocalizations.of(context).formatShortDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.55);
    final loading = !_dataLoaded || !_permissionLoaded;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 4,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: theme.colorScheme.onSurface),
          onPressed: () => NavigationHelper.safePop(context),
        ),
        title: Text(
          'Admin Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.adminManagement_loading,
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                ],
              ),
            )
          : !_canManageAdmins
              ? _AccessRestricted(muted: muted)
              : RefreshIndicator(
                  color: AppTheme.secondaryColor,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderRow(
                          muted: muted,
                          onAdd: _openAddAdmin,
                        ),
                        const SizedBox(height: 16),
                        _StatsRow(
                          total: _admins.length,
                          active: _activeCount,
                          positions: _positionsById.length,
                        ),
                        const SizedBox(height: 16),
                        _AdminTableCard(
                          admins: _admins,
                          positionName: _positionName,
                          formatJoined: _formatJoined,
                          onEdit: _openEditAdmin,
                          onDelete: _deleteAdmin,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _AccessRestricted extends StatelessWidget {
  final Color muted;

  const _AccessRestricted({required this.muted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: context.dashboardSurfaceCardDecoration(radius: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, size: 48, color: muted),
              const SizedBox(height: 12),
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You don\'t have permission to manage administrators.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: muted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final Color muted;
  final VoidCallback onAdd;

  const _HeaderRow({
    required this.muted,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final titleBlock = Text(
      'Manage administrator accounts and positions',
      style: TextStyle(fontSize: 14, color: muted, height: 1.35),
    );

    final addButton = FilledButton.icon(
      onPressed: onAdd,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Admin', style: TextStyle(fontSize: 14)),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: addButton),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            addButton,
          ],
        );
      },
    );
  }
}

/// Same grid + compact row layout as [DashboardScreen] mobile stat cards.
class _StatsRow extends StatelessWidget {
  final int total;
  final int active;
  final int positions;

  const _StatsRow({
    required this.total,
    required this.active,
    required this.positions,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 3 : 2,
          crossAxisSpacing:
              ResponsiveHelper.getResponsiveGridSpacing(context, 10),
          mainAxisSpacing:
              ResponsiveHelper.getResponsiveGridSpacing(context, 10),
          childAspectRatio: wide ? 2.1 : 1.8,
          children: [
            _DashboardMiniStatCard(
              title: 'Total Admins',
              value: '$total',
              valueStyle: valueStyle.copyWith(color: cs.primary),
              icon: Icons.admin_panel_settings_outlined,
              accentColor: cs.primary,
            ),
            _DashboardMiniStatCard(
              title: 'Active',
              value: '$active',
              valueStyle:
                  valueStyle.copyWith(color: const Color(0xFF059669)),
              icon: Icons.check_circle_outline_rounded,
              accentColor: const Color(0xFF059669),
            ),
            _DashboardMiniStatCard(
              title: 'Positions',
              value: '$positions',
              valueStyle: valueStyle.copyWith(color: const Color(0xFF7C3AED)),
              icon: Icons.badge_outlined,
              accentColor: const Color(0xFF7C3AED),
            ),
          ],
        );
      },
    );
  }
}

/// Mirrors [DashboardScreen._buildMobileStatCardContent] (uppercase label, value, icon badge).
class _DashboardMiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle valueStyle;
  final IconData icon;
  final Color accentColor;

  const _DashboardMiniStatCard({
    required this.title,
    required this.value,
    required this.valueStyle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final iconBadge = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: accentColor, size: 16),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: context.dashboardSurfaceCardDecoration(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.45),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: valueStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          iconBadge,
        ],
      ),
    );
  }
}

class _AdminTableCard extends StatelessWidget {
  final List<Map<String, dynamic>> admins;
  final String Function(String?) positionName;
  final String Function(dynamic) formatJoined;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _AdminTableCard({
    required this.admins,
    required this.positionName,
    required this.formatJoined,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mutedHeader = cs.onSurface.withValues(alpha: 0.55);
    final headerBg = cs.onSurface.withValues(alpha: 0.04);
    final dividerColor = cs.onSurface.withValues(alpha: 0.12);

    if (admins.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: context.dashboardSurfaceCardDecoration(radius: 12),
        alignment: Alignment.center,
        child: Text(
          'No administrators found',
          style: TextStyle(fontSize: 14, color: mutedHeader),
        ),
      );
    }

    return Container(
      decoration: context.dashboardSurfaceCardDecoration(radius: 12),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mqW = MediaQuery.sizeOf(context).width;
          final cw = constraints.maxWidth;
          final safeW =
              cw.isFinite && cw > 0 ? cw : (mqW - 32).clamp(200.0, mqW);
          final minW = max(safeW, 640.0);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minW),
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 80,
                horizontalMargin: 16,
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all<Color>(headerBg),
                dividerThickness: 1,
                border: TableBorder(
                  horizontalInside: BorderSide(color: dividerColor),
                  bottom: BorderSide(color: dividerColor),
                ),
                columns: [
                  DataColumn(
                    label: Text('Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: mutedHeader)),
                  ),
                  DataColumn(
                    label: Text('Email',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: mutedHeader)),
                  ),
                  DataColumn(
                    label: Text('Position',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: mutedHeader)),
                  ),
                  DataColumn(
                    label: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: mutedHeader)),
                  ),
                  DataColumn(
                    label: Text('Joined',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: mutedHeader)),
                  ),
                  const DataColumn(label: SizedBox(width: 72)),
                ],
                rows: admins.map((admin) {
                        final name =
                            admin['full_name']?.toString() ?? 'Admin';
                        final email = admin['email']?.toString() ?? '';
                        final rawStatus = admin['status']?.toString().trim();
                        final status = (rawStatus == null || rawStatus.isEmpty)
                            ? 'Active'
                            : rawStatus;
                        final pos = positionName(
                            admin['position_id']?.toString());
                        final joined = formatJoined(admin['created_at']);
                        final initial =
                            name.isNotEmpty ? name[0].toUpperCase() : 'A';

                        return DataRow(
                          cells: [
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 140,
                                  maxWidth: 220,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.primaryColor
                                          .withValues(alpha: 0.15),
                                      foregroundColor: AppTheme.primaryColor,
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                email,
                                style: TextStyle(
                                  color: mutedHeader,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataCell(_PositionPill(name: pos)),
                            DataCell(_StatusPill(status: status)),
                            DataCell(
                              Text(
                                joined,
                                style: TextStyle(
                                  color: mutedHeader,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: cs.onSurface.withValues(alpha: 0.55),
                                    ),
                                    onPressed: () => onEdit(admin),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: cs.onSurface.withValues(alpha: 0.45),
                                    ),
                                    onPressed: () => onDelete(admin),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PositionPill extends StatelessWidget {
  final String name;

  const _PositionPill({required this.name});

  @override
  Widget build(BuildContext context) {
    final isSuper = name.toLowerCase().contains('super');
    final bg = isSuper
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFDBEAFE);
    final fg = isSuper
        ? const Color(0xFF92400E)
        : const Color(0xFF1E40AF);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgUse = dark
        ? (isSuper
            ? const Color(0xFF78350F).withValues(alpha: 0.35)
            : const Color(0xFF1E3A8A).withValues(alpha: 0.35))
        : bg;
    final fgUse = dark
        ? (isSuper ? const Color(0xFFFCD34D) : const Color(0xFF93C5FD))
        : fg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgUse,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fgUse,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == 'Active';
    final bg = active ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5);
    final fg = active ? const Color(0xFF047857) : const Color(0xFFC2410C);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgUse = dark
        ? (active
            ? const Color(0xFF064E3B).withValues(alpha: 0.4)
            : const Color(0xFF9A3412).withValues(alpha: 0.35))
        : bg;
    final fgUse = dark
        ? (active ? const Color(0xFF6EE7B7) : const Color(0xFFFDBA74))
        : fg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgUse,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fgUse,
        ),
      ),
    );
  }
}
