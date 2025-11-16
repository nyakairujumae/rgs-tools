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
import '../utils/responsive_helper.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? colorScheme.surface : Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        scrolledUnderElevation: 6,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Check In Tool',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              'Scan or search for tools you currently hold, review their condition, and return them to the inventory.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
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
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await toolProvider.loadTools();
                      },
                      child: SingleChildScrollView(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: ResponsiveHelper.getMaxWidth(context),
                            ),
                            child: Column(
                              children: [
                                _buildSearchCard(context),
                                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                                _buildToolList(context, filteredTools, technicianProvider),
                                if (_selectedTool != null) ...[
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                                  _buildSelectedToolCard(context, technicianProvider),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                                  _buildCheckinForm(context),
                                ],
                                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 100)),
                              ],
                            ),
                          ),
                        ),
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


  Widget _buildSearchCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        all: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? theme.colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                    ),
                    border: Border.all(
                      color: isDarkMode 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by tool name, brand, or...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                        ),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      contentPadding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                  ),
                ),
                child: IconButton(
                  onPressed: _openScanner,
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: AppTheme.primaryColor,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Text(
            'Only tools currently assigned to you are listed below. Use the scanner to speed up the search.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolList(BuildContext context, List<Tool> tools, SupabaseTechnicianProvider technicianProvider) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    if (tools.isEmpty) {
      return Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          all: 24,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
          ),
          border: Border.all(
            color: isDarkMode 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: ResponsiveHelper.getResponsiveIconSize(context, 48),
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Text(
              'No tools to check in',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
            Text(
              'You currently do not have any tools assigned to you. Badge a shared tool or request one from the admin team.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                height: 1.4,
              ),
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
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
              margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                ),
                border: isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : Border.all(
                        color: isDarkMode 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.15),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                all: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveIconSize(context, 54),
                    height: ResponsiveHelper.getResponsiveIconSize(context, 54),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                      ),
                    ),
                    child: Icon(
                      Icons.build,
                      color: AppTheme.primaryColor,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            StatusChip(status: tool.status),
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                        Text(
                          '${tool.category}${tool.brand != null && tool.brand!.isNotEmpty ? ' • ${tool.brand}' : ''}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                        Row(
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 14),
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Text(
                              tool.serialNumber ?? 'No serial number',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 14),
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Text(
                              'Assigned to: $technicianName',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
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
        }),
      ],
    );
  }

  Widget _buildSelectedToolCard(BuildContext context, SupabaseTechnicianProvider technicianProvider) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final tool = _selectedTool!;
    final technicianName = technicianProvider.getTechnicianNameById(tool.assignedTo) ?? 'You';

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        all: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                color: Colors.green.shade600,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                'Selected Tool',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          _buildDetailRow(context, 'Name', tool.name),
          _buildDetailRow(context, 'Category', tool.category),
          if (tool.brand != null && tool.brand!.isNotEmpty)
            _buildDetailRow(context, 'Brand', tool.brand!),
          if (tool.serialNumber != null && tool.serialNumber!.isNotEmpty)
            _buildDetailRow(context, 'Serial Number', tool.serialNumber!),
          _buildDetailRow(context, 'Currently Assigned', technicianName),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
              StatusChip(status: tool.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinForm(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        all: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment,
                color: AppTheme.primaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                'Check-In Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          GestureDetector(
            onTap: _selectCheckinDate,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? theme.colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                ),
                border: Border.all(
                  color: isDarkMode 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _checkinDate != null
                        ? AppTheme.primaryColor
                        : Colors.grey[400],
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: Text(
                      _checkinDate != null
                          ? '${_checkinDate!.day}/${_checkinDate!.month}/${_checkinDate!.year}'
                          : 'Select check-in date',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _checkinDate != null
                            ? theme.colorScheme.onSurface
                            : Colors.grey[400],
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[500],
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),
          Text(
            'Returned Condition',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Wrap(
            spacing: ResponsiveHelper.getResponsiveSpacing(context, 10),
            runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 10),
            children: _conditions.map((condition) {
              final bool isSelected = _returnCondition == condition;
              return ChoiceChip(
                label: Text(
                  condition,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _returnCondition = condition),
                backgroundColor: isSelected
                    ? Colors.green.shade600
                    : (isDarkMode ? theme.colorScheme.surface : Colors.grey.shade200),
                selectedColor: Colors.green.shade600,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isSelected
                      ? Colors.green.shade600
                      : (isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 16),
              ),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _notesController,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              ),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
                hintText: 'Add any issues, damage, or additional information...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                  ),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                  ),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  vertical: 16,
                ),
                filled: true,
                fillColor: isDarkMode ? theme.colorScheme.surface : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final canSubmit = _selectedTool != null && _checkinDate != null && !_isSaving;

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: canSubmit ? Colors.green.shade600 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 16),
              ),
              boxShadow: [
                if (canSubmit)
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: ElevatedButton(
              onPressed: canSubmit ? _performCheckin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                  ),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          color: Colors.white,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 10)),
                        Text(
                          'Check In Tool',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              ),
            ),
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