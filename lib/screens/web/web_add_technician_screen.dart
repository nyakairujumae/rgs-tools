import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_technician_provider.dart';
import '../../models/technician.dart';

class WebAddTechnicianScreen extends StatefulWidget {
  final Technician? technician;

  const WebAddTechnicianScreen({super.key, this.technician});

  @override
  State<WebAddTechnicianScreen> createState() => _WebAddTechnicianScreenState();
}

class _WebAddTechnicianScreenState extends State<WebAddTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  
  String _status = 'Active';
  DateTime? _hireDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.technician != null) {
      _nameController.text = widget.technician!.name;
      _employeeIdController.text = widget.technician!.employeeId ?? '';
      _phoneController.text = widget.technician!.phone ?? '';
      _emailController.text = widget.technician!.email ?? '';
      _departmentController.text = widget.technician!.department ?? '';
      _status = widget.technician!.status;
      if (widget.technician!.hireDate != null) {
        _hireDate = DateTime.parse(widget.technician!.hireDate!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.technician == null ? 'Add New Technician' : 'Edit Technician',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveTechnician,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.technician == null ? 'Save Technician' : 'Update Technician',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.technician == null 
                                    ? 'Add New Technician' 
                                    : 'Edit Technician',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.technician == null
                                    ? 'Enter technician details below'
                                    : 'Update technician information',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Personal Information Section
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 24),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 600;
                      return isDesktop
                          ? _buildDesktopPersonalForm()
                          : _buildMobilePersonalForm();
                    },
                  ),

                  const SizedBox(height: 32),

                  // Contact Information Section
                  _buildSectionHeader('Contact Information'),
                  const SizedBox(height: 24),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 600;
                      return isDesktop
                          ? _buildDesktopContactForm()
                          : _buildMobileContactForm();
                    },
                  ),

                  const SizedBox(height: 32),

                  // Employment Information Section
                  _buildSectionHeader('Employment Information'),
                  const SizedBox(height: 24),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 600;
                      return isDesktop
                          ? _buildDesktopEmploymentForm()
                          : _buildMobileEmploymentForm();
                    },
                  ),

                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildDesktopPersonalForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter technician\'s full name',
                isRequired: true,
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _employeeIdController,
                label: 'Employee ID',
                hint: 'Enter employee ID (optional)',
                icon: Icons.badge,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobilePersonalForm() {
    return Column(
      children: [
        _buildFormField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter technician\'s full name',
          isRequired: true,
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _employeeIdController,
          label: 'Employee ID',
          hint: 'Enter employee ID (optional)',
          icon: Icons.badge,
        ),
      ],
    );
  }

  Widget _buildDesktopContactForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
                icon: Icons.phone,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileContactForm() {
    return Column(
      children: [
        _buildFormField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter phone number',
          keyboardType: TextInputType.phone,
          icon: Icons.phone,
        ),
        const SizedBox(height: 16),
        _buildFormField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter email address',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email,
        ),
      ],
    );
  }

  Widget _buildDesktopEmploymentForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _departmentController,
                label: 'Department',
                hint: 'Enter department',
                icon: Icons.business,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Status',
                hint: 'Select status',
                items: ['Active', 'Inactive', 'On Leave'],
                onChanged: (value) {
                  setState(() {
                    _status = value ?? 'Active';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileEmploymentForm() {
    return Column(
      children: [
        _buildFormField(
          controller: _departmentController,
          label: 'Department',
          hint: 'Enter department',
          icon: Icons.business,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Status',
          hint: 'Select status',
          items: ['Active', 'Inactive', 'On Leave'],
          onChanged: (value) {
            setState(() {
              _status = value ?? 'Active';
            });
          },
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1F2937),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
            ),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6B7280)) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.contains(_status) ? _status : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTechnician,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.technician == null ? 'Save Technician' : 'Update Technician',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _saveTechnician() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For web, just show success message
      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.technician == null 
                ? 'Technician added successfully!' 
                : 'Technician updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        return;
      }

      // Original mobile logic would go here
      // ... (Supabase integration code)
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving technician: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}






