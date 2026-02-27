import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_tool_provider.dart';
import '../../providers/supabase_technician_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/tool.dart';
import '../../screens/tool_detail_screen.dart';
import '../../screens/edit_tool_screen.dart';
import '../../screens/assign_tool_screen.dart';
import '../../utils/currency_formatter.dart';
import 'dart:async';

/// Enterprise Tools Management Screen
/// Professional data table with sorting, filtering, bulk actions
class ToolsManagementWeb extends StatefulWidget {
  const ToolsManagementWeb({Key? key}) : super(key: key);

  @override
  State<ToolsManagementWeb> createState() => _ToolsManagementWebState();
}

class _ToolsManagementWebState extends State<ToolsManagementWeb> {
  // Search & filter state
  String _searchQuery = '';
  Timer? _searchDebounce;
  String? _filterStatus;
  String? _filterCategory;

  // Selection state
  Set<String> _selectedIds = {};

  // Sort state
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  // Pagination
  int _currentPage = 0;
  int _rowsPerPage = 25;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final toolProvider = context.watch<SupabaseToolProvider>();

    // Process data
    var tools = _filterAndSortTools(toolProvider.tools);
    final totalCount = tools.length;
    tools = _paginateTools(tools);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page header
          _buildHeader(isDark, totalCount),
          const SizedBox(height: 24),

          // Toolbar
          _buildToolbar(isDark, totalCount),
          const SizedBox(height: 16),

          // Bulk actions (when items selected)
          if (_selectedIds.isNotEmpty) _buildBulkActionsBar(isDark, toolProvider),

          // Data table
          Expanded(
            child: _buildDataTable(isDark, tools, toolProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, int totalCount) {
    return Row(
      children: [
        Icon(
          Icons.build_circle,
          size: 32,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipment Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '$totalCount items',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDark, int totalCount) {
    return Row(
      children: [
        // Search
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E0E0),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() => _searchQuery = value);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search equipment...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Status filter
        _buildFilterDropdown(
          'Status',
          _filterStatus,
          ['All', 'Available', 'Assigned', 'Maintenance'],
          (value) => setState(() => _filterStatus = value == 'All' ? null : value),
          isDark,
        ),

        const SizedBox(width: 8),

        // Category filter
        _buildFilterDropdown(
          'Category',
          _filterCategory,
          ['All', 'HVAC', 'Electrical', 'Plumbing', 'General'],
          (value) => setState(() => _filterCategory = value == 'All' ? null : value),
          isDark,
        ),

        const SizedBox(width: 16),

        // Export button
        OutlinedButton.icon(
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export functionality - CSV/Excel')),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),

        const SizedBox(width: 8),

        // Add tool button
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Equipment'),
          onPressed: () {
            Navigator.pushNamed(context, '/add-tool');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> options,
    void Function(String?) onChanged,
    bool isDark,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E0E0),
        ),
      ),
      child: DropdownButton<String>(
        value: value ?? 'All',
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBulkActionsBar(bool isDark, SupabaseToolProvider toolProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} selected',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            child: const Text('Deselect all'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.assignment, size: 18),
            label: const Text('Assign'),
            onPressed: () => _bulkAssign(toolProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export Selected'),
            onPressed: () => _bulkExport(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            onPressed: () => _bulkDelete(toolProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(bool isDark, List<Tool> tools, SupabaseToolProvider toolProvider) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Select all checkbox
                SizedBox(
                  width: 56,
                  child: Checkbox(
                    value: _selectedIds.length == tools.length && tools.isNotEmpty,
                    tristate: true,
                    onChanged: (value) {
                      setState(() {
                        if (_selectedIds.length == tools.length) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds = tools.where((t) => t.id != null).map((t) => t.id!).toSet();
                        }
                      });
                    },
                  ),
                ),
                _buildColumnHeader('ID', 0, 80, isDark),
                _buildColumnHeader('Name', 1, 200, isDark),
                _buildColumnHeader('Category', 2, 120, isDark),
                _buildColumnHeader('Status', 3, 120, isDark),
                _buildColumnHeader('Assigned To', 4, 150, isDark),
                _buildColumnHeader('Value', 5, 100, isDark),
                SizedBox(width: 80, child: Center(child: Text('Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),

          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: tools.length,
              itemBuilder: (context, index) => _buildTableRow(tools[index], index, isDark, toolProvider),
            ),
          ),

          // Pagination footer
          _buildPaginationFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String label, int columnIndex, double width, bool isDark) {
    final isActive = _sortColumnIndex == columnIndex;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortColumnIndex == columnIndex) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumnIndex = columnIndex;
            _sortAscending = true;
          }
        });
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Icon(
              isActive
                  ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 16,
              color: isActive ? AppTheme.primaryColor : (isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(Tool tool, int index, bool isDark, SupabaseToolProvider toolProvider) {
    final isSelected = tool.id != null && _selectedIds.contains(tool.id!);
    final techProvider = context.watch<SupabaseTechnicianProvider>();
    final toolId = tool.id ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ToolDetailScreen(tool: tool)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.08)
              : (index.isEven
                  ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA))),
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF0F0F0),
            ),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 56,
              child: Checkbox(
                value: isSelected,
                onChanged: tool.id != null ? (value) {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(tool.id!);
                    } else {
                      _selectedIds.add(tool.id!);
                    }
                  });
                } : null,
              ),
            ),
            _buildCell(toolId.length > 8 ? toolId.substring(0, 8) : toolId, 80, isDark),
            _buildCell(tool.name, 200, isDark),
            _buildCell(tool.category ?? 'N/A', 120, isDark),
            _buildStatusCell(tool.status, 120, isDark),
            _buildCell(
              tool.assignedTo != null
                  ? (techProvider.getTechnicianNameById(tool.assignedTo!) ?? 'Unknown')
                  : 'Unassigned',
              150,
              isDark,
            ),
            _buildCell(CurrencyFormatter.formatCurrency(tool.currentValue ?? 0), 100, isDark),
            _buildActionsCell(tool, toolProvider, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, bool isDark) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusCell(String status, double width, bool isDark) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = AppTheme.successColor;
        break;
      case 'assigned':
        color = AppTheme.warningColor;
        break;
      case 'maintenance':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCell(Tool tool, SupabaseToolProvider toolProvider, bool isDark) {
    return SizedBox(
      width: 80,
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54),
        onSelected: (value) => _handleAction(value, tool, toolProvider),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'view', child: Text('View Details')),
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'assign', child: Text('Assign')),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(bool isDark) {
    final toolProvider = context.watch<SupabaseToolProvider>();
    final filteredTools = _filterAndSortTools(toolProvider.tools);
    final totalPages = (filteredTools.length / _rowsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Text('Rows per page:', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _rowsPerPage,
            items: [25, 50, 100].map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
            onChanged: (v) => setState(() {
              _rowsPerPage = v!;
              _currentPage = 0;
            }),
            underline: const SizedBox.shrink(),
          ),
          const Spacer(),
          Text(
            '${_currentPage * _rowsPerPage + 1}-${((_currentPage + 1) * _rowsPerPage).clamp(0, filteredTools.length)} of ${filteredTools.length}',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  List<Tool> _filterAndSortTools(List<Tool> tools) {
    var result = List<Tool>.from(tools);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) {
        return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (t.id ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (t.category?.toLowerCase()?.contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Status filter
    if (_filterStatus != null) {
      result = result.where((t) => t.status == _filterStatus).toList();
    }

    // Category filter
    if (_filterCategory != null) {
      result = result.where((t) => t.category == _filterCategory).toList();
    }

    // Sorting
    result.sort((a, b) {
      int comparison = 0;
      switch (_sortColumnIndex) {
        case 0:
          comparison = (a.id ?? '').compareTo(b.id ?? '');
          break;
        case 1:
          comparison = a.name.compareTo(b.name);
          break;
        case 2:
          comparison = (a.category ?? '').compareTo(b.category ?? '');
          break;
        case 3:
          comparison = a.status.compareTo(b.status);
          break;
        case 5:
          comparison = (a.currentValue ?? 0).compareTo(b.currentValue ?? 0);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return result;
  }

  List<Tool> _paginateTools(List<Tool> tools) {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, tools.length);
    return tools.sublist(start, end);
  }

  void _handleAction(String action, Tool tool, SupabaseToolProvider toolProvider) {
    switch (action) {
      case 'view':
        Navigator.push(context, MaterialPageRoute(builder: (context) => ToolDetailScreen(tool: tool)));
        break;
      case 'edit':
        Navigator.push(context, MaterialPageRoute(builder: (context) => EditToolScreen(tool: tool)));
        break;
      case 'assign':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignToolScreen()));
        break;
      case 'delete':
        _showDeleteConfirmation(tool, toolProvider);
        break;
    }
  }

  void _showDeleteConfirmation(Tool tool, SupabaseToolProvider toolProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Are you sure you want to delete ${tool.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (tool.id != null) {
                toolProvider.deleteTool(tool.id!);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _bulkAssign(SupabaseToolProvider toolProvider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk assign ${_selectedIds.length} items')),
    );
  }

  void _bulkExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${_selectedIds.length} items')),
    );
  }

  void _bulkDelete(SupabaseToolProvider toolProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Delete ${_selectedIds.length} items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              for (final id in _selectedIds.where((id) => id.isNotEmpty)) {
                toolProvider.deleteTool(id);
              }
              setState(() => _selectedIds.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
