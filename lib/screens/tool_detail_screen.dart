import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import '../models/tool.dart';
import "../providers/supabase_tool_provider.dart";
import "../providers/supabase_technician_provider.dart";
import "../providers/auth_provider.dart";
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../utils/error_handler.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_helper.dart';
import 'temporary_return_screen.dart';
import 'reassign_tool_screen.dart';
import 'edit_tool_screen.dart';
import 'tools_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentTool = widget.tool;
    _verifyToolExists();
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
            });
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
              _currentTool.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            if (_currentTool.category.isNotEmpty)
              Text(
                _currentTool.category,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Tool'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'image',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, size: 20),
                    SizedBox(width: 8),
                    Text('Add Photo'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'maintenance',
                child: Row(
                  children: [
                    Icon(
                      _currentTool.status == 'Maintenance' 
                          ? Icons.check_circle 
                          : Icons.build, 
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _currentTool.status == 'Maintenance' 
                          ? 'Complete Maintenance' 
                          : 'Mark for Maintenance',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 8),
                    Text('View History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Tool', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Tool Image Section
              _buildImageSection(),
              SizedBox(height: 24),

              // Quick Status Cards
              _buildQuickStatusCards(),
            SizedBox(height: 24),

            // Basic Information
            _buildInfoSection('Basic Information', [
                _buildInfoRow('Name', _currentTool.name),
                _buildInfoRow('Category', _currentTool.category),
                if (_currentTool.brand != null) _buildInfoRow('Brand', _currentTool.brand!),
                if (_currentTool.model != null) _buildInfoRow('Model', _currentTool.model!),
                if (_currentTool.serialNumber != null) _buildInfoRow('Serial Number', _currentTool.serialNumber!),
                if (_currentTool.location != null) _buildInfoRow('Location', _currentTool.location!),
              ]),

              // Status & Assignment
              _buildInfoSection('Status & Assignment', [
                _buildInfoRow('Status', _currentTool.status, statusWidget: StatusChip(status: _currentTool.status)),
                _buildInfoRow('Condition', _currentTool.condition, statusWidget: ConditionChip(condition: _currentTool.condition)),
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

            // Notes
              if (_currentTool.notes != null && _currentTool.notes!.isNotEmpty)
              _buildInfoSection('Notes', [
                  _buildInfoRow('', _currentTool.notes!),
              ]),

            SizedBox(height: 32),

            // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: isDarkMode
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _currentTool.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: _currentTool.imagePath!.startsWith('http')
                  ? Image.network(
                      _currentTool.imagePath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                      errorBuilder: (context, error, stackTrace) {
                        final theme = Theme.of(context);
                        final colorScheme = theme.colorScheme;
                        final isDarkMode = theme.brightness == Brightness.dark;
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: isDarkMode ? colorScheme.surface : Colors.white,
                            borderRadius: BorderRadius.circular(28),
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
                        final theme = Theme.of(context);
                        final colorScheme = theme.colorScheme;
                        final isDarkMode = theme.brightness == Brightness.dark;
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: isDarkMode ? colorScheme.surface : Colors.white,
                            borderRadius: BorderRadius.circular(28),
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
                    )
                  : (!kIsWeb && _currentTool.imagePath != null && !_currentTool.imagePath!.startsWith('http'))
                      ? (io.File(_currentTool.imagePath!).existsSync()
                          ? Image.file(
                              io.File(_currentTool.imagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250,
                            )
                          : Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 64, color: Colors.grey[400]),
                            ))
                      : (_currentTool.imagePath != null && _currentTool.imagePath!.isNotEmpty)
                          ? Image.network(
                              _currentTool.imagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 250,
                                color: Colors.grey[200],
                                child: Icon(Icons.image, size: 64, color: Colors.grey[400]),
                              ),
                            )
                          : Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: isDarkMode ? colorScheme.surface : Colors.white,
                            borderRadius: BorderRadius.circular(28),
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
                        ),
            )
          : Container(
              height: 250,
              decoration: BoxDecoration(
                color: isDarkMode ? colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No image available',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _addImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Add Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickStatusCards() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDarkMode
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(_currentTool.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info,
                    color: AppTheme.getStatusColor(_currentTool.status),
                    size: 24,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Status',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                StatusChip(
                  status: _currentTool.status,
                  label: _currentTool.status == 'Maintenance' ? 'Maint.' : null,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDarkMode
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.getConditionColor(_currentTool.condition).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assessment,
                    color: AppTheme.getConditionColor(_currentTool.condition),
                    size: 24,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Condition',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                ConditionChip(condition: _currentTool.condition),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isDarkMode
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_currentTool.purchasePrice != null ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: _currentTool.purchasePrice != null ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Purchase Price',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _currentTool.purchasePrice != null 
                      ? CurrencyFormatter.formatCurrencyWhole(_currentTool.purchasePrice!)
                      : 'N/A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildInfoSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: isDarkMode
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? statusWidget}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (label.isEmpty) {
      // For notes or long text without label
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if this tool is already assigned to the current user
        final isAssignedToCurrentUser = _currentTool.assignedTo == authProvider.userId;
        
        return Column(
          children: [
            // Primary Action Button - Only show if tool is available AND not assigned to current user
            if (_currentTool.status == 'Available' && !isAssignedToCurrentUser)
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
            else if (_currentTool.status == 'In Use' && _currentTool.assignedTo != null)
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

            const SizedBox(height: 12),

            // Secondary Action Buttons
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
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
        color: isDarkMode ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
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

  void _viewHistory() {
    // TODO: Implement history view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tool history coming soon!'),
        backgroundColor: Colors.blue,
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

