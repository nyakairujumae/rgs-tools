import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/user_name_service.dart';
import '../services/tool_history_service.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';
import '../models/tool_history.dart';
import 'temporary_return_screen.dart';
import 'reassign_tool_screen.dart';
import 'permanent_assignment_screen.dart';
import 'edit_tool_screen.dart';
import 'tools_screen.dart';
import 'image_viewer_screen.dart';
import 'tool_history_screen.dart';
import '../utils/logger.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF5F5F7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            kIsWeb ? Icons.build_rounded : Icons.build_outlined,
            size: kIsWeb ? 40 : 48,
            color: colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
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
      backgroundColor: context.scaffoldBackground,
      extendBodyBehindAppBar: true,
      appBar: kIsWeb
        ? PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, size: 28, color: theme.colorScheme.onSurface),
                      onPressed: () => NavigationHelper.safePop(context),
                      splashRadius: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _currentTool.name,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: _handleMenuAction,
                      icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), size: 24),
                      padding: EdgeInsets.zero,
                      color: context.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => _buildAppBarMenuItems(theme),
                    ),
                  ],
                ),
              ),
            ),
          )
        : AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: kIsWeb ? 900 : double.infinity,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        kIsWeb ? 24 : 0,
                        kIsWeb ? 16 : 0,
                        kIsWeb ? 24 : 0,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!kIsWeb) ...[
                            // Mobile: hero image
                            _buildMobileHeroImage(colorScheme, isDarkMode, theme),
                            const SizedBox(height: 16),
                            // Title + chips
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentTool.name,
                                    style: TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface, letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildCompactStatusChip(_currentTool.status, isAssigned: _currentTool.assignedTo != null),
                                      _buildCompactConditionChip(_currentTool.condition),
                                      if (_currentTool.toolType != null && _currentTool.toolType!.isNotEmpty)
                                        _buildTypePill(_currentTool.toolType!),
                                    ],
                                  ),
                                  if (_currentTool.notes != null && _currentTool.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _currentTool.notes!,
                                      style: TextStyle(
                                        fontSize: 13, height: 1.5,
                                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Details card (web-portal style)
                            _buildMobileDetailsCard(colorScheme, isDarkMode),
                            const SizedBox(height: 12),
                            // Condition & Status actions (admin only)
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) => auth.isAdmin
                                  ? _buildConditionStatusCard(colorScheme, isDarkMode)
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 12),
                            // History card
                            if (_currentTool.id != null)
                              _buildMobileHistoryCard(colorScheme, isDarkMode),
                            const SizedBox(height: 12),
                            // Inline actions card
                            _buildMobileActionsCard(colorScheme, isDarkMode),
                            const SizedBox(height: 16),
                          ] else ...[
                          const SizedBox(height: 8),
                          _buildImageSection(),
                          const SizedBox(height: 20),
                          ],
                          if (kIsWeb) ...[
                            // Web: two-column layout like add tool screen – compact, not elongated
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildInfoSection('Basic Information', [
                                    _buildInfoRow('Name', _currentTool.name),
                                    _buildInfoRow('Category', _currentTool.category),
                                    if (_currentTool.brand != null) _buildInfoRow('Brand', _currentTool.brand!),
                                    if (_currentTool.model != null) _buildInfoRow('Model', _currentTool.model!),
                                    if (_currentTool.serialNumber != null) _buildInfoRow('Serial Number', _currentTool.serialNumber!),
                                    if (_currentTool.location != null) _buildInfoRow('Location', _currentTool.location!),
                                  ], isFirstSection: true),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildInfoSection('Status & Assignment', [
                                    _buildInfoRow('Status', _currentTool.status, statusWidget: _buildCompactStatusChip(_currentTool.status, isAssigned: _currentTool.assignedTo != null)),
                                    _buildInfoRow('Condition', _currentTool.condition, statusWidget: _buildCompactConditionChip(_currentTool.condition)),
                                    if (_currentTool.assignedTo != null)
                                      FutureBuilder<String>(
                                        future: UserNameService.getUserName(_currentTool.assignedTo!),
                                        builder: (context, snapshot) {
                                          final name = snapshot.hasData ? snapshot.data! : 'Unknown';
                                          return _buildInfoRow('Assigned To', name);
                                        },
                                      ),
                                    if (_currentTool.createdAt != null) _buildInfoRow('Added On', _formatDate(_currentTool.createdAt!)),
                                    if (_currentTool.updatedAt != null) _buildInfoRow('Last Updated', _formatDate(_currentTool.updatedAt!)),
                                  ]),
                                ),
                              ],
                            ),
                            Builder(
                              builder: (context) {
                                final hasFinancial = _currentTool.purchasePrice != null || _currentTool.currentValue != null;
                                final hasNotes = _currentTool.notes != null && _currentTool.notes!.isNotEmpty;
                                if (hasFinancial && hasNotes) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildInfoSection('Financial Information', [
                                          if (_currentTool.purchasePrice != null) _buildInfoRow('Purchase Price', CurrencyFormatter.formatCurrency(_currentTool.purchasePrice!)),
                                          if (_currentTool.currentValue != null) _buildInfoRow('Current Value', CurrencyFormatter.formatCurrency(_currentTool.currentValue!)),
                                          if (_currentTool.purchaseDate != null) _buildInfoRow('Purchase Date', _formatDate(_currentTool.purchaseDate!)),
                                          if (_currentTool.purchasePrice != null && _currentTool.currentValue != null)
                                            _buildInfoRow('Depreciation', _calculateDepreciation()),
                                        ]),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildInfoSection('Notes', [
                                          _buildInfoRow('', _currentTool.notes!),
                                        ]),
                                      ),
                                    ],
                                  );
                                }
                                if (hasFinancial) {
                                  return _buildInfoSection('Financial Information', [
                                    if (_currentTool.purchasePrice != null) _buildInfoRow('Purchase Price', CurrencyFormatter.formatCurrency(_currentTool.purchasePrice!)),
                                    if (_currentTool.currentValue != null) _buildInfoRow('Current Value', CurrencyFormatter.formatCurrency(_currentTool.currentValue!)),
                                    if (_currentTool.purchaseDate != null) _buildInfoRow('Purchase Date', _formatDate(_currentTool.purchaseDate!)),
                                    if (_currentTool.purchasePrice != null && _currentTool.currentValue != null)
                                      _buildInfoRow('Depreciation', _calculateDepreciation()),
                                  ]);
                                }
                                if (hasNotes) {
                                  return _buildInfoSection('Notes', [
                                    _buildInfoRow('', _currentTool.notes!),
                                  ]);
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 0 : 16),
                            child: _buildActionButtons(),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  /// Mobile: edge-to-edge hero image with overlaid back/menu buttons and page indicator
  Widget _buildMobileHeroImage(ColorScheme colorScheme, bool isDarkMode, ThemeData theme) {
    final imageUrls = _getToolImageUrls(_currentTool);
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image carousel or placeholder
          if (imageUrls.isNotEmpty)
            PageView.builder(
              controller: _imagePageController,
              itemCount: imageUrls.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(
                    imageUrls: imageUrls,
                    initialIndex: index,
                    toolName: _currentTool.name,
                    status: _currentTool.status,
                    condition: _currentTool.condition,
                  ),
                )),
                child: _buildImageItem(imageUrls[index], colorScheme, isDarkMode),
              ),
            )
          else
            _buildImagePlaceholder(colorScheme),

          // Top buttons: back + menu
          Positioned(
            top: topPadding + 8,
            left: 12, right: 12,
            child: Row(
              children: [
                _heroCircleButton(Icons.arrow_back, () => NavigationHelper.safePop(context)),
              ],
            ),
          ),

          // Page indicator bottom-right
          if (imageUrls.length > 1)
            Positioned(
              bottom: 12, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${imageUrls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroCircleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
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
              borderRadius: BorderRadius.circular(kIsWeb ? 12 : 18),
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
              borderRadius: BorderRadius.circular(kIsWeb ? 12 : 18),
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
        child: Icon(Icons.image, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
      );
    }
    
    // Fallback for other cases
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 18),
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
    final cardRadius = kIsWeb ? 12.0 : 18.0;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: context.cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
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
                                  initialIndex: index,
                                  toolName: _currentTool.name,
                                  status: _currentTool.status,
                                  condition: _currentTool.condition,
                                ),
                              ),
                            );
                          },
                          child: _buildImageItem(
                              imageUrl, colorScheme, isDarkMode),
                        );
                      },
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
                                    : Colors.white.withValues(alpha: 0.4),
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


  Widget _buildTypePill(String type) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // Inline text label chip (e.g. "Condition: Good", "Type: inventory")
  Widget _buildInlineLabel(String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Web-portal-style details card for mobile
  Widget _buildMobileDetailsCard(ColorScheme colorScheme, bool isDarkMode) {
    final theme = Theme.of(context);

    // Build the rows list
    final rows = <_DetailRow>[];
    rows.add(_DetailRow(Icons.label_outline_rounded, 'Category', _currentTool.category));
    if (_currentTool.brand != null && _currentTool.brand!.isNotEmpty)
      rows.add(_DetailRow(Icons.handyman_outlined, 'Brand', _currentTool.brand!));
    if (_currentTool.model != null && _currentTool.model!.isNotEmpty)
      rows.add(_DetailRow(Icons.tag_rounded, 'Model', _currentTool.model!));
    if (_currentTool.serialNumber != null && _currentTool.serialNumber!.isNotEmpty)
      rows.add(_DetailRow(Icons.tag_rounded, 'Serial #', _currentTool.serialNumber!));
    if (_currentTool.location != null && _currentTool.location!.isNotEmpty)
      rows.add(_DetailRow(Icons.location_on_outlined, 'Location', _currentTool.location!));
    rows.add(_DetailRow(
      Icons.person_outline_rounded,
      'Assigned To',
      null,
      assignedUserId: _currentTool.assignedTo,
    ));
    if (_currentTool.purchaseDate != null && _currentTool.purchaseDate!.isNotEmpty)
      rows.add(_DetailRow(Icons.calendar_today_outlined, 'Purchase Date', _formatDate(_currentTool.purchaseDate!)));
    if (_currentTool.purchasePrice != null)
      rows.add(_DetailRow(Icons.attach_money_rounded, 'Purchase Price', CurrencyFormatter.formatCurrency(_currentTool.purchasePrice!)));
    if (_currentTool.currentValue != null)
      rows.add(_DetailRow(Icons.attach_money_rounded, 'Current Value', CurrencyFormatter.formatCurrency(_currentTool.currentValue!)));
    if (_currentTool.purchasePrice != null && _currentTool.currentValue != null)
      rows.add(_DetailRow(Icons.trending_down_rounded, 'Depreciation', _calculateDepreciation()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Details" header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                'Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: colorScheme.onSurface.withValues(alpha: 0.08)),
            // Rows
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  _buildIconDetailRow(row, colorScheme, isDarkMode),
                  if (i < rows.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 52,
                      color: colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                ],
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildIconDetailRow(_DetailRow row, ColorScheme colorScheme, bool isDarkMode) {
    final iconBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : colorScheme.onSurface.withValues(alpha: 0.06);

    Widget valueWidget;
    if (row.assignedUserId != null) {
      valueWidget = FutureBuilder<String>(
        future: UserNameService.getUserName(row.assignedUserId!),
        builder: (context, snapshot) {
          final name = snapshot.hasData ? snapshot.data! : '—';
          return Text(name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ));
        },
      );
    } else {
      final val = row.value ?? '—';
      valueWidget = Text(
        val.isNotEmpty ? val : '—',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(row.icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 0.2,
                    )),
                const SizedBox(height: 2),
                valueWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHistoryCard(ColorScheme colorScheme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FutureBuilder<List<ToolHistory>>(
          future: ToolHistoryService.getHistoryForTool(_currentTool.id!),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? [];
            final preview = entries.take(5).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                  child: Row(
                    children: [
                      Text(
                        'History',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (entries.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ToolHistoryScreen(
                                toolId: _currentTool.id!,
                                toolName: _currentTool.name,
                              ),
                            ),
                          ),
                          child: Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 0.5, color: colorScheme.onSurface.withValues(alpha: 0.08)),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  )
                else
                  ...preview.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return Column(
                      children: [
                        _buildHistoryRow(item, colorScheme, isDarkMode),
                        if (i < preview.length - 1)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 52,
                            color: colorScheme.onSurface.withValues(alpha: 0.06),
                          ),
                      ],
                    );
                  }),
                const SizedBox(height: 4),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryRow(ToolHistory item, ColorScheme colorScheme, bool isDarkMode) {
    final actionColor = _historyActionColor(item.action);
    final actionIcon = _historyActionIcon(item.action);
    final iconBg = actionColor.withValues(alpha: isDarkMode ? 0.18 : 0.1);

    String timeAgo = '';
    if (item.timestamp != null) {
      try {
        final t = DateTime.parse(item.timestamp!).toLocal();
        final diff = DateTime.now().difference(t);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else if (diff.inDays < 30) {
          timeAgo = '${diff.inDays}d ago';
        } else {
          timeAgo = '${t.day}/${t.month}/${t.year}';
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(actionIcon, size: 16, color: actionColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.action,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.performedBy != null && item.performedBy!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'by ${item.performedBy}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _historyActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'assigned': return AppTheme.primaryColor;
      case 'returned': return const Color(0xFF0FA958);
      case 'created': return const Color(0xFF0FA958);
      case 'maintenance': return Colors.orange;
      case 'deleted': return Colors.red;
      case 'transferred': return Colors.purple;
      case 'condition changed': return Colors.orange;
      case 'status changed': return Colors.blue;
      case 'edited':
      case 'updated': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  IconData _historyActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'assigned': return Icons.person_add_rounded;
      case 'returned': return Icons.assignment_return_rounded;
      case 'created': return Icons.add_circle_outline_rounded;
      case 'maintenance': return Icons.build_rounded;
      case 'deleted': return Icons.delete_outline_rounded;
      case 'transferred': return Icons.swap_horiz_rounded;
      case 'condition changed': return Icons.health_and_safety_outlined;
      case 'status changed': return Icons.swap_vert_rounded;
      case 'edited':
      case 'updated': return Icons.edit_outlined;
      default: return Icons.history_rounded;
    }
  }

  Widget _buildConditionStatusCard(ColorScheme colorScheme, bool isDarkMode) {
    final conditions = [
      ('Excellent',    Icons.star_outline_rounded,           const Color(0xFF0FA958)),
      ('Good',         Icons.check_circle_outline_rounded,   const Color(0xFF0FA958)),
      ('Fair',         Icons.thumbs_up_down_outlined,        Colors.orange),
      ('Poor',         Icons.warning_amber_outlined,         Colors.deepOrange),
      ('Needs Repair', Icons.build_circle_outlined,          Colors.red),
    ];

    final inMaintenance = _currentTool.status == 'Maintenance';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Condition ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text('Condition',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
            ),
            Divider(height: 1, thickness: 0.5, color: colorScheme.onSurface.withValues(alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: conditions.map((c) {
                  final label = c.$1;
                  final icon  = c.$2;
                  final color = c.$3;
                  final isActive = _currentTool.condition == label;
                  return GestureDetector(
                    onTap: () {
                      if (!isActive) {
                        _markCondition(label);
                      } else if (label != 'Excellent') {
                        _markCondition('Good');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withValues(alpha: isDarkMode ? 0.22 : 0.12)
                            : colorScheme.onSurface.withValues(alpha: isDarkMode ? 0.06 : 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isActive
                            ? Border.all(color: color.withValues(alpha: 0.5), width: 1.2)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14,
                              color: isActive ? color : colorScheme.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 5),
                          Text(label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? color : colorScheme.onSurface.withValues(alpha: 0.6),
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Maintenance ──────────────────────────────────────────
            Divider(height: 1, thickness: 0.5, color: colorScheme.onSurface.withValues(alpha: 0.08)),
            InkWell(
              onTap: () => _handleMenuAction('maintenance'),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: (inMaintenance ? const Color(0xFF0FA958) : Colors.orange)
                            .withValues(alpha: isDarkMode ? 0.18 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        inMaintenance ? Icons.check_circle_outline_rounded : Icons.build_outlined,
                        size: 16,
                        color: inMaintenance ? const Color(0xFF0FA958) : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        inMaintenance ? 'Complete Maintenance' : 'Mark for Maintenance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: inMaintenance ? const Color(0xFF0FA958) : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, {bool isFirstSection = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i != children.length - 1) {
        spacedChildren.add(const SizedBox(height: 14));
      }
    }

    final sectionPadding = kIsWeb ? 24.0 : 16.0;
    final cardRadius = 18.0;

    // Web: no elongated cards – ChatGPT-like flowing content with section header + divider
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFirstSection)
            Divider(
              height: 24,
              thickness: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(sectionPadding, 8, sectionPadding, 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(sectionPadding, 0, sectionPadding, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: spacedChildren,
            ),
          ),
        ],
      );
    }

    // Mobile: keep card layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(sectionPadding, 20, sectionPadding, 8),
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
          padding: EdgeInsets.symmetric(horizontal: sectionPadding),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: context.cardDecoration.copyWith(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
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
          width: kIsWeb ? 140 : 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = (isAssigned || status.toLowerCase() == 'in use')
        ? AppTheme.secondaryColor 
        : AppTheme.getStatusColor(status);
    final displayText = isAssigned ? 'Assigned' : status;
    final isWeb = ResponsiveHelper.isWeb;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 10 : 6,
        vertical: isWeb ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(isWeb ? 8 : 6),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isWeb ? 12 : 10,
          letterSpacing: isWeb ? -0.1 : 0,
        ),
      ),
    );
  }

  Widget _buildCompactConditionChip(String condition) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = AppTheme.getConditionColor(condition);
    final isWeb = ResponsiveHelper.isWeb;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 10 : 6,
        vertical: isWeb ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(isWeb ? 8 : 6),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isWeb ? 12 : 10,
          letterSpacing: isWeb ? -0.1 : 0,
        ),
      ),
    );
  }

  Widget _buildMobileActionsCard(ColorScheme colorScheme, bool isDarkMode) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAdmin = auth.isAdmin;
        final isShared = _currentTool.toolType == 'shared';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.07),
                  blurRadius: 12, offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Text('Actions',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface)),
                ),
                Divider(height: 1, thickness: 0.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.08)),

                // Edit Tool (admin only)
                if (isAdmin)
                  _buildActionRow(
                    icon: Icons.edit_outlined,
                    iconColor: AppTheme.secondaryColor,
                    label: 'Edit Tool',
                    onTap: () => _handleMenuAction('edit'),
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                  ),

                // Add Photo
                if (isAdmin)
                  Divider(height: 1, thickness: 0.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.06),
                      indent: 56),
                _buildActionRow(
                  icon: Icons.camera_alt_outlined,
                  iconColor: AppTheme.secondaryColor,
                  label: 'Add Photo (${_getToolImageUrls(_currentTool).length}/4)',
                  onTap: () => _handleMenuAction('image'),
                  colorScheme: colorScheme,
                  isDarkMode: isDarkMode,
                ),
                if (_getToolImageUrls(_currentTool).isNotEmpty) ...[
                  Divider(height: 1, thickness: 0.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.06),
                      indent: 56),
                  _buildActionRow(
                    icon: Icons.hide_image_outlined,
                    iconColor: Colors.red,
                    label: 'Remove Current Photo',
                    onTap: () => _handleMenuAction('remove_image'),
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                  ),
                ],

                // Share / Return to Inventory (admin only)
                if (isAdmin) ...[
                  Divider(height: 1, thickness: 0.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.06),
                      indent: 56),
                  _buildActionRow(
                    icon: isShared ? Icons.share : Icons.share_outlined,
                    iconColor: AppTheme.secondaryColor,
                    label: isShared ? 'Return Tool to Inventory' : 'Make Tool Shared',
                    onTap: () => _handleMenuAction('shared'),
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                  ),

                  // Delete Tool
                  Divider(height: 1, thickness: 0.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.08)),
                  _buildActionRow(
                    icon: Icons.delete_outline,
                    iconColor: Colors.red,
                    label: 'Delete Tool',
                    labelColor: Colors.red,
                    onTap: () => _handleMenuAction('delete'),
                    colorScheme: colorScheme,
                    isDarkMode: isDarkMode,
                    isLast: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDarkMode,
    Color? labelColor,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDarkMode ? 0.18 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: labelColor ?? colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
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
                colors: [AppTheme.secondaryColor, AppTheme.secondaryColor.withValues(alpha: 0.85)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PermanentAssignmentScreen(tool: _currentTool),
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
                    label: 'Request from Holder',
                    icon: Icons.handshake,
                    colors: [AppTheme.secondaryColor, AppTheme.secondaryColor.withValues(alpha: 0.85)],
                    onTap: () => _sendToolRequest(context),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 12),


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
    final btnRadius = kIsWeb ? 10.0 : context.borderRadiusLarge;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(btnRadius),
        // No shadows - clean design
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(btnRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: kIsWeb ? 14 : 16,
              horizontal: kIsWeb ? 16 : 0,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: kIsWeb ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: kIsWeb ? -0.1 : 0,
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
    
    final cardRadius = kIsWeb ? 12.0 : 18.0;
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: color.withValues(alpha: isDarkMode ? 0.25 : 0.3),
          width: kIsWeb ? 1 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(cardRadius),
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
                      fontSize: kIsWeb ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: kIsWeb ? -0.05 : 0,
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
      case 'remove_image':
        _removeCurrentImage();
        break;
      case 'shared':
        _toggleToolShared();
        break;
      case 'maintenance':
        _scheduleMaintenance();
        break;
      case 'delete':
        _deleteTool();
        break;
    }
  }

  void _editTool() {
    final toolBeforeEdit = _currentTool;
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
        // Record history for the edit
        if (toolBeforeEdit.id != null) {
          final authProvider = context.read<AuthProvider>();
          final performerName = authProvider.userFullName ?? authProvider.user?.email ?? 'Unknown';
          final performerRole = authProvider.isAdmin ? 'Admin' : 'Technician';
          ToolHistoryService.record(
            toolId: toolBeforeEdit.id!,
            toolName: updatedTool.name,
            action: ToolHistoryActions.edited,
            description: '$performerName edited tool details for "${updatedTool.name}"',
            oldValue: toolBeforeEdit.name,
            newValue: updatedTool.name,
            performedById: authProvider.userId,
            performedByName: performerName,
            performedByRole: performerRole,
            location: updatedTool.location,
          );
          // Notify admins if triggered by a technician
          if (!authProvider.isAdmin) {
            context.read<AdminNotificationProvider>().createNotification(
              technicianName: performerName,
              technicianEmail: authProvider.user?.email ?? '',
              type: NotificationType.general,
              title: 'Tool Edited: ${updatedTool.name}',
              message: '$performerName edited the details for "${updatedTool.name}"',
              data: {'tool_id': toolBeforeEdit.id, 'tool_name': updatedTool.name},
            );
          }
        }
      }
    });
  }

  void _addImage() async {
    try {
      // Check current image count
      final currentImages = _getToolImageUrls(_currentTool);
      if (currentImages.length >= 4) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 4 photos allowed. Remove a photo first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Let user pick source
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // Append to existing images (comma-separated, max 4)
        final existing = _currentTool.imagePath ?? '';
        final newPath = existing.isEmpty ? image.path : '$existing,${image.path}';
        final updatedTool = _currentTool.copyWith(imagePath: newPath);
        await context.read<SupabaseToolProvider>().updateTool(updatedTool);

        setState(() {
          _currentTool = updatedTool;
          _isLoading = false;
          // Jump to the newly added photo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final newIndex = _getToolImageUrls(updatedTool).length - 1;
            _imagePageController.jumpToPage(newIndex);
            _currentImageIndex = newIndex;
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo ${currentImages.length + 1} of 4 added.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeCurrentImage() async {
    final images = _getToolImageUrls(_currentTool);
    if (images.isEmpty) return;

    final indexToRemove = _currentImageIndex.clamp(0, images.length - 1);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo'),
        content: Text(images.length == 1
            ? 'Remove the only photo from this tool?'
            : 'Remove photo ${indexToRemove + 1} of ${images.length}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = List<String>.from(images)..removeAt(indexToRemove);
      final newPath = updated.join(',');
      final updatedTool = _currentTool.copyWith(imagePath: newPath);
      await context.read<SupabaseToolProvider>().updateTool(updatedTool);

      setState(() {
        _currentTool = updatedTool;
        _currentImageIndex = (indexToRemove - 1).clamp(0, (updated.length - 1).clamp(0, 3));
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo removed.'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PopupMenuEntry<String>> _buildAppBarMenuItems(ThemeData theme) {
    final textColor = theme.colorScheme.onSurface;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isTechnician = !authProvider.isAdmin;
    
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
      if (!isTechnician)
      _buildMenuItem(
        value: 'shared',
        icon: _currentTool.toolType == 'shared'
            ? Icons.share
            : Icons.share_outlined,
        label: _currentTool.toolType == 'shared'
            ? 'Return Tool to Inventory'
            : 'Make Tool Shared',
        textColor: textColor,
        iconColor: AppTheme.secondaryColor,
      ),
      // Hide Delete Tool for technicians - admins only
      if (!isTechnician) ...[
        _buildMenuDivider(),
        _buildMenuItem(
          value: 'delete',
          icon: Icons.delete_outline,
          label: 'Delete Tool',
          textColor: Colors.red,
          iconColor: Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ],
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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

      // Record history
      if (_currentTool.id != null && mounted) {
        final authProvider = context.read<AuthProvider>();
        final performerName = authProvider.userFullName ?? authProvider.user?.email ?? 'Unknown';
        final performerRole = authProvider.isAdmin ? 'Admin' : 'Technician';
        ToolHistoryService.record(
          toolId: _currentTool.id!,
          toolName: _currentTool.name,
          action: isShared ? ToolHistoryActions.movedToInventory : ToolHistoryActions.movedToShared,
          description: isShared
              ? '$performerName returned "${_currentTool.name}" to inventory'
              : '$performerName made "${_currentTool.name}" a shared tool',
          oldValue: isShared ? 'shared' : 'inventory',
          newValue: isShared ? 'inventory' : 'shared',
          performedById: authProvider.userId,
          performedByName: performerName,
          performedByRole: performerRole,
          location: _currentTool.location,
        );
        // Notify admins if triggered by a technician
        if (!authProvider.isAdmin) {
          context.read<AdminNotificationProvider>().createNotification(
            technicianName: performerName,
            technicianEmail: authProvider.user?.email ?? '',
            type: NotificationType.general,
            title: isShared
                ? 'Tool Returned to Inventory: ${_currentTool.name}'
                : 'Tool Made Shared: ${_currentTool.name}',
            message: isShared
                ? '$performerName returned "${_currentTool.name}" to inventory'
                : '$performerName made "${_currentTool.name}" available as a shared tool',
            data: {'tool_id': _currentTool.id, 'tool_name': _currentTool.name},
          );
        }
      }

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
                        ? 'Tool returned to inventory. It will no longer appear in shared tools.'
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

      final authProvider = context.read<AuthProvider>();
      final performerName = authProvider.userFullName ?? authProvider.user?.email ?? 'Unknown';
      final performerRole = authProvider.isAdmin ? 'Admin' : 'Technician';
      final performerId = authProvider.userId;

      // Record history
      if (_currentTool.id != null) {
        ToolHistoryService.record(
          toolId: _currentTool.id!,
          toolName: _currentTool.name,
          action: isInMaintenance ? 'Maintenance Completed' : 'Marked for Maintenance',
          description: isInMaintenance
              ? '$performerName completed maintenance on "${_currentTool.name}"'
              : '$performerName marked "${_currentTool.name}" for maintenance',
          oldValue: isInMaintenance ? 'Maintenance' : _currentTool.status,
          newValue: isInMaintenance ? 'Available' : 'Maintenance',
          performedById: performerId,
          performedByName: performerName,
          performedByRole: performerRole,
        );
      }

      // Notify admins if a technician triggered this
      if (!authProvider.isAdmin) {
        context.read<AdminNotificationProvider>().createNotification(
          technicianName: performerName,
          technicianEmail: authProvider.user?.email ?? '',
          type: NotificationType.maintenanceRequest,
          title: isInMaintenance
              ? 'Maintenance Completed: ${_currentTool.name}'
              : 'Maintenance Requested: ${_currentTool.name}',
          message: isInMaintenance
              ? '$performerName completed maintenance on "${_currentTool.name}"'
              : '$performerName marked "${_currentTool.name}" for maintenance',
          data: {'tool_id': _currentTool.id, 'tool_name': _currentTool.name},
        );
      }

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

  void _markCondition(String newCondition) async {
    final toolProvider = context.read<SupabaseToolProvider>();
    try {
      setState(() => _isLoading = true);

      final updatedTool = _currentTool.copyWith(
        condition: newCondition,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await toolProvider.updateTool(updatedTool);
      setState(() {
        _currentTool = updatedTool;
        _isLoading = false;
      });

      final authProvider = context.read<AuthProvider>();
      final performerName = authProvider.userFullName ?? authProvider.user?.email ?? 'Unknown';
      final performerRole = authProvider.isAdmin ? 'Admin' : 'Technician';
      final performerId = authProvider.userId;
      final isRestoring = newCondition == 'Good' || newCondition == 'Excellent';

      // Record history
      if (_currentTool.id != null) {
        ToolHistoryService.record(
          toolId: _currentTool.id!,
          toolName: _currentTool.name,
          action: isRestoring ? 'Condition Restored' : 'Condition Updated',
          description: isRestoring
              ? '$performerName restored condition to Good'
              : '$performerName marked tool as $newCondition',
          oldValue: _currentTool.condition,
          newValue: newCondition,
          performedById: performerId,
          performedByName: performerName,
          performedByRole: performerRole,
        );
      }

      // Notify admins (non-blocking)
      if (!authProvider.isAdmin) {
        final email = authProvider.user?.email ?? '';
        context.read<AdminNotificationProvider>().createNotification(
          technicianName: performerName,
          technicianEmail: email,
          type: NotificationType.issueReport,
          title: 'Tool Condition Update: ${_currentTool.name}',
          message: isRestoring
              ? '$performerName restored "${_currentTool.name}" condition to Good'
              : '$performerName marked "${_currentTool.name}" as $newCondition',
          data: {'tool_id': _currentTool.id, 'tool_name': _currentTool.name, 'condition': newCondition},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRestoring
                  ? 'Tool condition restored to Good.'
                  : 'Tool marked as $newCondition.',
            ),
            backgroundColor: isRestoring ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating condition: ${e.toString()}'),
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

      await ToolHistoryService.record(
        toolId: _currentTool.id!,
        toolName: _currentTool.name,
        action: ToolHistoryActions.badged,
        description: '${authProvider.userFullName ?? 'Technician'} badged this tool (I have it)',
        oldValue: _currentTool.assignedTo,
        newValue: authProvider.userId,
        performedById: authProvider.userId,
        performedByName: authProvider.userFullName,
        performedByRole: authProvider.userRole?.name ?? 'technician',
        location: _currentTool.location,
      );

      // Notify admins that a technician badged this tool
      final performerName = authProvider.userFullName ?? authProvider.user?.email ?? 'Unknown';
      context.read<AdminNotificationProvider>().createNotification(
        technicianName: performerName,
        technicianEmail: authProvider.user?.email ?? '',
        type: NotificationType.general,
        title: 'Tool Badged: ${_currentTool.name}',
        message: '$performerName has taken "${_currentTool.name}" (badged as in use)',
        data: {'tool_id': _currentTool.id, 'tool_name': _currentTool.name},
      );

      // Clear name cache for this user so fresh data is fetched
      UserNameService.clearCacheForUser(authProvider.userId!);
      
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

      final authProvider = context.read<AuthProvider>();
      await ToolHistoryService.record(
        toolId: _currentTool.id!,
        toolName: _currentTool.name,
        action: ToolHistoryActions.releasedBadge,
        description: '${authProvider.userFullName ?? 'Technician'} released the badge. Tool is now available.',
        oldValue: _currentTool.assignedTo,
        newValue: null,
        performedById: authProvider.userId,
        performedByName: authProvider.userFullName,
        performedByRole: authProvider.userRole?.name ?? 'technician',
        location: _currentTool.location,
      );
      
      // Reload tools to ensure fresh data from database
      await toolProvider.loadTools();
      
      // Get the fresh tool data from the provider to ensure UI reflects database state
      final reloadedTool = toolProvider.getToolById(_currentTool.id!);
      final finalTool = reloadedTool ?? updatedTool;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Badge released. Tool is now available to others.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          _currentTool = finalTool;
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
        Logger.debug('Could not fetch owner email: $e');
      }
      
      // Tool requests from holders (badged tools) only go to the tool holder, not admins
      // Create notification in technician_notifications table for the tool owner
      // This will appear in the technician's notification center
      try {
        // Get requester's first name for better message format
        final requesterFirstName = requesterName.split(' ').first;
        
        await SupabaseService.client.from('technician_notifications').insert({
          'user_id': ownerId, // The technician who has the tool
          'title': 'Tool Request: ${_currentTool.name}',
          'message': '$requesterFirstName has requested the ${_currentTool.name}',
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
        Logger.debug('✅ Created technician notification for tool request');
        Logger.debug('✅ Notification sent to technician: $ownerId');
        
        // Send push notification to the tool holder
        try {
          final pushSuccess = await PushNotificationService.sendToUser(
            userId: ownerId,
            title: 'Tool Request: ${_currentTool.name}',
            body: '$requesterFirstName has requested the ${_currentTool.name}',
            data: {
              'type': 'tool_request',
              'tool_id': _currentTool.id,
              'requester_id': requesterId,
            },
          );
          if (pushSuccess) {
            Logger.debug('✅ Push notification sent successfully to tool holder: $ownerId');
          } else {
            Logger.debug('⚠️ Push notification returned false for tool holder: $ownerId');
          }
        } catch (pushError, stackTrace) {
          Logger.debug('❌ Exception sending push notification to tool holder: $pushError');
          Logger.debug('❌ Stack trace: $stackTrace');
        }
      } catch (e) {
        Logger.debug('❌ Failed to create technician notification: $e');
        Logger.debug('❌ Error details: ${e.toString()}');
        // Still show success message even if notification fails
      }
      
      if (mounted) {
        AuthErrorHandler.showSuccessSnackBar(
          context,
          'Tool request sent to ${_currentTool.assignedTo == requesterId ? 'the owner' : 'the tool holder'}',
        );
      }
    } catch (e) {
      Logger.debug('Error sending tool request: $e');
      if (mounted) {
        AuthErrorHandler.showErrorSnackBar(
          context,
          'Failed to send request: $e',
        );
      }
    }
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolHistoryScreen(
          toolId: _currentTool.id!,
          toolName: _currentTool.name,
        ),
      ),
    );
  }

  void _deleteTool() {
    // Block technicians from deleting tools
    final authProvider = context.read<AuthProvider>();
    final isTechnician = authProvider.userRole != null && authProvider.userRole!.name == 'technician';
    if (isTechnician) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can delete tools.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

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
                
                // Use provider to delete (avoids duplicate logic and session issues)
                await toolProvider.deleteTool(toolId);
                
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
                // Do NOT call loadTools() here - it can trigger session refresh/401
                // and log the user out. removeToolFromList already updated local state.
              } catch (e) {
                Logger.debug('❌ Error deleting tool: $e');
                
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
                Logger.debug('🔧 Finally block - cleaning up');
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

/// Simple data holder for mobile detail rows
class _DetailRow {
  final IconData icon;
  final String label;
  final String? value;
  final String? assignedUserId;

  const _DetailRow(this.icon, this.label, this.value, {this.assignedUserId});
}
