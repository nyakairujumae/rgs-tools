import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';

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
import '../providers/organization_provider.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  static const Color _skeletonBaseColor = Color(0xFFE6EAF1);
  static const Color _skeletonHighlightColor = Color(0xFFD8DBE0);
  String _searchQuery = '';
  String _selectedFilter = 'All';
  Set<String> _selectedTechnicians = <String>{};
  List<String>? _selectedTools;

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
      baseColor: _skeletonBaseColor,
      highlightColor: _skeletonHighlightColor,
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
            decoration: const BoxDecoration(
              color: _skeletonBaseColor,
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
                        color: _skeletonBaseColor,
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
          color: _skeletonBaseColor,
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

        // Get unique departments for filter
        final departments = technicians
            .where((tech) =>
                tech.department != null && tech.department!.isNotEmpty)
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

          // Apply selected filter
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
            // Department filter
            if (departments.contains(_selectedFilter) &&
                tech.department != _selectedFilter) {
              return false;
            }
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
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
                              Text(
                                context.read<OrganizationProvider>().workerLabelPlural,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (_selectedTools == null) const SizedBox(height: 4),
                              if (_selectedTools == null)
                                Text(
                                  AppLocalizations.of(context).technicians_subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.55),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_selectedTools == null)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'add') {
                                _showAddTechnicianDialog();
                              } else if (value == 'csv') {
                                _bulkImportCSV();
                              }
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'add',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_add_rounded, size: 20),
                                    const SizedBox(width: 10),
                                    Text('Add ${context.read<OrganizationProvider>().workerLabel}'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'csv',
                                child: Row(
                                  children: [
                                    Icon(Icons.upload_file_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text('Bulk import CSV'),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectedTools != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text(
                        AppLocalizations.of(context).technicians_subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.55),
                        ),
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
                                  'Select ${context.read<OrganizationProvider>().workerLabelPlural.toLowerCase()} to assign',
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

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: TextField(
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: context.chatGPTInputDecoration.copyWith(
                        hintText: AppLocalizations.of(context).technicians_searchHint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.45),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.45),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),

                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFilterChips(),
                  ),
                  const SizedBox(height: 12),

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
                                  AppLocalizations.of(context).technicians_emptyTitle,
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
                                  AppLocalizations.of(context).technicians_emptySubtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth = constraints.maxWidth;
                                  final isDesktop = kIsWeb && screenWidth >= 900;
                                  final padding = isDesktop ? 20.0 : 16.0;
                                  final spacing = isDesktop ? 8.0 : 12.0;
                                  
                                  return ListView.builder(
                                    padding: EdgeInsets.fromLTRB(padding, 12, padding, 16),
                                    itemCount: filteredTechnicians.length,
                                    itemBuilder: (context, index) {
                                      final technician = filteredTechnicians[index];
                                      final isLast = index == filteredTechnicians.length - 1;
                                      return Column(
                                        children: [
                                          isDesktop 
                                            ? _buildWebTechnicianRow(technician)
                                            : _buildTechnicianCard(technician),
                                          if (!isLast) SizedBox(height: spacing),
                                        ],
                                      );
                                    },
                                  );
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
      borderRadius: BorderRadius.circular(18), // Match card decoration
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
                      ? AppTheme.secondaryColor
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
              backgroundColor: context.cardBackground,
              selectedColor: AppTheme.secondaryColor.withOpacity(0.08),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.secondaryColor
                    : Colors.black.withOpacity(0.04),
                width: isSelected ? 1.2 : 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18), // Match card borderRadius
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
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

  Future<void> _bulkImportCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final content = utf8.decode(bytes);
      final lines = content
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        _showCSVError('CSV file is empty.');
        return;
      }

      // Detect header
      final firstRow = lines.first.toLowerCase();
      final hasHeader = firstRow.contains('name') || firstRow.contains('email');
      final dataLines = hasHeader ? lines.sublist(1) : lines;

      if (dataLines.isEmpty) {
        _showCSVError('No data rows found.');
        return;
      }

      // Parse: name, email, phone, department
      final rows = <Map<String, String>>[];
      for (final line in dataLines) {
        final cols = _parseCSVLine(line);
        if (cols.isEmpty) continue;
        final name = cols.isNotEmpty ? cols[0].trim() : '';
        final email = cols.length > 1 ? cols[1].trim() : '';
        if (email.isEmpty) continue;
        rows.add({
          'name': name.isEmpty ? email.split('@').first : name,
          'email': email,
          'phone': cols.length > 2 ? cols[2].trim() : '',
          'department': cols.length > 3 ? cols[3].trim() : '',
        });
      }

      if (rows.isEmpty) {
        _showCSVError('No valid rows found. Ensure CSV has name and email columns.');
        return;
      }

      // Show confirmation dialog
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Import ${rows.length} ${rows.length == 1 ? 'person' : 'people'}?'),
          content: SizedBox(
            width: double.maxFinite,
            height: (rows.length * 48.0).clamp(48.0, 300.0),
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.12),
                      child: Text(
                        rows[i]['name']![0].toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.secondaryColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i]['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(rows[i]['email']!, style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryColor),
              child: const Text('Import & Send Invites'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      // Send invites
      final auth = context.read<AuthProvider>();
      int success = 0;
      int failed = 0;

      for (final row in rows) {
        try {
          await auth.createTechnicianAuthAccount(
            email: row['email']!,
            name: row['name']!,
            department: row['department']!.isEmpty ? null : row['department'],
          );
          success++;
        } catch (_) {
          failed++;
        }
      }

      if (mounted) {
        // Refresh the list
        context.read<SupabaseTechnicianProvider>().loadTechnicians();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failed == 0
                  ? '$success invite${success == 1 ? '' : 's'} sent successfully!'
                  : '$success sent, $failed failed.',
            ),
            backgroundColor: failed == 0 ? AppTheme.secondaryColor : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      _showCSVError('Failed to read CSV: $e');
    }
  }

  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(c);
      }
    }
    result.add(sb.toString());
    return result;
  }

  void _showCSVError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _showDeleteConfirmation(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          AppLocalizations.of(context).technicians_deleteTitle,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          AppLocalizations.of(context).technicians_deleteConfirm(technician.name),
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
