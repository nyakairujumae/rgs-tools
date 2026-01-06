import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_position.dart';
import '../providers/auth_provider.dart';
import '../services/admin_position_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_helper.dart';

class AddAdminScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAdmin;

  const AddAdminScreen({super.key, this.existingAdmin});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _status = 'Active';
  List<AdminPosition> _positions = [];
  String? _selectedPositionId;
  bool _isLoading = false;
  bool _isLoadingPositions = false;

  bool get _isEdit => widget.existingAdmin != null;

  @override
  void initState() {
    super.initState();
    _loadPositions();
    if (_isEdit) {
      _nameController.text = widget.existingAdmin?['full_name']?.toString() ?? '';
      _emailController.text = widget.existingAdmin?['email']?.toString() ?? '';
      _status = widget.existingAdmin?['status']?.toString() ?? 'Active';
      _selectedPositionId = widget.existingAdmin?['position_id']?.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPositions() async {
    setState(() {
      _isLoadingPositions = true;
    });

    try {
      final positions = await AdminPositionService.getAllPositions();
      setState(() {
        _positions = positions;
        if (_positions.isNotEmpty && _selectedPositionId == null) {
          _selectedPositionId = _positions.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading positions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPositions = false;
        });
      }
    }
  }

  Future<void> _saveAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final positionId = _selectedPositionId;

      if (positionId == null) {
        throw Exception('Please select a position');
      }

      if (_isEdit) {
        final adminId = widget.existingAdmin?['id']?.toString();
        if (adminId == null) throw Exception('Admin not found');

        await SupabaseService.client.rpc('update_admin_user', params: {
          'p_user_id': adminId,
          'p_full_name': name,
          'p_status': _status,
          'p_position_id': positionId,
        });
      } else {
        final userId = await authProvider.createAdminAuthAccount(
          email: email,
          name: name,
          positionId: positionId,
        );

        if (userId != null) {
          await SupabaseService.client.rpc('update_admin_user', params: {
            'p_user_id': userId,
            'p_full_name': name,
            'p_status': _status,
            'p_position_id': positionId,
          });
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Admin updated' : 'Admin added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktopLayout = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Admin' : 'Add Admin'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktopLayout ? 48 : context.spacingLarge,
            vertical: context.spacingLarge,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktopLayout ? 640 : double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEdit ? 'Update admin access' : 'Add a new admin',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.spacingLarge * 1.5),
                    Container(
                      padding: EdgeInsets.all(isDesktopLayout ? 32 : context.spacingLarge),
                      decoration: context.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the full name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: context.spacingMedium),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isEdit,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: context.spacingMedium),
                          _isLoadingPositions
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: _selectedPositionId,
                                  items: _positions
                                      .map(
                                        (position) => DropdownMenuItem(
                                          value: position.id,
                                          child: Text(position.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPositionId = value;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Position',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a position';
                                    }
                                    return null;
                                  },
                                ),
                          SizedBox(height: context.spacingMedium),
                          DropdownButtonFormField<String>(
                            value: _status,
                            items: const [
                              DropdownMenuItem(value: 'Active', child: Text('Active')),
                              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _status = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                          ),
                          SizedBox(height: context.spacingLarge),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(_isEdit ? 'Save Changes' : 'Add Admin'),
                          ),
                        ],
                      ),
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
}
