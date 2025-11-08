import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../models/technician.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'add_technician_screen.dart';
import 'technician_detail_screen.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  Set<String> _selectedTechnicians = <String>{};
  List<String>? _selectedTools;

  @override
  void initState() {
    super.initState();
    // Check if we're coming from assign tool screen with selected tools
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['selectedTools'] != null) {
        setState(() {
          _selectedTools = List<String>.from(args['selectedTools']);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SupabaseTechnicianProvider, SupabaseToolProvider>(
      builder: (context, technicianProvider, toolProvider, child) {
        final technicians = technicianProvider.technicians;
        
        // Get unique departments for filter
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
          
          // Apply selected filter
          if (_selectedFilter != 'All') {
            if (_selectedFilter == 'Active' && tech.status != 'Active') return false;
            if (_selectedFilter == 'Inactive' && tech.status != 'Inactive') return false;
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
            if (departments.contains(_selectedFilter) && tech.department != _selectedFilter) {
              return false;
            }
          }
          
          // Filter by search query
          return _searchQuery.isEmpty ||
              tech.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (tech.employeeId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (tech.department?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: Column(
            children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Technicians',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
                // Assignment Instructions (only show when assigning tools)
                if (_selectedTools != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assign ${_selectedTools!.length} Tool${_selectedTools!.length > 1 ? 's' : ''} to Technicians',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select one or more technicians to assign the tools to',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                
                // Compact Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(24), // Fully rounded pill shape
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: TextField(
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search technicians...',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              
              // Filter Chips
              _buildFilterChips(departments),
              
              // Technicians List
              Expanded(
                child: technicianProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredTechnicians.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No technicians found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add your first technician to get started',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            itemCount: filteredTechnicians.length,
                            itemBuilder: (context, index) {
                              final technician = filteredTechnicians[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _buildTechnicianCard(technician),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
          floatingActionButton: _selectedTools != null 
              ? FloatingActionButton.extended(
                  onPressed: _selectedTechnicians.isNotEmpty ? () {
                    _assignToolsToTechnicians();
                  } : null,
                  icon: Icon(Icons.assignment_turned_in),
                  label: Text(_selectedTechnicians.isNotEmpty 
                      ? 'Assign ${_selectedTools!.length} Tool${_selectedTools!.length > 1 ? 's' : ''} to ${_selectedTechnicians.length} Technician${_selectedTechnicians.length > 1 ? 's' : ''}'
                      : 'Select Technicians First'),
                  backgroundColor: _selectedTechnicians.isNotEmpty 
                      ? Colors.green 
                      : Colors.grey,
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    _showAddTechnicianDialog();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add'),
                  backgroundColor: Colors.blue,
                ),
        );
      },
    );
  }

  Widget _buildTechnicianCard(Technician technician) {
    final isSelected = technician.id != null && _selectedTechnicians.contains(technician.id!);
    
    // Get assigned tools count
    final assignedToolsCount = context.read<SupabaseToolProvider>().tools
        .where((tool) => tool.assignedTo == technician.id)
        .length;
    
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
              builder: (context) => TechnicianDetailScreen(technician: technician),
            ),
          );
        }
      },
      onLongPress: () {
        if (_selectedTools == null) {
          _showEditTechnicianDialog(technician);
        }
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTechnicianAvatar(technician),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              technician.department?.isNotEmpty == true
                                  ? technician.department!
                                  : 'No department',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_selectedTools != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 4),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      _buildStatusChip(technician.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant ??
                            Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.build,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          assignedToolsCount == 0
                              ? 'No tools assigned'
                              : '$assignedToolsCount tool${assignedToolsCount > 1 ? 's' : ''} assigned',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(Technician technician) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          technician.name.isNotEmpty 
              ? technician.name[0].toUpperCase() 
              : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianAvatar(Technician technician) {
    final statusColor = technician.status == 'Active' ? Colors.green : Colors.grey;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 108,
            height: 108,
            color: statusColor.withValues(alpha: 0.15),
            child: (technician.profilePictureUrl != null && technician.profilePictureUrl!.isNotEmpty)
                ? Image.network(
                    technician.profilePictureUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(technician),
                  )
                : _buildPlaceholderAvatar(technician),
          ),
        ),
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(List<String> departments) {
    final filterOptions = ['All', 'Active', 'Inactive', 'With Tools', 'Without Tools', ...departments];
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final filter = filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              labelPadding: EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Theme.of(context).cardTheme.color,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePicture(Technician technician) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: technician.status == 'Active' ? Colors.green : Colors.grey,
      backgroundImage: technician.profilePictureUrl != null
          ? NetworkImage(technician.profilePictureUrl!)
          : null,
      child: technician.profilePictureUrl == null
          ? Text(
              technician.name.isNotEmpty ? technician.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'Active' ? Colors.green : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
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
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Delete Technician',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete ${technician.name}?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<SupabaseTechnicianProvider>().deleteTechnician(technician.id!);
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
      final technicians = technicianProvider.technicians.where((tech) => 
        tech.id != null && _selectedTechnicians.contains(tech.id!)
      ).toList();

      // Assign each tool to each selected technician
      List<String> failedAssignments = [];
      
      for (final toolId in _selectedTools!) {
        for (final technician in technicians) {
          if (technician.email != null && technician.email!.isNotEmpty) {
            // Look up the user ID - check approval status first, then users table
            try {
              final technicianEmail = technician.email!.trim();
              debugPrint('🔍 Looking up user for technician: ${technician.name}');
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
                debugPrint('   No approval record found, checking users table...');
                var userResponse = await SupabaseService.client
                    .from('users')
                    .select('id, email')
                    .ilike('email', technicianEmail)
                    .maybeSingle();
                
                // If not found with ilike, try fetching all and matching
                if (userResponse == null) {
                  debugPrint('   No direct match found, searching all users...');
                  final allUsers = await SupabaseService.client
                      .from('users')
                      .select('id, email');
                  
                  debugPrint('   Found ${(allUsers as List).length} total users');
                  for (var user in allUsers as List) {
                    final userEmail = (user['email'] as String?)?.toLowerCase() ?? '';
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
                debugPrint('⚠️ No user account found for technician: ${technician.name} (${technician.email})');
                debugPrint('   Technician must register in the app and be approved by admin first.');
              }
            } catch (e) {
              debugPrint('Error looking up user for technician ${technician.name}: $e');
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
            backgroundColor: failedCount == totalCount ? Colors.red : Colors.orange,
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


