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

  static const Color _roleTechBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('User Role Management'),
        backgroundColor: context.appBarBackground,
        foregroundColor: cs.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: cs.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: cs.onSurface),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: AppTheme.groupedCardDecoration(context),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(color: cs.onSurface, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search users by email or name…',
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: muted, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: muted, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 56, color: muted),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No users found'
                                    : 'No users match your search',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Users will appear here once they register'
                                    : 'Try a different search term',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final currentRole = UserRoleExtension.fromString(
                              user['role'] ?? 'technician');
                          final currentUserId =
                              context.read<AuthProvider>().userId;
                          final isCurrentUser = user['id'] == currentUserId;
                          final isAdmin = currentRole == UserRole.admin;
                          final roleAccent =
                              isAdmin ? AppTheme.primaryColor : _roleTechBlue;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration:
                                  AppTheme.groupedCardDecoration(context),
                              foregroundDecoration: isCurrentUser
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.45),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: roleAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Icon(
                                        isAdmin
                                            ? Icons.admin_panel_settings_outlined
                                            : Icons.person_outline,
                                        color: roleAccent,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  user['full_name'] ??
                                                      'Unknown User',
                                                  style: TextStyle(
                                                    color: cs.onSurface,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor
                                                        .withValues(alpha: 0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    'You',
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .primaryColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user['email'] ?? '',
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: roleAccent
                                                  .withValues(alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              currentRole.displayName,
                                              style: TextStyle(
                                                color: roleAccent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isCurrentUser)
                                      PopupMenuButton<UserRole>(
                                        icon: Icon(Icons.more_vert,
                                            color: muted),
                                        onSelected: (UserRole newRole) {
                                          _showRoleChangeDialog(
                                              user, currentRole, newRole);
                                        },
                                        itemBuilder: (BuildContext menuContext) =>
                                            [
                                          PopupMenuItem<UserRole>(
                                            value: UserRole.admin,
                                            enabled:
                                                currentRole != UserRole.admin,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .admin_panel_settings_outlined,
                                                  color: currentRole ==
                                                          UserRole.admin
                                                      ? muted
                                                      : AppTheme.primaryColor,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Make Admin',
                                                  style: TextStyle(
                                                    color: currentRole ==
                                                            UserRole.admin
                                                        ? muted
                                                        : cs.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<UserRole>(
                                            value: UserRole.technician,
                                            enabled: currentRole !=
                                                UserRole.technician,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  color: currentRole ==
                                                          UserRole.technician
                                                      ? muted
                                                      : _roleTechBlue,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Make Technician',
                                                  style: TextStyle(
                                                    color: currentRole ==
                                                            UserRole.technician
                                                        ? muted
                                                        : cs.onSurface,
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
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final confirmBg = newRole == UserRole.admin
            ? AppTheme.primaryColor
            : _roleTechBlue;
        return AlertDialog(
          title: Text(
            'Change User Role',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to change ${user['full_name'] ?? 'this user'}\'s role from ${currentRole.displayName} to ${newRole.displayName}?',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _updateUserRole(user['id'], newRole);
              },
              style: FilledButton.styleFrom(
                backgroundColor: confirmBg,
                foregroundColor: Colors.white,
              ),
              child: Text('Change to ${newRole.displayName}'),
            ),
          ],
        );
      },
    );
  }
}
