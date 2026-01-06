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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Admin Updated' : 'Admin Added Successfully',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (!_isEdit)
                      Text(
                        'An invite email has been sent to $email',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      // Clean up error message
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Failed to Update Admin' : 'Failed to Add Admin',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktopLayout ? 48 : 20,
            vertical: 20,
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
                    // Header icon
                    Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _isEdit ? Icons.edit_outlined : Icons.person_add_alt_1,
                        color: AppTheme.secondaryColor,
                        size: 32,
                      ),
                    ),
                    Text(
                      _isEdit ? 'Update Admin Details' : 'Add New Admin',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEdit 
                          ? 'Update the admin\'s information and permissions'
                          : 'Enter the details for the new admin. They will receive an email to set their password.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Form Card
                    Container(
                      padding: EdgeInsets.all(isDesktopLayout ? 28 : 20),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? context.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name Field
                          _buildLabel('Full Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            decoration: _inputDecoration(
                              hint: 'Enter full name',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Email Field
                          _buildLabel('Email Address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isEdit,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 15,
                              color: _isEdit 
                                  ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                            decoration: _inputDecoration(
                              hint: 'Enter email address',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the email';
                              }
                              return null;
                            },
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Email cannot be changed',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          
                          // Position Dropdown
                          _buildLabel('Position'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                                  value: _selectedPositionId,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: 'Select position',
                                    icon: Icons.badge_outlined,
                                  ),
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a position';
                                    }
                                    return null;
                                  },
                                ),
                          const SizedBox(height: 20),
                          
                          // Status Dropdown
                          _buildLabel('Status'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _status,
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            decoration: _inputDecoration(
                              hint: 'Select status',
                              icon: Icons.toggle_on_outlined,
                            ),
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.secondaryColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEdit ? Icons.check : Icons.person_add,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isEdit ? 'Save Changes' : 'Add Admin',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
        fontSize: 15,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
      ),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor ?? Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.secondaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
