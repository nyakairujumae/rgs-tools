import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/supabase_technician_provider.dart';
import '../models/technician.dart';
import '../services/supabase_service.dart';

class AddTechnicianScreen extends StatefulWidget {
  final Technician? technician;

  const AddTechnicianScreen({super.key, this.technician});

  @override
  State<AddTechnicianScreen> createState() => _AddTechnicianScreenState();
}

class _AddTechnicianScreenState extends State<AddTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  
  String _status = 'Active';
  DateTime? _hireDate;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: Text(
          widget.technician == null ? 'Add Technician' : 'Edit Technician',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveTechnician,
              child: Text(
                widget.technician == null ? 'Save' : 'Update',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person_add,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.technician == null 
                                          ? 'Add New Technician' 
                                          : 'Edit Technician',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      widget.technician == null
                                          ? 'Enter technician details below'
                                          : 'Update technician information',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

                    SizedBox(height: 24),

                    // Form Fields
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Profile Picture Section
                    _buildProfilePictureSection(),
                    SizedBox(height: 16),

                    // Name (Required)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter technician\'s full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter technician\'s name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    // Employee ID
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: InputDecoration(
                        labelText: 'Employee ID',
                        hintText: 'Enter employee ID (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Phone and Email Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              hintText: 'Phone number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Email address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    Text(
                      'Work Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Department
                    TextFormField(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        hintText: 'Enter department name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Status and Hire Date Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.work),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Active', child: Text('Active')),
                              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _status = value!;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectHireDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Hire Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _hireDate != null
                                    ? '${_hireDate!.day}/${_hireDate!.month}/${_hireDate!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  color: _hireDate != null 
                                      ? Theme.of(context).textTheme.bodyLarge?.color 
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveTechnician,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    widget.technician == null ? 'Add Technician' : 'Update Technician',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectHireDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _hireDate = date;
      });
    }
  }

  Future<void> _saveTechnician() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? profilePictureUrl;
      if (_profileImage != null) {
        // Upload image to Supabase storage
        profilePictureUrl = await _uploadProfileImage();
      }

      // Preserve existing profile picture when editing and no new picture selected
      if (profilePictureUrl == null && widget.technician?.profilePictureUrl != null) {
        profilePictureUrl = widget.technician!.profilePictureUrl;
      }

      final technician = Technician(
        id: widget.technician?.id,
        name: _nameController.text.trim(),
        employeeId: _employeeIdController.text.trim().isEmpty ? null : _employeeIdController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        hireDate: _hireDate?.toIso8601String().split('T')[0],
        status: _status,
        profilePictureUrl: profilePictureUrl,
      );

      final technicianProvider = context.read<SupabaseTechnicianProvider>();

      if (widget.technician == null) {
        await technicianProvider.addTechnician(technician);
      } else {
        await technicianProvider.updateTechnician(technician);
      }

      // Refresh list to ensure latest data (including profile urls)
      await technicianProvider.loadTechnicians();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.technician == null 
                  ? 'Technician added successfully!' 
                  : 'Technician updated successfully!'
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oops! Something went wrong. Please try again.'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
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

  Widget _buildProfilePictureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Picture (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Profile Picture Preview
              GestureDetector(
                onTap: _selectProfileImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: _profileImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.file(
                            _profileImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Profile Picture',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap to select from gallery or camera',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selectProfileImage,
                          icon: Icon(Icons.photo_library, size: 16),
                          label: Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _takeProfileImage,
                          icon: Icon(Icons.camera_alt, size: 16),
                          label: Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_profileImage != null)
                IconButton(
                  onPressed: _removeProfileImage,
                  icon: Icon(Icons.close, color: Colors.red),
                  tooltip: 'Remove image',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _takeProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
  }

  Future<String?> _uploadProfileImage() async {
    try {
      if (_profileImage == null) return null;

      // Generate unique filename
      final fileName = 'technician_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profile-pictures/$fileName';

      // Upload to Supabase storage
      final response = await SupabaseService.client.storage
          .from('technician-images')
          .upload(filePath, _profileImage!);

      if (response.isNotEmpty) {
        // Get public URL
        final publicUrl = SupabaseService.client.storage
            .from('technician-images')
            .getPublicUrl(filePath);
        return publicUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
      return null;
    }
  }
}

