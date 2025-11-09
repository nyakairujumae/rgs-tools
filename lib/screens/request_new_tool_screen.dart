import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';

class RequestNewToolScreen extends StatefulWidget {
  const RequestNewToolScreen({super.key});

  @override
  State<RequestNewToolScreen> createState() => _RequestNewToolScreenState();
}

class _RequestNewToolScreenState extends State<RequestNewToolScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController(text: '1');
  final TextEditingController _siteCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  DateTime? _neededBy;
  String _priority = 'Normal';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _quantityCtrl.dispose();
    _siteCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/technician',
                            (route) => false,
                          );
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Request New Tool',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the details below to request a new tool',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _SectionCard(
                    title: 'Tool Details',
                    child: Column(
                      children: [
                        _textField(_nameCtrl, label: 'Tool name', hint: 'e.g., Cordless Drill', validator: _req),
                        const SizedBox(height: 16),
                        _textField(_categoryCtrl, label: 'Category', hint: 'e.g., Electrical Tools', validator: _req),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _textField(_brandCtrl, label: 'Brand', hint: 'e.g., Makita')),
                          const SizedBox(width: 12),
                          Expanded(child: _textField(_modelCtrl, label: 'Model', hint: 'e.g., XFD131')),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: _textField(
                              _quantityCtrl,
                              label: 'Quantity',
                              hint: '1',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final n = int.tryParse(v);
                                if (n == null || n <= 0) return 'Enter a valid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdown(
                              label: 'Priority',
                              value: _priority,
                              items: const ['Low', 'Normal', 'High', 'Urgent'],
                              onChanged: (v) => setState(() => _priority = v!),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _SectionCard(
                    title: 'Timing & Location',
                    child: Column(
                      children: [
                        _dateField(
                          label: 'Needed by',
                          value: _neededBy,
                          onPick: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now.add(const Duration(days: 1)),
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _neededBy = picked);
                          },
                        ),
                        const SizedBox(height: 16),
                        _textField(_siteCtrl, label: 'Site / Location', hint: 'Job site or office pickup'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _SectionCard(
                    title: 'Justification',
                    child: Column(
                      children: [
                        _multiline(_reasonCtrl, label: 'Why is this needed?', hint: 'Describe reason, job, safety/efficiency impact', validator: _req),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attachment, color: Colors.blue.shade600, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Attach photo or spec (optional)',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Attach'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade700],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSubmitting ? null : _submit,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          alignment: Alignment.center,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _textField(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 15),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _multiline(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 15),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
        minLines: 3,
        maxLines: 6,
        validator: validator,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
            dropdownColor: AppTheme.cardSurfaceColor(context),
            borderRadius: BorderRadius.circular(20),
            menuMaxHeight: 300,
            onChanged: onChanged,
            items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
          ),
        ),
      ),
    );
  }

  Widget _dateField({required String label, required DateTime? value, required VoidCallback onPick}) {
    final text = value == null ? 'Select date' : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(24),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            filled: true,
            fillColor: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(Icons.event, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: value == null ? Colors.grey[500] : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final authProvider = context.read<AuthProvider>();
    final adminNotificationProvider = context.read<AdminNotificationProvider>();
    final user = authProvider.user;

    setState(() => _isSubmitting = true);

    try {
      final requestData = {
        'tool_name': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'brand': _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        'model': _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
        'quantity': int.parse(_quantityCtrl.text.trim()),
        'priority': _priority,
        'needed_by': _neededBy?.toIso8601String(),
        'site': _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
        'reason': _reasonCtrl.text.trim(),
        'status': 'pending',
        'requested_by': user?.id,
        'requested_by_email': user?.email,
        'requested_by_name': authProvider.userFullName,
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client.from('tool_requests').insert(requestData);

      try {
        await adminNotificationProvider.createNotification(
          technicianName: authProvider.userFullName ?? (user?.email ?? 'Technician'),
          technicianEmail: user?.email ?? 'unknown@technician',
          type: NotificationType.toolRequest,
          title: 'Tool Request: ${_nameCtrl.text.trim()}',
          message: '${authProvider.userFullName ?? 'A technician'} requested ${_quantityCtrl.text.trim()} x ${_nameCtrl.text.trim()}',
          data: {
            'tool_name': _nameCtrl.text.trim(),
            'quantity': _quantityCtrl.text.trim(),
            'priority': _priority,
          },
        );
      } catch (e) {
        debugPrint('Failed to create admin notification: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tool request submitted. Admin will review it soon.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _resetForm();
    } catch (e) {
      debugPrint('Error submitting tool request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _categoryCtrl.clear();
    _brandCtrl.clear();
    _modelCtrl.clear();
    _quantityCtrl.text = '1';
    _siteCtrl.clear();
    _reasonCtrl.clear();
    setState(() {
      _priority = 'Normal';
      _neededBy = null;
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}


