import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/tool.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/themed_text_field.dart';
import '../widgets/common/themed_button.dart';
import '../utils/error_handler.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';
import '../utils/responsive_helper.dart';
import '../utils/file_helper.dart' if (dart.library.html) '../utils/file_helper_stub.dart';

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
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => NavigationHelper.safePop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Return Tool',
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
        color: context.scaffoldBackground,
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
                      backgroundColor: context.scaffoldBackground,
                      color: AppTheme.secondaryColor,
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
    
    return Container(
      decoration: context.cardDecoration,
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
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  ),
                  decoration: context.chatGPTInputDecoration.copyWith(
                    hintText: 'Search by tool name, brand, or...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Container(
                decoration: context.cardDecoration,
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
        decoration: context.cardDecoration,
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: ResponsiveHelper.getResponsiveIconSize(context, 48),
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Text(
              'No tools to return',
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
              decoration: context.cardDecoration.copyWith(
                border: isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : context.cardDecoration.border,
              ),
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                all: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildToolImage(tool, context),
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

  List<String> _getToolImageUrls(Tool tool) {
    if (tool.imagePath == null || tool.imagePath!.isEmpty) {
      return [];
    }
    
    // Support both single image (backward compatibility) and multiple images (comma-separated)
    final imagePath = tool.imagePath!;
    
    // Check if it's comma-separated (multiple images)
    if (imagePath.contains(',')) {
      return imagePath.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    return [imagePath];
  }

  Widget _buildToolImage(Tool tool, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrls = _getToolImageUrls(tool);
    final imageSize = ResponsiveHelper.getResponsiveIconSize(context, 54);

    if (imageUrls.isEmpty) {
      // Show placeholder icon if no image
      return Container(
        width: imageSize,
        height: imageSize,
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
      );
    }

    final imageUrl = imageUrls.first;

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
        ),
        border: Border.all(
          color: context.cardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
        ),
        child: _buildImageWidget(imageUrl, colorScheme),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, ColorScheme colorScheme) {
    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: context.cardBackground,
            child: Icon(
              Icons.build,
              color: AppTheme.primaryColor,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: context.cardBackground,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    }
    
    // Check if it's a local file (not web)
    if (!kIsWeb && !imageUrl.startsWith('http')) {
      final localImage = buildLocalFileImage(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
      if (localImage != null) {
        return localImage;
      }
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: context.cardBackground,
        child: Icon(
          Icons.build,
          color: AppTheme.primaryColor,
          size: ResponsiveHelper.getResponsiveIconSize(context, 24),
        ),
      );
    }
    
    // Fallback for other cases
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: context.cardBackground,
      child: Icon(
        Icons.build,
        color: AppTheme.primaryColor,
        size: ResponsiveHelper.getResponsiveIconSize(context, 24),
      ),
    );
  }

  Widget _buildSelectedToolCard(BuildContext context, SupabaseTechnicianProvider technicianProvider) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final tool = _selectedTool!;
    final technicianName = technicianProvider.getTechnicianNameById(tool.assignedTo) ?? 'You';

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 20),
        ),
        border: Border.all(
          color: AppTheme.getCardBorderSubtle(context),
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
                    color: context.secondaryTextColor,
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
      decoration: context.cardDecoration,
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
                'Return Details',
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
              decoration: context.cardDecoration,
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
                        : theme.colorScheme.onSurface.withOpacity(0.55),
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: Text(
                      _checkinDate != null
                          ? '${_checkinDate!.day}/${_checkinDate!.month}/${_checkinDate!.year}'
                          : 'Select return date',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _checkinDate != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.55),
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                    : context.cardBackground,
                selectedColor: Colors.green.shade600,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isSelected
                      ? Colors.green.shade600
                      : AppTheme.getCardBorderSubtle(context),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 18)),
          ThemedTextField(
            controller: _notesController,
            label: 'Notes (optional)',
            hint: 'Add any issues, damage, or additional information...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final canSubmit = _selectedTool != null && _checkinDate != null && !_isSaving;

    return SafeArea(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ThemedButton(
              onPressed: canSubmit ? _performCheckin : null,
              isLoading: _isSaving,
              backgroundColor: canSubmit ? Colors.green.shade600 : Colors.grey.shade400,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_turned_in,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 10)),
                  const Text(
                    'Return Tool',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            TextButton(
              onPressed: () => NavigationHelper.safePop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                ),
              ),
            ),
          ],
        ),
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
      final toolProvider = context.read<SupabaseToolProvider>();
      
      String newStatus = 'Available';
      if (_returnCondition == 'Poor' || _returnCondition == 'Needs Repair') {
        newStatus = 'Maintenance';
      }

      // For shared tools, ensure assignedTo is cleared when returning
      final updatedTool = _selectedTool!.copyWith(
        status: newStatus,
        condition: _returnCondition,
        assignedTo: null, // Always clear assignedTo when returning, especially for shared tools
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await toolProvider.updateTool(updatedTool);
      
      // Reload tools to ensure fresh data from database
      await toolProvider.loadTools();

      if (!mounted) return;
        AuthErrorHandler.showSuccessSnackBar(context, '${_selectedTool!.name} returned successfully');
        NavigationHelper.safePop(context);
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}