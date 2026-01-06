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
    setState(() {
      _isLoading = true;
    });

    try {
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

      setState(() {
        _positionsById = positionsById;
        _admins = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading admins: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    if (adminId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text('Remove Admin'),
        content: Text('Remove $email from admin access? Their auth account will remain.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.client.from('users').delete().eq('id', adminId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin removed'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing admin: $e'),
          backgroundColor: Colors.red,
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _admins.isEmpty
              ? Center(
                  child: Text(
                    'No admins found',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.grey[500]),
                  ),
                )
              : ListView.separated(
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
                      decoration: context.cardDecoration,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'A',
                              style: TextStyle(color: AppTheme.secondaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildChip(positionName, AppTheme.primaryColor.withOpacity(0.12), AppTheme.primaryColor),
                                    _buildChip(
                                      status,
                                      isActive ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                                      isActive ? Colors.green : Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (canManageAdmins)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEditAdmin(admin);
                                } else if (value == 'delete') {
                                  _deleteAdmin(admin);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Remove'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildChip(String label, Color background, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
