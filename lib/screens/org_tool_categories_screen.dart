import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../theme/app_theme.dart';

/// Settings sub-screen: admin can add/delete org tool categories.
class OrgToolCategoriesScreen extends StatefulWidget {
  const OrgToolCategoriesScreen({super.key});

  @override
  State<OrgToolCategoriesScreen> createState() => _OrgToolCategoriesScreenState();
}

class _OrgToolCategoriesScreenState extends State<OrgToolCategoriesScreen> {
  final _addController = TextEditingController();
  bool _isAdding = false;
  String? _error;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _isAdding = true;
      _error = null;
    });
    try {
      await context.read<OrganizationProvider>().addToolCategory(name);
      _addController.clear();
    } catch (e) {
      setState(() => _error = 'Could not add category. It may already exist.');
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _delete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Remove "$name" from your tool categories?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<OrganizationProvider>().deleteToolCategory(name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete category')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<OrganizationProvider>().toolCategories;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Categories'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Add category
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: InputDecoration(
                      hintText: 'New category name',
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isAdding ? null : _add,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: _isAdding
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Category list
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'No categories yet.\nAdd one above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      return ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: Text(cat),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                          onPressed: () => _delete(cat),
                          tooltip: 'Delete',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
