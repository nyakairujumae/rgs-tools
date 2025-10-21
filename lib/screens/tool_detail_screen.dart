import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/tool.dart';
import "../providers/supabase_tool_provider.dart";
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
      appBar: AppBar(
        title: Text(_currentTool.name),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
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
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingMessage: 'Loading tool details...',
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                if (_currentTool.assignedTo != null) _buildInfoRow('Assigned To', _currentTool.assignedTo!),
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
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _currentTool.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _currentTool.imagePath!.startsWith('http')
                  ? Image.network(
                      _currentTool.imagePath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
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
                          height: 200,
                          color: Colors.grey[300],
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
                          height: 200,
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
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
          : Column(
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
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addImage,
                  icon: Icon(Icons.camera_alt, size: 16),
                  label: Text('Add Photo'),
                      style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickStatusCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info,
                    color: AppTheme.getStatusColor(_currentTool.status),
                    size: 20,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  Flexible(
                    child: StatusChip(status: _currentTool.status),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
                    Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assessment,
                    color: AppTheme.getConditionColor(_currentTool.condition),
                    size: 20,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Condition',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  Flexible(
                    child: ConditionChip(condition: _currentTool.condition),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money,
                    color: _currentTool.currentValue != null ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Value',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _currentTool.currentValue != null 
                        ? 'AED ${_currentTool.currentValue!.toStringAsFixed(0)}'
                        : 'N/A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            ),
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? statusWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: statusWidget ?? Text(
                      value,
                      style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignToolScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.person_add),
                  label: Text('Assign to Technician'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else if (_currentTool.status == 'In Use' && _currentTool.assignedTo != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReassignToolScreen(tool: _currentTool),
                      ),
                    );
                  },
                  icon: Icon(Icons.swap_horiz),
                  label: Text('Reassign Tool'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
        
        SizedBox(height: 12),
        
        // Badge System for Technicians
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Show badge button for technicians when tool is available
            if (authProvider.userRole != null && authProvider.userRole!.name == 'technician' && _currentTool.status == 'Available') {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _badgeTool,
                  icon: Icon(Icons.badge),
                  label: Text('Badge Tool (I have this)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
        
        SizedBox(height: 12),
        
        // Secondary Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scheduleMaintenance,
                icon: Icon(Icons.build),
                label: Text('Maintenance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editTool,
                icon: Icon(Icons.edit),
                label: Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
        
        // Additional Actions
        if (_currentTool.status == 'In Use' && _currentTool.assignedTo != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TemporaryReturnScreen(tool: _currentTool),
                    ),
                  );
                },
                icon: Icon(Icons.holiday_village),
                label: Text('Temporary Return'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                  side: const BorderSide(color: AppTheme.secondaryColor),
                ),
              ),
            ),
          ),
        ],
      );
      },
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

