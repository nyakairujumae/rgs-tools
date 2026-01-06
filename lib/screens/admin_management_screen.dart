import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_position_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';
import '../models/admin_position.dart';
import 'add_admin_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _admins = [];
  Map<String, AdminPosition> _positionsById = {};
  bool _canManageAdmins = false;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) return;
      final canManageAdmins = await AdminPositionService.userHasPermission(
        userId,
        'can_manage_admins',
      );
      if (!mounted) return;
      setState(() {
        _canManageAdmins = canManageAdmins;
      });
    } catch (e) {
      debugPrint('❌ Error loading admin permissions: $e');
    }
  }

  Future<void> _loadAdmins() async {
    try {
      // Load positions and admins
      final positions = await AdminPositionService.getAllPositions();
      final positionsById = <String, AdminPosition>{};
      for (final position in positions) {
        positionsById[position.id] = position;
      }

      final response = await SupabaseService.client
          .from('users')
          .select('id, email, full_name, role, position_id, status, created_at')
          .eq('role', 'admin')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _positionsById = positionsById;
        _admins = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading admins: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAddAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAdminScreen(),
      ),
    );
    if (!mounted) return;
    await _loadAdmins();
  }

  Future<void> _openEditAdmin(Map<String, dynamic> admin) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdminScreen(existingAdmin: admin),
      ),
    );
    if (!mounted) return;
    await _loadAdmins();
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    final adminId = admin['id']?.toString();
    final email = admin['email']?.toString() ?? 'this admin';
    final name = admin['full_name']?.toString() ?? 'Admin';
    if (adminId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_remove, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Remove Admin'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove $name ($email) from admin access?\n\nTheir authentication account will remain but they will lose admin privileges.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Remove from local list immediately for instant UI feedback
      setState(() {
        _admins.removeWhere((a) => a['id']?.toString() == adminId);
      });
      
      // Then delete from database
      await SupabaseService.client.from('users').delete().eq('id', adminId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('$name has been removed from admin access'),
            ],
          ),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      // Reload to restore the list if deletion failed
      await _loadAdmins();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to remove admin: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _positionName(String? positionId) {
    if (positionId == null) return 'Unassigned';
    return _positionsById[positionId]?.name ?? 'Unassigned';
  }

  @override
  Widget build(BuildContext context) {
    final canManageAdmins = _canManageAdmins;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admins'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        actions: [
          if (canManageAdmins)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: _openAddAdmin,
            ),
        ],
      ),
      body: ListView.separated(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: _admins.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final admin = _admins[index];
                    final name = admin['full_name']?.toString() ?? 'Admin';
                    final email = admin['email']?.toString() ?? '';
                    final status = admin['status']?.toString() ?? 'Active';
                    final positionName = _positionName(admin['position_id']?.toString());
                    final isActive = status.toLowerCase() == 'active';

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ?? context.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: canManageAdmins ? () => _openEditAdmin(admin) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.secondaryColor.withOpacity(0.8),
                                        AppTheme.secondaryColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isActive 
                                                  ? AppTheme.secondaryColor.withOpacity(0.1)
                                                  : Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : 'Inactive',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isActive ? AppTheme.secondaryColor : Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          positionName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Actions
                                if (canManageAdmins)
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _openEditAdmin(admin);
                                      } else if (value == 'delete') {
                                        _deleteAdmin(admin);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                                            const SizedBox(width: 10),
                                            const Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.person_remove_outlined, size: 18, color: Colors.red),
                                            const SizedBox(width: 10),
                                            const Text('Remove', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

}
