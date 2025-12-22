import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../models/technician.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../services/supabase_service.dart';
import '../widgets/common/offline_skeleton.dart';
import '../providers/connectivity_provider.dart';
import 'add_technician_screen.dart';
import 'technician_detail_screen.dart';

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
                    child: Text(
                      'Technicians',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      'Manage active, inactive, and assigned technicians',
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
                                  'Select technicians to assign',
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
                        hintText: 'Search technicians...',
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

                  // Technicians List
                  Expanded(
                    child: isOffline && !technicianProvider.isLoading
                        ? OfflineListSkeleton(
                            itemCount: 5,
                            itemHeight: 100,
                            message:
                                'You are offline. Showing cached technicians.',
                          )
                        : technicianProvider.isLoading
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
                                  'No technicians found',
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
                                  'Add your first technician to get started',
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
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                itemCount: filteredTechnicians.length,
                                itemBuilder: (context, index) {
                                  final technician = filteredTechnicians[index];
                                  final isLast =
                                      index == filteredTechnicians.length - 1;
                                  return Column(
                                    children: [
                                      _buildTechnicianCard(technician),
                                      if (!isLast) const SizedBox(height: 12), // Spacing between cards
                                    ],
                                  );
                                },
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
                  icon: Icon(Icons.assignment_turned_in),
                  label: Text(_selectedTechnicians.isNotEmpty
                      ? 'Assign ${_selectedTools!.length} Tool${_selectedTools!.length > 1 ? 's' : ''} to ${_selectedTechnicians.length} Technician${_selectedTechnicians.length > 1 ? 's' : ''}'
                      : 'Select Technicians First'),
                  backgroundColor: _selectedTechnicians.isNotEmpty
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 16),
                  child: SizedBox(
                    height: 52,
                    width: 52,
                    child: FloatingActionButton(
                      onPressed: _showAddTechnicianDialog,
              backgroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.borderRadiusLarge),
              ),
              elevation: 0, // No elevation - clean design
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ),
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
                                  : 'No department',
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
                              ? 'No tools'
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
                  debugPrint('❌ Error loading profile picture for ${technician.name}: $error');
                  debugPrint('❌ URL: ${technician.profilePictureUrl}');
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
          'Delete Technician',
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
              'Cancel',
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

      for (final toolId in _selectedTools!) {
        for (final technician in technicians) {
          if (technician.email != null && technician.email!.isNotEmpty) {
            // Look up the user ID - check approval status first, then users table
            try {
              final technicianEmail = technician.email!.trim();
              debugPrint(
                  '🔍 Looking up user for technician: ${technician.name}');
              debugPrint('   Technician email: "$technicianEmail"');

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
                debugPrint('   ✅ Found user ID from approval record: $userId');
              } else {
                // If no approval record, try to find user in users table
                debugPrint(
                    '   No approval record found, checking users table...');
                var userResponse = await SupabaseService.client
                    .from('users')
                    .select('id, email')
                    .ilike('email', technicianEmail)
                    .maybeSingle();

                // If not found with ilike, try fetching all and matching
                if (userResponse == null) {
                  debugPrint(
                      '   No direct match found, searching all users...');
                  final allUsers = await SupabaseService.client
                      .from('users')
                      .select('id, email');

                  debugPrint(
                      '   Found ${(allUsers as List).length} total users');
                  for (var user in allUsers as List) {
                    final userEmail =
                        (user['email'] as String?)?.toLowerCase() ?? '';
                    if (userEmail == technicianEmail.toLowerCase()) {
                      userResponse = user;
                      debugPrint('   ✅ Found matching user: ${user['id']}');
                      break;
                    }
                  }
                } else {
                  debugPrint('   ✅ Found user: ${userResponse['id']}');
                }

                if (userResponse != null && userResponse['id'] != null) {
                  userId = userResponse['id'] as String;
                }
              }

              if (userId != null) {
                // Use the user ID (from auth.users/users table) as the assigned_to value
                await toolProvider.assignTool(
                  toolId,
                  userId,
                  'Permanent',
                );
              } else {
                // No user account found - technician needs to register and be approved first
                failedAssignments.add(technician.name);
                debugPrint(
                    '⚠️ No user account found for technician: ${technician.name} (${technician.email})');
                debugPrint(
                    '   Technician must register in the app and be approved by admin first.');
              }
            } catch (e) {
              debugPrint(
                  'Error looking up user for technician ${technician.name}: $e');
              failedAssignments.add(technician.name);
            }
          } else {
            debugPrint('⚠️ Technician ${technician.name} has no email address');
            failedAssignments.add(technician.name);
          }
        }
      }

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
      }

      // Refresh tools to get updated data
      await toolProvider.loadTools();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully assigned ${_selectedTools!.length} tool${_selectedTools!.length > 1 ? 's' : ''} to ${_selectedTechnicians.length} technician${_selectedTechnicians.length > 1 ? 's' : ''}',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to admin dashboard
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
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
