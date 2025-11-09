import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tool.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import 'technician_add_tool_screen.dart';

class TechnicianMyToolsScreen extends StatefulWidget {
  const TechnicianMyToolsScreen({super.key});

  @override
  State<TechnicianMyToolsScreen> createState() => _TechnicianMyToolsScreenState();
}

class _TechnicianMyToolsScreenState extends State<TechnicianMyToolsScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
    });
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      await context.read<SupabaseToolProvider>().loadTools();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _openAddTool() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TechnicianAddToolScreen()),
    );
    if (added == true && mounted) {
      await context.read<SupabaseToolProvider>().loadTools();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Tools'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradientFor(context)),
        child: SafeArea(
          child: Consumer2<SupabaseToolProvider, AuthProvider>(
            builder: (context, toolProvider, authProvider, child) {
              final currentUserId = authProvider.userId;
              final myTools = currentUserId == null
                  ? <Tool>[]
                  : toolProvider.tools
                      .where((tool) => tool.assignedTo == currentUserId)
                      .toList();

              if (_isRefreshing || toolProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: myTools.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradientFor(context),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 56,
                                  color: colorScheme.onSurface.withOpacity(0.45),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tools yet',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use the button below to add tools you currently have. They will appear in the admin tool inventory as well.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.72),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: myTools.length,
                        itemBuilder: (context, index) {
                          final tool = myTools[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ToolCard(tool: tool),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTool,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Tool'),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Tool tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.pushNamed(context, '/tool-detail', arguments: tool);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradientFor(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.18),
                    AppTheme.primaryColor.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.build, color: AppTheme.primaryColor.withOpacity(0.85)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tool.category}${tool.brand != null && tool.brand!.isNotEmpty ? ' • ${tool.brand}' : ''}${tool.model != null && tool.model!.isNotEmpty ? ' • ${tool.model}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _buildTag(context, Icons.badge_outlined, tool.serialNumber ?? 'No Serial'),
                      _buildTag(context, Icons.event, tool.purchaseDate ?? 'No Purchase Date'),
                      _buildStatusTag(context, tool.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(BuildContext context, String status) {
    final theme = Theme.of(context);
    final Color color = AppTheme.getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

