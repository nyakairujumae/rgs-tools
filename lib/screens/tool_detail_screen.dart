import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/tool.dart';
import "../providers/supabase_tool_provider.dart";
import "../providers/supabase_technician_provider.dart";
import "../providers/auth_provider.dart";
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/loading_widget.dart';
import '../utils/error_handler.dart';
import 'assign_tool_screen.dart';
import 'temporary_return_screen.dart';
import 'reassign_tool_screen.dart';
import 'edit_tool_screen.dart';

class ToolDetailScreen extends StatefulWidget {
  final Tool tool;

  const ToolDetailScreen({super.key, required this.tool});

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> with ErrorHandlingMixin {
  late Tool _currentTool;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTool = widget.tool;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradientFor(context),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        _currentTool.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: _handleMenuAction,
                      icon: Icon(Icons.more_vert, color: Colors.black87),
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
              const PopupMenuItem(
                value: 'maintenance',
                child: Row(
                  children: [
                    Icon(Icons.build, size: 20),
                    SizedBox(width: 8),
                    Text('Schedule Maintenance'),
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
              ),
              // Body Content
              Expanded(
                child: LoadingOverlay(
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
                  if (_currentTool.purchasePrice != null) _buildInfoRow('Purchase Price', 'AED ${_currentTool.purchasePrice!.toStringAsFixed(2)}'),
                  if (_currentTool.currentValue != null) _buildInfoRow('Current Value', 'AED ${_currentTool.currentValue!.toStringAsFixed(2)}'),
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradientFor(context),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, size: 48, color: Colors.grey[600]),
                                SizedBox(height: 8),
                                Text('Failed to load image', style: TextStyle(color: Colors.grey[600])),
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
                            gradient: AppTheme.cardGradientFor(context),
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
                  : File(_currentTool.imagePath!).existsSync()
                      ? Image.file(
                          File(_currentTool.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 250,
                        )
                      : Container(
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradientFor(context),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 48, color: Colors.grey[600]),
                                SizedBox(height: 8),
                                Text('Image not found', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ),
            )
          : Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradientFor(context),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No image available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
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
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradientFor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                    color: AppTheme.getStatusColor(_currentTool.status).withOpacity(0.15),
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
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                StatusChip(status: _currentTool.status),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradientFor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                    color: AppTheme.getConditionColor(_currentTool.condition).withOpacity(0.15),
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
                    color: Colors.grey[600],
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
              gradient: AppTheme.cardGradientFor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                    color: (_currentTool.currentValue != null ? Colors.green : Colors.grey).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: _currentTool.currentValue != null ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Value',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _currentTool.currentValue != null 
                      ? 'AED ${_currentTool.currentValue!.toStringAsFixed(0)}'
                      : 'N/A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
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
                color: Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradientFor(context),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
    if (label.isEmpty) {
      // For notes or long text without label
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
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
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
              value,
              style: TextStyle(
                color: Colors.black87,
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
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssignToolScreen(),
                    ),
                  );
                },
              )
            else if (_currentTool.status == 'In Use' && _currentTool.assignedTo != null)
              _buildFilledActionButton(
                label: 'Reassign Tool',
                icon: Icons.swap_horiz,
                colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.85)],
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
                    label: 'Maintenance',
                    icon: Icons.build,
                    color: AppTheme.primaryColor,
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
            color: colors.first.withOpacity(0.3),
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
    
    return 'AED ${depreciation.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)';
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

  void _scheduleMaintenance() {
    // TODO: Implement maintenance scheduling
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maintenance scheduling coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _badgeTool() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Badge Tool'),
        content: Text('Are you sure you want to badge yourself as having this tool? This will notify other technicians that you have it temporarily.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final toolName = _currentTool.name;
                await context.read<SupabaseToolProvider>().deleteTool(_currentTool.id!);
                
                // Force navigation back immediately
                Navigator.of(context).pop();
                
                // Show success message
                Future.delayed(Duration(milliseconds: 100), () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tool "$toolName" deleted successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
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
                // Don't reset loading state if we successfully deleted and navigated away
                // The setState would cause an error since we've popped the screen
                debugPrint('🔧 Finally block - cleaning up');
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

