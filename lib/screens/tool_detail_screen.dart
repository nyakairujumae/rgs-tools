import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/file_helper.dart' if (dart.library.html) '../utils/file_helper_stub.dart';
import '../models/tool.dart';
import "../providers/supabase_tool_provider.dart";
import "../providers/supabase_technician_provider.dart";
import "../providers/auth_provider.dart";
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../utils/error_handler.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_helper.dart';
import '../utils/navigation_helper.dart';
import '../utils/auth_error_handler.dart';
import '../services/push_notification_service.dart';
import 'temporary_return_screen.dart';
import 'reassign_tool_screen.dart';
import 'edit_tool_screen.dart';
import 'tools_screen.dart';
import 'image_viewer_screen.dart';

class ToolDetailScreen extends StatefulWidget {
  final Tool tool;

  const ToolDetailScreen({super.key, required this.tool});

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> with ErrorHandlingMixin {
  late Tool _currentTool;
  bool _isLoading = false;
  bool _toolNotFound = false;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentTool = widget.tool;
    _verifyToolExists();
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: context.cardBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_outlined,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  /// Verify that the tool still exists in the provider
  Future<void> _verifyToolExists() async {
    // Wait a frame to ensure provider is available
    await Future.delayed(Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final toolProvider = context.read<SupabaseToolProvider>();
    
    // Check if tool exists in provider
    if (!toolProvider.toolExists(_currentTool.id!)) {
      // Tool might have been deleted, try to reload tools first
      await toolProvider.loadTools();
      
      if (mounted) {
        // Check again after reload
        if (!toolProvider.toolExists(_currentTool.id!)) {
          setState(() {
            _toolNotFound = true;
          });
          
          // Show error and navigate back
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('This tool no longer exists. It may have been deleted.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.of(context).pop();
            }
          });
          return;
        } else {
          // Tool found after reload, update current tool
          final updatedTool = toolProvider.getToolById(_currentTool.id!);
          if (updatedTool != null && mounted) {
            setState(() {
              _currentTool = updatedTool;
              _currentImageIndex = 0; // Reset to first image
            });
            // Reset PageController to first page
            _imagePageController.jumpToPage(0);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                      Icons.chevron_left,
                      size: 28,
                    color: theme.colorScheme.onSurface,
                    ),
                  onPressed: () => NavigationHelper.safePop(context),
                    splashRadius: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentTool.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: context.cardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                  ),
                  child: PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                    padding: EdgeInsets.zero,
                  color: context.cardBackground,
                    elevation: 0, // No elevation - clean design
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18), // Match card decoration
                    side: BorderSide(
                        color: AppTheme.getCardBorderSubtle(context),
                        width: 0.5,
                    ),
                  ),
                  itemBuilder: (context) => _buildAppBarMenuItems(theme),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _toolNotFound
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Tool Not Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This tool may have been deleted.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            )
          : LoadingOverlay(
              isLoading: _isLoading,
              loadingMessage: 'Loading tool details...',
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildInfoSection('Basic Information', [
                        _buildInfoRow('Name', _currentTool.name),
                        _buildInfoRow('Category', _currentTool.category),
                        if (_currentTool.brand != null) _buildInfoRow('Brand', _currentTool.brand!),
                        if (_currentTool.model != null) _buildInfoRow('Model', _currentTool.model!),
                        if (_currentTool.serialNumber != null) _buildInfoRow('Serial Number', _currentTool.serialNumber!),
                        if (_currentTool.location != null) _buildInfoRow('Location', _currentTool.location!),
                      ]),
                    const SizedBox(height: 12),
                    // Status & Assignment
                    _buildInfoSection('Status & Assignment', [
                        _buildInfoRow('Status', _currentTool.status, statusWidget: _buildCompactStatusChip(_currentTool.status, isAssigned: _currentTool.assignedTo != null)),
                        _buildInfoRow('Condition', _currentTool.condition, statusWidget: _buildCompactConditionChip(_currentTool.condition)),
                        if (_currentTool.assignedTo != null) 
                  Consumer<SupabaseTechnicianProvider>(
                    builder: (context, technicianProvider, child) {
                      final technicianName = technicianProvider.getTechnicianNameById(_currentTool.assignedTo) ?? 'Unknown';
                      return _buildInfoRow('Assigned To', technicianName);
                    },
                  ),
                if (_currentTool.createdAt != null) _buildInfoRow('Added On', _formatDate(_currentTool.createdAt!)),
                if (_currentTool.updatedAt != null) _buildInfoRow('Last Updated', _formatDate(_currentTool.updatedAt!)),
            ]),

            // Financial Information
              if (_currentTool.purchasePrice != null || _currentTool.currentValue != null)
              _buildInfoSection('Financial Information', [
                  if (_currentTool.purchasePrice != null) _buildInfoRow('Purchase Price', CurrencyFormatter.formatCurrency(_currentTool.purchasePrice!)),
                  if (_currentTool.currentValue != null) _buildInfoRow('Current Value', CurrencyFormatter.formatCurrency(_currentTool.currentValue!)),
                  if (_currentTool.purchaseDate != null) _buildInfoRow('Purchase Date', _formatDate(_currentTool.purchaseDate!)),
                  if (_currentTool.purchasePrice != null && _currentTool.currentValue != null)
                    _buildInfoRow('Depreciation', _calculateDepreciation()),
              ]),
              if (_currentTool.purchasePrice != null || _currentTool.currentValue != null)
                const SizedBox(height: 12),

            // Notes
              if (_currentTool.notes != null && _currentTool.notes!.isNotEmpty)
              _buildInfoSection('Notes', [
                  _buildInfoRow('', _currentTool.notes!),
              ]),

                    const SizedBox(height: 24),

            // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
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

  Widget _buildImageItem(String imageUrl, ColorScheme colorScheme, bool isDarkMode) {
    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 250,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(18), // Match card decoration
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  SizedBox(height: 8),
                  Text('Failed to load image', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(18), // Match card decoration
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
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
        height: 250,
      );
      if (localImage != null) {
        return localImage;
      }
      return Container(
        width: double.infinity,
        height: 250,
        color: context.cardBackground,
        child: Icon(Icons.image, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
      );
    }
    
    // Fallback for other cases
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(18), // Match card decoration
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            SizedBox(height: 8),
            Text('Image not found', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final imageUrls = _getToolImageUrls(_currentTool);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: context.cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18), // Match card decoration
          child: imageUrls.isNotEmpty
              ? Stack(
                  children: [
                    PageView.builder(
                      controller: _imagePageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = imageUrls[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageViewerScreen(
                                  imageUrls: imageUrls,
                                  initialIndex: _currentImageIndex,
                                ),
                              ),
                            );
                          },
                          child: _buildImageItem(
                              imageUrl, colorScheme, isDarkMode),
                        );
                      },
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageViewerScreen(
                                imageUrls: imageUrls,
                                initialIndex: _currentImageIndex,
                              ),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.open_in_full,
                          size: 20,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    if (imageUrls.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            imageUrls.length,
                            (index) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : _buildImagePlaceholder(colorScheme),
        ),
      ),
    );
  }


  Widget _buildInfoSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i != children.length - 1) {
        spacedChildren.add(const SizedBox(height: 14));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: context.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: spacedChildren,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? statusWidget}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (label.isEmpty) {
      return Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: statusWidget ??
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusChip(String status, {bool isAssigned = false}) {
    // Use app green for assigned tools or "In Use" status
    final color = (isAssigned || status.toLowerCase() == 'in use')
        ? AppTheme.secondaryColor 
        : AppTheme.getStatusColor(status);
    // Show "Assigned" text if tool is assigned, otherwise show the status
    final displayText = isAssigned ? 'Assigned' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildCompactConditionChip(String condition) {
    final color = AppTheme.getConditionColor(condition);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if this tool is already assigned to the current user
        final isAssignedToCurrentUser = _currentTool.assignedTo == authProvider.userId;
        final isTechnician = authProvider.userRole != null && authProvider.userRole!.name == 'technician';
        
        return Column(
          children: [
            // Primary Action Button - Show assign if available and not assigned, or reassign if assigned
            // Hide reassign button for technicians
            if (!isTechnician) ...[
              if (_currentTool.status == 'Available' && !isAssignedToCurrentUser && _currentTool.assignedTo == null)
              _buildFilledActionButton(
                label: 'Assign to Technician',
                icon: Icons.person_add,
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.85)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ToolsScreen(isSelectionMode: true),
                    ),
                  );
                },
              )
              else if (_currentTool.assignedTo != null)
              _buildFilledActionButton(
                label: 'Reassign Tool',
                icon: Icons.swap_horiz,
                colors: [AppTheme.accentColor, AppTheme.accentColor.withValues(alpha: 0.85)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReassignToolScreen(tool: _currentTool),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 12),

            // Badge System for Technicians
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isTechnician = authProvider.userRole != null && authProvider.userRole!.name == 'technician';
                if (!isTechnician || _currentTool.status != 'Available') {
                  return const SizedBox.shrink();
                }

                final hasBadge = _currentTool.toolType == 'shared' &&
                    (_currentTool.assignedTo != null && _currentTool.assignedTo!.isNotEmpty);

                if (!hasBadge) {
                  return _buildFilledActionButton(
                    label: 'Badge Tool (I have this)',
                    icon: Icons.badge,
                    colors: [Colors.orange.shade600, Colors.orange.shade700],
                    onTap: _badgeTool,
                  );
                } else if (_currentTool.assignedTo == authProvider.userId) {
                  return _buildFilledActionButton(
                    label: 'Release Badge',
                    icon: Icons.badge_outlined,
                    colors: [Colors.grey.shade700, Colors.grey.shade500],
                    onTap: _releaseBadge,
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            // Request Button for Technicians viewing shared tools assigned to someone else
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isTechnician = authProvider.userRole != null && authProvider.userRole!.name == 'technician';
                final currentUserId = authProvider.userId;
                
                // Show Request button for shared tools that have a holder (badged to someone else)
                // Match the carousel logic: show if tool is shared, has an assignedTo, and it's not the current user
                if (isTechnician &&
                    _currentTool.toolType == 'shared' &&
                    _currentTool.assignedTo != null &&
                    _currentTool.assignedTo!.isNotEmpty &&
                    (currentUserId == null || currentUserId != _currentTool.assignedTo)) {
                  return _buildFilledActionButton(
                    label: 'Request Tool',
                    icon: Icons.request_quote,
                    colors: [AppTheme.secondaryColor, AppTheme.secondaryColor.withValues(alpha: 0.85)],
                    onTap: () => _sendToolRequest(context),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 12),

            // Secondary Action Buttons - Hide Edit button for technicians
            if (!isTechnician)
            Row(
              children: [
                Expanded(
                  child: _buildOutlinedActionButton(
                    label: _currentTool.status == 'Maintenance' 
                        ? 'Complete Maint.' 
                        : 'Mark for Maint.',
                    icon: _currentTool.status == 'Maintenance' 
                        ? Icons.check_circle 
                        : Icons.build,
                    color: _currentTool.status == 'Maintenance' 
                        ? Colors.green 
                        : AppTheme.primaryColor,
                    onTap: _scheduleMaintenance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOutlinedActionButton(
                    label: 'Edit',
                    icon: Icons.edit,
                    color: AppTheme.primaryColor,
                    onTap: _editTool,
                  ),
                ),
              ],
              )
            else
              // For technicians, only show maintenance button
              _buildOutlinedActionButton(
                label: _currentTool.status == 'Maintenance' 
                    ? 'Complete Maint.' 
                    : 'Mark for Maint.',
                icon: _currentTool.status == 'Maintenance' 
                    ? Icons.check_circle 
                    : Icons.build,
                color: _currentTool.status == 'Maintenance' 
                    ? Colors.green 
                    : AppTheme.primaryColor,
                onTap: _scheduleMaintenance,
            ),

            // Additional Actions
            if (_currentTool.status == 'In Use' && _currentTool.assignedTo != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildOutlinedActionButton(
                  label: 'Temporary Return',
                  icon: Icons.holiday_village,
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TemporaryReturnScreen(tool: _currentTool),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilledActionButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        // No shadows - clean design
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(18), // Match card decoration
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        // No shadows - clean design
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18), // Match card decoration
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _calculateDepreciation() {
    if (_currentTool.purchasePrice == null || _currentTool.currentValue == null) {
      return 'N/A';
    }
    
    final depreciation = _currentTool.purchasePrice! - _currentTool.currentValue!;
    final percentage = (depreciation / _currentTool.purchasePrice!) * 100;
    
    return '${CurrencyFormatter.formatCurrency(depreciation)} (${percentage.toStringAsFixed(1)}%)';
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        _editTool();
        break;
      case 'image':
        _addImage();
        break;
      case 'shared':
        _toggleToolShared();
        break;
      case 'maintenance':
        _scheduleMaintenance();
        break;
      case 'history':
        _viewHistory();
        break;
      case 'delete':
        _deleteTool();
        break;
    }
  }

  void _editTool() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditToolScreen(tool: _currentTool),
      ),
    ).then((updatedTool) {
      if (updatedTool != null) {
        setState(() {
          _currentTool = updatedTool;
        });
      }
    });
  }

  void _addImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _isLoading = true;
        });
        
        // Update tool with image path
        final updatedTool = _currentTool.copyWith(imagePath: image.path);
        await context.read<SupabaseToolProvider>().updateTool(updatedTool);
        
        setState(() {
          _currentTool = updatedTool;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<PopupMenuEntry<String>> _buildAppBarMenuItems(ThemeData theme) {
    final textColor = theme.colorScheme.onSurface;
    final iconColor = textColor;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isTechnician = authProvider.userRole != null && authProvider.userRole!.name == 'technician';
    
    return [
      // Hide Edit Tool menu item for technicians
      if (!isTechnician)
      _buildMenuItem(
        value: 'edit',
        icon: Icons.edit_outlined,
        label: 'Edit Tool',
        textColor: textColor,
        iconColor: AppTheme.secondaryColor, // Use app green
      ),
      _buildMenuItem(
        value: 'image',
        icon: Icons.camera_alt_outlined,
        label: 'Add Photo',
        textColor: textColor,
        iconColor: AppTheme.secondaryColor, // Use app green
      ),
      _buildMenuItem(
        value: 'shared',
        icon: _currentTool.toolType == 'shared'
            ? Icons.share
            : Icons.share_outlined,
        label: _currentTool.toolType == 'shared'
            ? 'Make Tool Inventory'
            : 'Make Tool Shared',
        textColor: textColor,
        iconColor: AppTheme.secondaryColor, // Use app green
      ),
      _buildMenuItem(
        value: 'maintenance',
        icon: _currentTool.status == 'Maintenance'
            ? Icons.check_circle_outline
            : Icons.build_outlined,
        label: _currentTool.status == 'Maintenance'
            ? 'Complete Maintenance'
            : 'Mark for Maintenance',
        textColor: textColor,
        iconColor: _currentTool.status == 'Maintenance'
            ? Colors.green
            : AppTheme.secondaryColor, // Use app green for mark, green for complete
      ),
      _buildMenuItem(
        value: 'history',
        icon: Icons.history_outlined,
        label: 'View History',
        textColor: textColor,
        iconColor: AppTheme.secondaryColor, // Use app green
      ),
      _buildMenuDivider(),
      _buildMenuItem(
        value: 'delete',
        icon: Icons.delete_outline,
        label: 'Delete Tool',
        textColor: Colors.red,
        iconColor: Colors.red,
        fontWeight: FontWeight.w600,
      ),
    ];
  }

  PopupMenuEntry<String> _buildMenuDivider() {
    final theme = Theme.of(context);
    return PopupMenuItem<String>(
      enabled: false,
      height: 12,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color textColor,
    required Color iconColor,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 52,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleToolShared() async {
    final toolProvider = context.read<SupabaseToolProvider>();
    final isShared = _currentTool.toolType == 'shared';
    final newToolType = isShared ? 'inventory' : 'shared';
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Create updated tool with new tool type
      final updatedTool = _currentTool.copyWith(
        toolType: newToolType,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await toolProvider.updateTool(updatedTool);
      
      // Reload tools to ensure the change is reflected everywhere
      await toolProvider.loadTools();

      setState(() {
        _currentTool = updatedTool;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isShared 
                        ? 'Tool changed to inventory. It will no longer appear in shared tools.' 
                        : 'Tool is now shared! It will appear in the shared tools section.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 3),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error updating tool type: ${e.toString()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 3),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      }
    }
  }

  void _scheduleMaintenance() async {
    final toolProvider = context.read<SupabaseToolProvider>();
    final isInMaintenance = _currentTool.status == 'Maintenance';
    
    try {
      setState(() {
        _isLoading = true;
      });

      // Create updated tool with new status
      final updatedTool = Tool(
        id: _currentTool.id,
        name: _currentTool.name,
        category: _currentTool.category,
        brand: _currentTool.brand,
        model: _currentTool.model,
        serialNumber: _currentTool.serialNumber,
        purchaseDate: _currentTool.purchaseDate,
        purchasePrice: _currentTool.purchasePrice,
        currentValue: _currentTool.currentValue,
        condition: _currentTool.condition,
        location: _currentTool.location,
        assignedTo: _currentTool.assignedTo,
        status: isInMaintenance ? 'Available' : 'Maintenance',
        toolType: _currentTool.toolType,
        imagePath: _currentTool.imagePath,
        notes: _currentTool.notes,
        createdAt: _currentTool.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await toolProvider.updateTool(updatedTool);

      setState(() {
        _currentTool = updatedTool;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInMaintenance 
                  ? 'Maintenance completed! Tool is now available.' 
                  : 'Tool marked for maintenance.',
            ),
            backgroundColor: isInMaintenance ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating maintenance status: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _badgeTool() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Badge Tool'),
        content: Text('Are you sure you want to badge yourself as having this tool? This will notify other technicians that you have it temporarily.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performBadgeTool();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Badge Tool'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBadgeTool() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update tool status to "In Use" and assign to current user
      final authProvider = context.read<AuthProvider>();
      final toolProvider = context.read<SupabaseToolProvider>();
      
      final updatedTool = _currentTool.copyWith(
        status: 'In Use',
        assignedTo: authProvider.userId,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await toolProvider.updateTool(updatedTool);
      
      // Reload tools to ensure other technicians see the update
      await toolProvider.loadTools();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tool badged successfully! Other technicians will see you have this tool.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Update the current tool
        setState(() {
          _currentTool = updatedTool;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error badging tool: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _releaseBadge() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final toolProvider = context.read<SupabaseToolProvider>();

      final updatedTool = _currentTool.copyWith(
        status: 'Available',
        assignedTo: null,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await toolProvider.updateTool(updatedTool);
      await toolProvider.loadTools();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Badge released. Tool is now available to others.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          _currentTool = updatedTool;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error releasing badge: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendToolRequest(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final requesterId = auth.user?.id;
    final requesterName = auth.userFullName ?? 'Unknown Technician';
    final requesterEmail = auth.user?.email ?? 'unknown@technician';
    
    if (requesterId == null) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'You need to be signed in to request a tool.',
      );
      return;
    }
    
    final ownerId = _currentTool.assignedTo;
    if (ownerId == null || ownerId.isEmpty) {
      AuthErrorHandler.showErrorSnackBar(
        context,
        'This tool is not assigned to anyone.',
      );
      return;
    }
    
    try {
      // Get owner email from users table
      String ownerEmail = 'unknown@owner';
      try {
        final userResponse = await SupabaseService.client
            .from('users')
            .select('email')
            .eq('id', ownerId)
            .maybeSingle();
        
        if (userResponse != null && userResponse['email'] != null) {
          ownerEmail = userResponse['email'] as String;
        }
      } catch (e) {
        debugPrint('Could not fetch owner email: $e');
      }
      
      // Note: Approval workflows are automatically created by the database function
      // when create_admin_notification is called with type 'tool_request'
      
      // Create notification in admin_notifications table (for admin visibility)
      try {
        await SupabaseService.client.rpc(
          'create_admin_notification',
          params: {
            'p_title': 'Tool Request: ${_currentTool.name}',
            'p_message': '$requesterName requested the tool "${_currentTool.name}"',
            'p_technician_name': requesterName,
            'p_technician_email': requesterEmail,
            'p_type': 'tool_request',
            'p_data': {
              'tool_id': _currentTool.id,
              'tool_name': _currentTool.name,
              'requester_id': requesterId,
              'requester_name': requesterName,
              'requester_email': requesterEmail,
              'owner_id': ownerId,
            },
          },
        );
        debugPrint('✅ Created admin notification for tool request');
      } catch (e) {
        debugPrint('⚠️ Failed to create admin notification: $e');
      }
      
      // Create notification in technician_notifications table for the tool owner
      // This will appear in the technician's notification center
      try {
        await SupabaseService.client.from('technician_notifications').insert({
          'user_id': ownerId, // The technician who has the tool
          'title': 'Tool Request: ${_currentTool.name}',
          'message': '$requesterName needs the tool "${_currentTool.name}" that you currently have',
          'type': 'tool_request',
          'is_read': false,
          'timestamp': DateTime.now().toIso8601String(),
          'data': {
            'tool_id': _currentTool.id,
            'tool_name': _currentTool.name,
            'requester_id': requesterId,
            'requester_name': requesterName,
            'requester_email': requesterEmail,
            'owner_id': ownerId,
          },
        });
        debugPrint('✅ Created technician notification for tool request');
        debugPrint('✅ Notification sent to technician: $ownerId');
        
        // Send push notification to the tool holder
        try {
          await PushNotificationService.sendToUser(
            userId: ownerId,
            title: 'Tool Request: ${_currentTool.name}',
            body: '$requesterName needs the tool "${_currentTool.name}" that you currently have',
            data: {
              'type': 'tool_request',
              'tool_id': _currentTool.id,
              'requester_id': requesterId,
            },
          );
          debugPrint('✅ Push notification sent to tool holder');
        } catch (pushError) {
          debugPrint('⚠️ Could not send push notification to tool holder: $pushError');
        }
      } catch (e) {
        debugPrint('❌ Failed to create technician notification: $e');
        debugPrint('❌ Error details: ${e.toString()}');
        // Still show success message even if notification fails
      }
      
      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Tool request sent to ${_currentTool.assignedTo == requesterId ? 'the owner' : 'the tool holder'}',
        );
      }
    } catch (e) {
      debugPrint('Error sending tool request: $e');
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to send request: $e',
        );
      }
    }
  }

  void _viewHistory() {
    // TODO: Implement history view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tool history coming soon!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _deleteTool() {
    // Check if tool is currently assigned
    if (_currentTool.status == 'In Use' && _currentTool.assignedTo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete tool that is currently assigned. Please return it first.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Capture the screen's navigator and scaffold messenger before showing dialog
    final screenNavigator = Navigator.of(context);
    final screenScaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Tool'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${_currentTool.name}"?'),
              SizedBox(height: 12),
              Text(
                'This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• The tool and all its data'),
              Text('• All maintenance records'),
              Text('• All usage history'),
              Text('• All reported issues'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'This action cannot be undone!',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Close confirmation dialog first
                Navigator.pop(dialogContext);
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final toolName = _currentTool.name;
                final toolId = _currentTool.id!;
                final toolProvider = context.read<SupabaseToolProvider>();
                
                // Delete from database first
                await SupabaseService.client.from('tools').delete().eq('id', toolId);
                
                // Update local state immediately for instant UI feedback
                toolProvider.removeToolFromList(toolId);
                
                // Clear loading state and navigate immediately
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  
                  // Navigate back using the screen's navigator
                  screenNavigator.pop();
                  
                  // Show success message after a short delay
                  Future.delayed(Duration(milliseconds: 100), () {
                    screenScaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Tool "$toolName" deleted successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                }
                
                // Reload tools in background to ensure full sync
                toolProvider.loadTools().catchError((e) {
                  debugPrint('Error reloading tools after deletion: $e');
                });
              } catch (e) {
                debugPrint('❌ Error deleting tool: $e');
                
                if (mounted) {
                  String errorMessage = 'Failed to delete tool. ';
                  if (e.toString().contains('active assignments')) {
                    errorMessage += 'This tool is currently assigned to a technician. Please return it first.';
                  } else if (e.toString().contains('permission')) {
                    errorMessage += 'You do not have permission to delete this tool.';
                  } else if (e.toString().contains('network')) {
                    errorMessage += 'Network error. Please check your connection.';
                  } else if (e.toString().contains('timeout')) {
                    errorMessage += 'Request timed out. Please check your connection and try again.';
                  } else {
                    errorMessage += 'Please try again. Error: ${e.toString()}';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } finally {
                // Clear loading state if still mounted (in case of error)
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
                debugPrint('🔧 Finally block - cleaning up');
              }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
