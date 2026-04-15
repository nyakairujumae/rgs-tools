import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../providers/auth_provider.dart';
import '../models/technician.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../widgets/common/offline_skeleton.dart';
import '../widgets/common/offline_sync_banner.dart';
import '../providers/connectivity_provider.dart';
import 'add_technician_screen.dart';
import 'technician_detail_screen.dart';
import '../utils/logger.dart';
import '../l10n/app_localizations.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  static Color _skeletonBase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF252525) : const Color(0xFFE6EAF1);
  }

  static Color _skeletonHighlight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF323232) : const Color(0xFFD8DBE0);
  }
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedDepartment = 'Department';
  Set<String> _selectedTechnicians = <String>{};
  List<String>? _selectedTools;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Check if we're coming from assign tool screen with selected tools
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedTools'] != null) {
        setState(() {
          _selectedTools = List<String>.from(args['selectedTools']);
        });
      }
      // Refresh technicians and tools to sync with database
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
      context.read<SupabaseToolProvider>().loadTools();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<SupabaseTechnicianProvider>().loadTechnicians(),
      context.read<SupabaseToolProvider>().loadTools(),
    ]);
  }

  Widget _buildTechnicianSkeletonList(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _skeletonBase(context),
      highlightColor: _skeletonHighlight(context),
      period: const Duration(milliseconds: 1400),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildTechnicianSkeletonCard(context),
      ),
    );
  }

  Widget _buildTechnicianSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: context.cardDecoration.copyWith(
        color: context.cardBackground,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _skeletonBase(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonLine(context, height: 16),
                const SizedBox(height: 6),
                _buildSkeletonLine(context, widthFactor: 0.4, height: 12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildSkeletonLine(context, widthFactor: 0.35, height: 10),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _skeletonBase(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine(BuildContext context,
      {double? widthFactor, double height = 12}) {
    return FractionallySizedBox(
      widthFactor: widthFactor ?? 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _skeletonBase(context),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SupabaseTechnicianProvider, SupabaseToolProvider, ConnectivityProvider>(
      builder: (context, technicianProvider, toolProvider, connectivityProvider, child) {
        final technicians = technicianProvider.technicians;
        final isOffline = !connectivityProvider.isOnline;

        // Get departments from unique values across technicians
        final departments = technicians
            .where((tech) => tech.department != null && tech.department!.isNotEmpty)
            .map((tech) => tech.department!)
            .toSet()
            .toList()
          ..sort();

        // Filter technicians based on search, filter, and assignment mode
        // When assigning tools, only show Active technicians
        final filteredTechnicians = technicians.where((tech) {
          // Filter by status if in assignment mode
          if (_selectedTools != null && tech.status != 'Active') {
            return false;
          }

          // Apply status/special filter
          if (_selectedFilter != 'All') {
            if (_selectedFilter == 'Active' && tech.status != 'Active')
              return false;
            if (_selectedFilter == 'Inactive' && tech.status != 'Inactive')
              return false;
            if (_selectedFilter == 'With Tools') {
              final toolCount = toolProvider.tools
                  .where((tool) => tool.assignedTo == tech.id)
                  .length;
              if (toolCount == 0) return false;
            }
            if (_selectedFilter == 'Without Tools') {
              final toolCount = toolProvider.tools
                  .where((tool) => tool.assignedTo == tech.id)
                  .length;
              if (toolCount > 0) return false;
            }
          }

          // Department filter
          if (_selectedDepartment != 'Department' &&
              tech.department != _selectedDepartment) {
            return false;
          }

          // Filter by search query
          return _searchQuery.isEmpty ||
              tech.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tech.employeeId
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false) ||
              (tech.department
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false);
        }).toList();

        return Scaffold(
          backgroundColor: context.scaffoldBackground,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_selectedTools != null) ...[
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              size: 28,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            splashRadius: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Technicians',
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  if (_selectedTools == null)
                                    FilledButton.icon(
                                      onPressed: _showAddTechnicianDialog,
                                      icon: const Icon(Icons.person_add_rounded, size: 16),
                                      label: Text('Add ${'Technician'}',
                                          style: const TextStyle(fontSize: 13)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        minimumSize: const Size(0, 36),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${filteredTechnicians.length} ${'Technicians'.toLowerCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Assignment Instructions (only show when assigning tools)
                  if (_selectedTools != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16.0),
                      decoration: context.cardDecoration.copyWith(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assign ${_selectedTools!.length} Tool${_selectedTools!.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select ${'Technicians'.toLowerCase()} to assign',
                                  style: TextStyle(
                                    fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Filter bar ───────────────────────────────────────
                  _buildFilterBar(departments),
                  const SizedBox(height: 8),

                  // Offline / sync banner
                  OfflineSyncBanner(isOffline: isOffline),

                  // Technicians List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: technicianProvider.isLoading
                              ? _buildTechnicianSkeletonList(context)
                    : filteredTechnicians.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedFilter != 'All' || _selectedDepartment != 'Department'
                                      ? 'No ${'Technicians'.toLowerCase()} match your filters'
                                      : 'No ${'Technicians'.toLowerCase()} yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedFilter != 'All' || _selectedDepartment != 'Department'
                                      ? 'Try adjusting your search or filters'
                                      : 'Add your first ${'Technician'.toLowerCase()} to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth = constraints.maxWidth;
                                  final isDesktop = kIsWeb && screenWidth >= 900;

                                  if (isDesktop) {
                                    return ListView.builder(
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior.onDrag,
                                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                                      itemCount: filteredTechnicians.length,
                                      itemBuilder: (context, index) {
                                        final technician = filteredTechnicians[index];
                                        final isLast = index == filteredTechnicians.length - 1;
                                        return Column(
                                          children: [
                                            _buildWebTechnicianRow(technician),
                                            if (!isLast) const SizedBox(height: 8),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                  return _buildMobileTable(context, filteredTechnicians);
                                },
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: _selectedTools != null
              ? FloatingActionButton.extended(
                  onPressed: _selectedTechnicians.isNotEmpty
                      ? () {
                          _assignToolsToTechnicians();
                        }
                      : null,
                  icon: const Icon(Icons.assignment_turned_in),
                  label: Text(_selectedTechnicians.isNotEmpty
                      ? 'Assign ${_selectedTools!.length} Tool${_selectedTools!.length > 1 ? 's' : ''} to ${_selectedTechnicians.length} Technician${_selectedTechnicians.length > 1 ? 's' : ''}'
                      : 'Select Technicians First'),
                  backgroundColor: _selectedTechnicians.isNotEmpty
                      ? AppTheme.secondaryColor
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                )
              : null,
        );
      },
    );
  }

  Widget _buildTechnicianCard(Technician technician) {
    final isSelected =
        technician.id != null && _selectedTechnicians.contains(technician.id!);

    // Get assigned tools count
    final assignedToolsCount = context
        .read<SupabaseToolProvider>()
        .tools
        .where((tool) => tool.assignedTo == technician.id)
        .length;

    final baseCardColor = AppTheme.cardSurfaceColor(context);
    final cardColor = isSelected
        ? AppTheme.secondaryColor.withOpacity(0.08)
        : baseCardColor;

    return InkWell(
      onTap: () {
        if (_selectedTools != null) {
          setState(() {
            if (technician.id != null) {
              if (isSelected) {
                _selectedTechnicians.remove(technician.id!);
              } else {
                _selectedTechnicians.add(technician.id!);
              }
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TechnicianDetailScreen(technician: technician),
            ),
          );
        }
      },
      onLongPress: () {
        if (_selectedTools == null) {
          _showEditTechnicianDialog(technician);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: context.cardDecoration.copyWith(
          color: isSelected
              ? AppTheme.secondaryColor.withOpacity(0.08)
              : context.cardBackground,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTechnicianAvatar(technician),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              technician.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              technician.department?.isNotEmpty == true
                                  ? technician.department!
                                  : AppLocalizations.of(context).technicians_noDepartment,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_selectedTools != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppTheme.secondaryColor
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4),
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStatusChip(technician.status),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.build_outlined,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          assignedToolsCount == 0
                              ? AppLocalizations.of(context).technicians_noTools
                              : '$assignedToolsCount tool${assignedToolsCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
  }

  // Web-optimized compact row for technicians
  Widget _buildWebTechnicianRow(Technician technician) {
    final isSelected =
        technician.id != null && _selectedTechnicians.contains(technician.id!);
    final assignedToolsCount = context
        .read<SupabaseToolProvider>()
        .tools
        .where((tool) => tool.assignedTo == technician.id)
        .length;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (_selectedTools != null) {
          setState(() {
            if (technician.id != null) {
              if (isSelected) {
                _selectedTechnicians.remove(technician.id!);
              } else {
                _selectedTechnicians.add(technician.id!);
              }
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TechnicianDetailScreen(technician: technician),
            ),
          );
        }
      },
      onLongPress: () {
        if (_selectedTools == null) {
          _showEditTechnicianDialog(technician);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondaryColor.withOpacity(0.06)
              : context.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondaryColor.withOpacity(0.3)
                : theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar - smaller for web
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onSurface.withOpacity(0.05),
              ),
              child: _buildTechnicianAvatarContent(technician, 36),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              flex: 3,
              child: Text(
                technician.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Department
            Expanded(
              flex: 2,
              child: Text(
                technician.department?.isNotEmpty == true
                    ? technician.department!
                    : '-',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Phone
            Expanded(
              flex: 2,
              child: Text(
                technician.phone?.trim().isNotEmpty == true
                    ? technician.phone!
                    : '-',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            SizedBox(
              width: 80,
              child: _buildStatusChip(technician.status),
            ),
            // Tools count
            SizedBox(
              width: 70,
              child: Row(
                children: [
                  Icon(
                    Icons.build_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$assignedToolsCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Selection checkbox or chevron
            if (_selectedTools != null)
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? AppTheme.secondaryColor
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              )
            else
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianAvatarContent(Technician technician, double size) {
    final hasImage = technician.profilePictureUrl != null &&
        technician.profilePictureUrl!.isNotEmpty;
    final initials = technician.name.isNotEmpty
        ? technician.name.trim()[0].toUpperCase()
        : '?';

    if (hasImage) {
      return ClipOval(
        child: Image.network(
          technician.profilePictureUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.65),
                ),
              ),
            );
          },
        ),
      );
    }
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withOpacity(0.65),
        ),
      ),
    );
  }

  Widget _buildTechnicianAvatar(Technician technician) {
    final hasImage = technician.profilePictureUrl != null &&
        technician.profilePictureUrl!.isNotEmpty;
    final initials = technician.name.isNotEmpty
        ? technician.name.trim()[0].toUpperCase()
        : '?';

    final placeholderColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withOpacity(0.05);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: placeholderColor,
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                technician.profilePictureUrl!,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  Logger.debug('❌ Error loading profile picture for ${technician.name}: $error');
                  Logger.debug('❌ URL: ${technician.profilePictureUrl}');
                  return Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.65),
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.65),
                ),
              ),
            ),
    );
  }

  // ── Filter bar (new web-style) ─────────────────────────────────────────
  Widget _buildFilterBar(List<String> departments) {
    final theme = Theme.of(context);
    final hasActiveFilter = _searchQuery.isNotEmpty ||
        _selectedFilter != 'All' ||
        _selectedDepartment != 'Department';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Row 1: search (matches Tools screen)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 17,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                FocusScope.of(context).unfocus();
                              },
                              padding: EdgeInsets.zero,
                              splashRadius: 16,
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: status + department + clear
          Row(
            children: [
              _filterDropdown(
                value: _selectedFilter,
                items: const ['All', 'Active', 'Inactive', 'With Tools', 'Without Tools'],
                hint: 'Status',
                resetLabel: 'All Status',
                onChanged: (v) => setState(() => _selectedFilter = v!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterDropdown(
                  value: _selectedDepartment,
                  items: ['Department', ...departments],
                  hint: 'Department',
                  resetLabel: 'All Departments',
                  onChanged: (v) => setState(() => _selectedDepartment = v!),
                ),
              ),
              if (hasActiveFilter) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedFilter = 'All';
                      _selectedDepartment = 'Department';
                    });
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Filter dropdown pill ──────────────────────────────────────────────
  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required String hint,
    required String resetLabel,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = value != 'All' && value != 'Department' && value != hint;

    String displayText(String item) {
      if (item == 'All' || item == 'Department') return resetLabel;
      return item;
    }

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: hint == 'Department',
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16,
              color: isActive
                  ? AppTheme.primaryColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? AppTheme.primaryColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          menuMaxHeight: 300,
          borderRadius: BorderRadius.circular(10),
          selectedItemBuilder: (_) => items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(displayText(item),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        )),
                  ))
              .toList(),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(displayText(item),
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Mobile table (horizontal + vertical scroll) ───────────────────────
  Widget _buildMobileTable(BuildContext context, List<Technician> technicians) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final toolProvider = context.read<SupabaseToolProvider>();

    const double colName     = 160;
    const double colDept     = 120;
    const double colPhone    = 120;
    const double colEmpId    = 100;
    const double colStatus   =  90;
    const double colTools    =  70;
    const double colAction   =  44;
    // Row/header containers add horizontal padding of 16 on each side,
    // so include that in scroll width to avoid right-edge overflow.
    const double totalW =
        colName + colDept + colPhone + colEmpId + colStatus + colTools + colAction + 32;

    TextStyle headerStyle() => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: onSurface.withValues(alpha: 0.45),
      letterSpacing: 0.3,
    );
    TextStyle cellStyle() => TextStyle(
      fontSize: 12.5,
      color: onSurface.withValues(alpha: 0.85),
    );

    Widget headerCell(String label, double w, {TextAlign align = TextAlign.left}) =>
        SizedBox(
          width: w,
          child: Text(label.toUpperCase(), style: headerStyle(),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        );

    Widget cell(String text, double w, {FontWeight? weight, Color? color}) =>
        SizedBox(
          width: w,
          child: Text(text,
              style: cellStyle().copyWith(fontWeight: weight, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        );

    final headerRow = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : const Color(0xFFF5F5F5),
      child: Row(
        children: [
          headerCell('Name', colName),
          headerCell('Department', colDept),
          headerCell('Phone', colPhone),
          headerCell('Emp ID', colEmpId),
          headerCell('Status', colStatus),
          headerCell('Tools', colTools),
          SizedBox(width: colAction),
        ],
      ),
    );

    Widget buildRow(Technician tech) {
      final isSelected = tech.id != null && _selectedTechnicians.contains(tech.id!);
      final toolCount = toolProvider.tools
          .where((t) => t.assignedTo == tech.id)
          .length;
      final initials = tech.name.isNotEmpty ? tech.name.trim()[0].toUpperCase() : '?';
      final hasImage = tech.profilePictureUrl != null && tech.profilePictureUrl!.isNotEmpty;

      return InkWell(
        onTap: () {
          if (_selectedTools != null) {
            setState(() {
              if (tech.id != null) {
                if (isSelected) {
                  _selectedTechnicians.remove(tech.id!);
                } else {
                  _selectedTechnicians.add(tech.id!);
                }
              }
            });
          } else {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => TechnicianDetailScreen(technician: tech),
            ));
          }
        },
        onLongPress: () {
          if (_selectedTools == null) _showEditTechnicianDialog(tech);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: onSurface.withValues(alpha: isDark ? 0.06 : 0.04),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar + name
              SizedBox(
                width: colName,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                      ),
                      child: hasImage
                          ? ClipOval(
                              child: Image.network(
                                tech.profilePictureUrl!,
                                fit: BoxFit.cover,
                                width: 32,
                                height: 32,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(initials,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor,
                                      )),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(initials,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  )),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tech.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              cell(tech.department?.isNotEmpty == true ? tech.department! : '—', colDept),
              cell(tech.phone?.trim().isNotEmpty == true ? tech.phone! : '—', colPhone),
              cell(tech.employeeId?.isNotEmpty == true ? tech.employeeId! : '—', colEmpId),
              // Status pill
              SizedBox(
                width: colStatus,
                child: _buildStatusChip(tech.status, compact: true),
              ),
              // Tools count
              SizedBox(
                width: colTools,
                child: Row(
                  children: [
                    Icon(Icons.build_outlined, size: 12,
                        color: onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Text('$toolCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.7),
                        )),
                  ],
                ),
              ),
              // Action
              SizedBox(
                width: colAction,
                child: _selectedTools != null
                    ? Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : onSurface.withValues(alpha: 0.35),
                      )
                    : PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _showEditTechnicianDialog(tech);
                          if (v == 'delete' && tech.id != null) {
                            _showDeleteConfirmation(tech);
                          }
                          if (v == 'send_invite' && tech.email != null) {
                            _sendInvite(tech);
                          }
                        },
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        icon: Icon(Icons.more_vert, size: 18,
                            color: onSurface.withValues(alpha: 0.4)),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ]),
                          ),
                          if (tech.email != null && tech.email!.isNotEmpty)
                            const PopupMenuItem(
                              value: 'send_invite',
                              child: Row(children: [
                                Icon(Icons.email_outlined, size: 18, color: Colors.blue),
                                SizedBox(width: 10),
                                Text('Send Invite', style: TextStyle(color: Colors.blue)),
                              ]),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              shrinkWrap: false,
              children: [
                headerRow,
                const Divider(height: 1, thickness: 0.5),
                ...technicians.map(buildRow),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = [
      'All',
      'Active',
      'Inactive',
      'With Tools',
      'Without Tools',
    ];

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.secondaryColor,
              side: BorderSide(
                color: isSelected
                    ? AppTheme.secondaryColor
                    : Colors.black.withOpacity(0.04),
                width: isSelected ? 0 : 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status, {bool compact = false}) {
    Color textColor;
    Color backgroundColor;

    switch (status.toLowerCase()) {
      case 'active':
        textColor = const Color(0xFF0FA958);
        backgroundColor = const Color(0xFFE9F8F1);
        break;
      case 'inactive':
        textColor = const Color(0xFF6E6E6E);
        backgroundColor = const Color(0xFFF1F1F1);
        break;
      default:
        textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
        backgroundColor =
            Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 2.5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 72 : 120),
        child: Text(
          status,
          style: TextStyle(
            color: textColor,
            fontSize: compact ? 10 : 10.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showAddTechnicianDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTechnicianScreen(),
      ),
    );
  }

  void _showEditTechnicianDialog(Technician technician) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTechnicianScreen(technician: technician),
      ),
    );
  }

  Future<void> _sendInvite(Technician technician) async {
    if (technician.email == null || technician.email!.isEmpty) return;

    final auth = context.read<AuthProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating invite link...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );

    try {
      final newUserId = await auth.createTechnicianAuthAccount(
        email: technician.email!,
        name: technician.name,
        department: technician.department,
      );

      // Link user_id to technician record if not already set
      if (technician.id != null && technician.userId == null && newUserId != null) {
        await SupabaseService.client
            .from('technicians')
            .update({'user_id': newUserId})
            .eq('id', technician.id!);
        await context.read<SupabaseTechnicianProvider>().loadTechnicians();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite sent to ${technician.email}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      final msg = e.toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FunctionException: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invite: $msg'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showInviteLinkDialog(String name, String link) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Invite Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Open this link in the device browser to set $name\'s password:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copy Link'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Delete ${'Technician'}',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete ${technician.name}?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).common_cancel,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<SupabaseTechnicianProvider>()
                  .deleteTechnician(technician.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${technician.name} deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _assignToolsToTechnicians() async {
    if (_selectedTools == null || _selectedTechnicians.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Assigning tools...'),
            ],
          ),
        ),
      );

      // Get technician provider and tool provider
      final technicianProvider = context.read<SupabaseTechnicianProvider>();
      final toolProvider = context.read<SupabaseToolProvider>();

      // Get technician details for each selected technician
      final technicians = technicianProvider.technicians
          .where((tech) =>
              tech.id != null && _selectedTechnicians.contains(tech.id!))
          .toList();

      // Assign each tool to each selected technician
      List<String> failedAssignments = [];
      final authProvider = context.read<AuthProvider>();
      final adminName = authProvider.userFullName ?? 'Admin';

      for (final toolId in _selectedTools!) {
        for (final technician in technicians) {
          // Use technician.userId directly — no email-based lookups needed
          final userId = technician.userId;

          if (userId == null || userId.isEmpty) {
            failedAssignments.add(technician.name);
            Logger.debug(
                '⚠️ No linked user account for technician: ${technician.name}');
            continue;
          }

          try {
            Logger.debug('🔧 Assigning tool $toolId to userId: $userId');
            await toolProvider.assignTool(toolId, userId, 'Permanent');

            final tool = toolProvider.getToolById(toolId);
            final toolName = tool?.name ?? 'Tool';

            // Send in-app notification to technician
            try {
              await SupabaseService.client.from('technician_notifications').insert({
                'user_id': userId,
                'title': 'Tool Assigned to You',
                'message': '$adminName assigned "$toolName" to you. Please accept or decline.',
                'type': 'tool_assigned',
                'is_read': false,
                'timestamp': DateTime.now().toIso8601String(),
                'data': {
                  'tool_id': toolId,
                  'tool_name': toolName,
                  'assigned_by_name': adminName,
                  'assignment_type': 'Permanent',
                },
              });
            } catch (e) {
              Logger.debug('Error sending in-app notification: $e');
            }

            // Send push notification (fire-and-forget)
            try {
              await PushNotificationService.sendToUser(
                userId: userId,
                title: 'Tool Assigned to You',
                body: '$adminName assigned "$toolName" to you. Please accept or decline.',
                data: {
                  'type': 'tool_assigned',
                  'tool_id': toolId,
                  'tool_name': toolName,
                },
              );
            } catch (_) {}
          } catch (e) {
            Logger.debug('Error assigning tool to ${technician.name}: $e');
            failedAssignments.add(technician.name);
          }
        }
      }

      // Refresh tools to get updated data
      await toolProvider.loadTools();

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show consolidated error message if any assignments failed
      if (failedAssignments.isNotEmpty) {
        final failedCount = failedAssignments.length;
        final totalCount = technicians.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedCount == totalCount
                  ? 'Could not assign tools. ${failedCount} technician${failedCount > 1 ? 's' : ''} (${failedAssignments.take(3).join(', ')}${failedCount > 3 ? '...' : ''}) need to register in the app first.'
                  : 'Assigned tools to ${totalCount - failedCount} technician(s), but ${failedCount} technician${failedCount > 1 ? 's' : ''} need to register first.',
            ),
            backgroundColor:
                failedCount == totalCount ? Colors.red : Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully assigned ${_selectedTools!.length} tool${_selectedTools!.length > 1 ? 's' : ''} to ${_selectedTechnicians.length} technician${_selectedTechnicians.length > 1 ? 's' : ''}',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Navigate back to admin dashboard (Tools tab)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin',
        (route) => false,
        arguments: {'initialTab': 1},
      );
    } catch (e) {
      if (!mounted) return;
      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning tools: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
