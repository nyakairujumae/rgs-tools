import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/organization_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';

/// Settings → Company configuration: manage org tool categories.
class OrgToolCategoriesScreen extends StatefulWidget {
  const OrgToolCategoriesScreen({super.key});

  @override
  State<OrgToolCategoriesScreen> createState() =>
      _OrgToolCategoriesScreenState();
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Remove "$name" from your tool categories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

  InputDecoration _fieldDecoration(ThemeData theme, bool isDark) {
    final outline = theme.colorScheme.outline.withValues(alpha: 0.35);
    return InputDecoration(
      hintText: 'New category name',
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorText: _error,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = context.watch<OrganizationProvider>().toolCategories;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tool Categories'),
        backgroundColor: context.appBarBackground,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 28, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: AppTheme.groupedCardDecoration(context),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration(theme, isDark),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isAdding ? null : _add,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.groupedCardDecoration(context),
              clipBehavior: Clip.antiAlias,
              child: categories.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 36),
                      child: Center(
                        child: Text(
                          'No categories yet.\nAdd one above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < categories.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.08),
                            ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Icon(
                              Icons.category_outlined,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                            title: Text(
                              categories[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppTheme.errorColor
                                    .withValues(alpha: 0.9),
                              ),
                              onPressed: () => _delete(categories[i]),
                              tooltip: 'Delete',
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
