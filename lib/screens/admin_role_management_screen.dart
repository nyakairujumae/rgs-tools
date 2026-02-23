import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../services/supabase_service.dart';

class AdminRoleManagementScreen extends StatefulWidget {
  const AdminRoleManagementScreen({super.key});

  @override
  State<AdminRoleManagementScreen> createState() => _AdminRoleManagementScreenState();
}

class _AdminRoleManagementScreenState extends State<AdminRoleManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(String userId, UserRole newRole) async {
    try {
      await SupabaseService.client
          .from('users')
          .update({'role': newRole.value})
          .eq('id', userId);

      // Update local list
      setState(() {
        final userIndex = _users.indexWhere((user) => user['id'] == userId);
        if (userIndex != -1) {
          _users[userIndex]['role'] = newRole.value;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to ${newRole.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      final email = user['email']?.toLowerCase() ?? '';
      final fullName = user['full_name']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return email.contains(query) || fullName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('User Role Management'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Builder(
            builder: (builderContext) => Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: builderContext.chatGPTInputDecoration.copyWith(
                  hintText: 'Search users by email or name...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: context.placeholderIcon,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No users found' : 'No users match your search',
                              style: AppTheme.heading3.copyWith(
                                color: context.placeholderIcon,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'Users will appear here once they register'
                                  : 'Try a different search term',
                              style: AppTheme.bodyMedium.copyWith(
                                color: context.hintTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final currentRole = UserRoleExtension.fromString(user['role'] ?? 'technician');
                          final currentUserId = context.read<AuthProvider>().userId;
                          final isCurrentUser = user['id'] == currentUserId;

                          return Card(
                            color: Theme.of(context).cardTheme.color,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isCurrentUser 
                                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                    : Colors.grey.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // User Avatar
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: currentRole == UserRole.admin 
                                          ? Colors.blue.withValues(alpha: 0.2)
                                          : Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Icon(
                                      currentRole == UserRole.admin 
                                          ? Icons.admin_panel_settings 
                                          : Icons.person,
                                      color: currentRole == UserRole.admin ? Colors.blue : Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  
                                  SizedBox(width: 16),
                                  
                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              user['full_name'] ?? 'Unknown User',
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (isCurrentUser) ...[
                                              SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'You',
                                                  style: TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          user['email'] ?? '',
                                          style: TextStyle(
                                            color: context.placeholderIcon,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: currentRole == UserRole.admin 
                                                    ? Colors.blue.withValues(alpha: 0.2)
                                                    : Colors.green.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                currentRole.displayName,
                                                style: TextStyle(
                                                  color: currentRole == UserRole.admin ? Colors.blue : Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Role Change Button
                                  if (!isCurrentUser)
                                    PopupMenuButton<UserRole>(
                                      icon: Icon(Icons.more_vert, color: Colors.grey),
                                      onSelected: (UserRole newRole) {
                                        _showRoleChangeDialog(user, currentRole, newRole);
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem<UserRole>(
                                          value: UserRole.admin,
                                          enabled: currentRole != UserRole.admin,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.admin_panel_settings,
                                                color: currentRole == UserRole.admin ? Colors.grey : Colors.blue,
                                                size: 20,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Make Admin',
                                                style: TextStyle(
                                                  color: currentRole == UserRole.admin ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<UserRole>(
                                          value: UserRole.technician,
                                          enabled: currentRole != UserRole.technician,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                color: currentRole == UserRole.technician ? Colors.grey : Colors.green,
                                                size: 20,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Make Technician',
                                                style: TextStyle(
                                                  color: currentRole == UserRole.technician ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeDialog(
    Map<String, dynamic> user,
    UserRole currentRole,
    UserRole newRole,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Change User Role',
          style: AppTheme.heading3.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Are you sure you want to change ${user['full_name'] ?? 'this user'}\'s role from ${currentRole.displayName} to ${newRole.displayName}?',
          style: AppTheme.bodyMedium.copyWith(color: context.dividerColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUserRole(user['id'], newRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == UserRole.admin ? Colors.blue : Colors.green,
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            child: Text('Change to ${newRole.displayName}'),
          ),
        ],
      ),
    );
  }
}
