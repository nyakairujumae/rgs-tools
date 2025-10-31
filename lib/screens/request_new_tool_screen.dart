import 'package:flutter/material.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request New Tool'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Tool Details',
                  child: Column(
                    children: [
                      _textField(_nameCtrl, label: 'Tool name', hint: 'e.g., Cordless Drill', validator: _req),
                      const SizedBox(height: 12),
                      _textField(_categoryCtrl, label: 'Category', hint: 'e.g., Electrical Tools', validator: _req),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _textField(_brandCtrl, label: 'Brand', hint: 'e.g., Makita')),
                        const SizedBox(width: 12),
                        Expanded(child: _textField(_modelCtrl, label: 'Model', hint: 'e.g., XFD131')),
                      ]),
                      const SizedBox(height: 12),
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

                const SizedBox(height: 16),

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
                      const SizedBox(height: 12),
                      _textField(_siteCtrl, label: 'Site / Location', hint: 'Job site or office pickup'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Justification',
                  child: Column(
                    children: [
                      _multiline(_reasonCtrl, label: 'Why is this needed?', hint: 'Describe reason, job, safety/efficiency impact', validator: _req),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.attachment, color: cs.onSurface.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Attach photo or spec (optional)',
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Attach'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Request'),
                  ),
                ),
              ],
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
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _multiline(
    TextEditingController ctrl, {
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      minLines: 3,
      maxLines: 6,
      validator: validator,
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
        ),
      ),
    );
  }

  Widget _dateField({required String label, required DateTime? value, required VoidCallback onPick}) {
    final text = value == null ? 'Select date' : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request prepared (UI only). Hook backend next.')),
    );
    Navigator.pop(context);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}


