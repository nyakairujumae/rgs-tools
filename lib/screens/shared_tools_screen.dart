import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/supabase_tool_provider.dart';
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/request_thread_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/common/empty_state.dart';
import '../models/tool.dart';
import '../models/user_role.dart';
import 'tool_detail_screen.dart';

class SharedToolsScreen extends StatefulWidget {
  const SharedToolsScreen({super.key});

  @override
  State<SharedToolsScreen> createState() => _SharedToolsScreenState();
}

class _SharedToolsScreenState extends State<SharedToolsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'All',
    'Available',
    'In Use',
    'Maintenance',
    'High Value',
    'Recently Added',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
        child: Column(
          children: [
              // Section Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Shared Tools',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Search Section
            _buildSearchSection(),
            
            // Filter Chips
            _buildFilterChips(),
            
            // Tools List
            Expanded(
            child: Consumer2<SupabaseToolProvider, SupabaseTechnicianProvider>(
              builder: (context, toolProvider, technicianProvider, child) {
                final tools = _getFilteredTools(toolProvider.tools);
                
                if (toolProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (tools.isEmpty) {
                  // Check if user is admin to show "Go to Tools" button
                  return Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isAdmin = authProvider.userRole == UserRole.admin;
                      
                      return EmptyState(
                        icon: Icons.share,
                        title: _selectedFilter == 'All' ? 'No Shared Tools' : 'No Tools Found',
                        subtitle: _selectedFilter == 'All' 
                            ? (isAdmin 
                                ? 'Go to All Tools to mark tools as "Shared" so they appear here'
                                : 'No shared tools available. Contact your admin to share tools.')
                            : 'Try adjusting your filters or search terms',
                        actionText: isAdmin ? 'Go to Tools' : null,
                        onAction: isAdmin ? () {
                          // Navigate to Admin Home with Tools tab selected
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/admin',
                            (route) => false,
                            arguments: {'initialTab': 1}, // Tools tab
                          );
                        } : null,
                      );
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await toolProvider.loadTools();
                  },
                  color: AppTheme.primaryColor,
                  backgroundColor: Theme.of(context).cardTheme.color,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 0.62, // Extra height for owner labels & buttons
                      ),
                    itemCount: tools.length,
                    itemBuilder: (context, index) {
                      final tool = tools[index];
                      return _buildToolCard(tool, technicianProvider);
                    },
                  ),
                );
              },
            ),
          ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradientFor(context),
          borderRadius: BorderRadius.circular(24), // Fully rounded pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
        child: TextField(
          controller: _searchController,
            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search shared tools...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              labelPadding: EdgeInsets.symmetric(horizontal: 4),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Theme.of(context).cardTheme.color,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Theme.of(context).textTheme.bodyLarge?.color,
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolCard(Tool tool, SupabaseTechnicianProvider technicianProvider) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    final assignedToId = tool.assignedTo;
    final assignedTechnicianName = assignedToId != null && assignedToId.isNotEmpty
        ? technicianProvider.getTechnicianNameById(assignedToId)
        : null;
    final isOwnedByCurrentUser = assignedToId != null && assignedToId == currentUserId;
    return InkWell(
        onTap: () {
        Navigator.push(
            context,
          MaterialPageRoute(
            builder: (context) => ToolDetailScreen(tool: tool),
          ),
        );
      },
      onLongPress: () => _showToolActions(tool, technicianProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
            children: [
          // Full Image Card - Square
          AspectRatio(
            aspectRatio: 1.0, // Perfect square
            child: Container(
                decoration: BoxDecoration(
                gradient: AppTheme.cardGradientFor(context),
                borderRadius: BorderRadius.circular(28), // More rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow( // Second shadow for depth
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
                child: tool.imagePath != null
                  ? (tool.imagePath!.startsWith('http')
                    ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                                tool.imagePath!,
                            width: double.infinity,
                            height: double.infinity,
                                fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.cardGradientFor(context),
                                ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                          ),
                              )
                            : File(tool.imagePath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.file(
                                    File(tool.imagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                    fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              ),
                            )
                          : _buildPlaceholderImage())
                  : _buildPlaceholderImage(),
            ),
          ),
          
          // Details Below Card
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
                  children: [
                // Tool Name and Category in one line
                    Text(
                  '${tool.name} • ${tool.category}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                    ),
                SizedBox(height: 6),
                // Status, value, and actions
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(
                    status: tool.status,
                    showIcon: false,
                  ),
                  if (!isOwnedByCurrentUser && assignedToId != null && assignedToId.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => _openRequestChat(tool, assignedToId),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Request', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (assignedToId != null && assignedToId.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isOwnedByCurrentUser ? Icons.verified_user : Icons.person_pin_circle,
                      size: 16,
                      color: isOwnedByCurrentUser ? Colors.green : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isOwnedByCurrentUser
                            ? 'You have this tool.'
                            : '${assignedTechnicianName ?? 'Another technician'} has this tool.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOwnedByCurrentUser ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ],
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradientFor(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 40,
            color: Colors.grey[400],
          ),
          SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<Tool> _getFilteredTools(List<Tool> tools) {
    debugPrint('🔍 Shared Tools Filter - Total tools: ${tools.length}');
    
    var filteredTools = tools.where((tool) {
      // Only show tools that are marked as 'shared' (available for checkout by any technician)
      // Do NOT show 'assigned' tools (technician's personal tools) or 'inventory' tools
      if (tool.toolType != 'shared') {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!tool.name.toLowerCase().contains(query) &&
            !tool.category.toLowerCase().contains(query) &&
            !(tool.brand?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Category filter
      switch (_selectedFilter) {
        case 'Available':
          return tool.status == 'Available';
        case 'In Use':
          return tool.status == 'In Use';
        case 'Maintenance':
          return tool.status == 'Maintenance';
        case 'High Value':
          return tool.currentValue != null && tool.currentValue! > 500;
        case 'Recently Added':
          // Show tools added in the last 7 days
          if (tool.createdAt == null) return false;
          final createdAt = DateTime.tryParse(tool.createdAt!);
          if (createdAt == null) return false;
          final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
          return daysSinceCreated <= 7;
        default:
          return true;
      }
    }).toList();

    // Sort by name
    filteredTools.sort((a, b) => a.name.compareTo(b.name));
    
    return filteredTools;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Options',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            ..._filterOptions.map((filter) => ListTile(
              title: Text(
                filter,
                style: TextStyle(
                  color: _selectedFilter == filter ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: _selectedFilter == filter
                  ? Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showToolActions(Tool tool, SupabaseTechnicianProvider technicianProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              tool.name,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (tool.status == 'Available') ...[
              ListTile(
                leading: Icon(Icons.person_add, color: AppTheme.primaryColor),
                title: Text('Assign to Technician', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/assign-tool', arguments: tool);
                },
              ),
            ],
            if (tool.status == 'In Use') ...[
              ListTile(
                leading: Icon(Icons.swap_horiz, color: AppTheme.accentColor),
                title: Text('Reassign Tool', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reassign-tool', arguments: tool);
                },
              ),
              ListTile(
                leading: Icon(Icons.keyboard_return, color: Colors.green),
                title: Text('Check In Tool', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/checkin');
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.edit, color: Colors.orange),
              title: Text('Edit Tool', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/edit-tool', arguments: tool);
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blue),
              title: Text('View Details', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tool-detail', arguments: tool);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRequestChat(Tool tool, String ownerId) async {
    final auth = context.read<AuthProvider>();
    final requesterId = auth.user?.id;
    if (requesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to request a tool.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (tool.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This tool is missing an identifier.'), backgroundColor: Colors.red),
      );
      return;
    }

    final threadProvider = context.read<RequestThreadProvider>();
    try {
      final chatCtrl = TextEditingController();
      final FocusNode inputFocus = FocusNode();
      bool hasText = false;
      bool requestedFocus = false;

      final thread = await threadProvider.openOrCreateThread(
        toolId: tool.id!,
        ownerId: ownerId,
        requesterId: requesterId,
      );

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setSheetState) {
                  if (!requestedFocus) {
                    requestedFocus = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (inputFocus.canRequestFocus) {
                        inputFocus.requestFocus();
                      }
                    });
                  }
                  void handleChanged(String value) {
                    final trimmed = value.trim().isNotEmpty;
                    if (trimmed != hasText) {
                      hasText = trimmed;
                      setSheetState(() {});
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(4))),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                child: Text(
                                  tool.name.isNotEmpty ? tool.name[0].toUpperCase() : 'T',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tool.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        _sharedChip(context, 'Request chat', Theme.of(context).colorScheme.onSurface),
                                        _sharedChip(context, tool.status, Theme.of(context).colorScheme.primary),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Consumer<RequestThreadProvider>(
                            builder: (context, provider, child) {
                              final messages = provider.messages(thread.id);
                              return ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  final isMe = msg.senderId == requesterId;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: isMe
                                        ? _sharedMeBubble(context, msg.text)
                                        : _sharedOtherBubble(context, msg.text),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: TextField(
                                      focusNode: inputFocus,
                                      controller: chatCtrl,
                                      onChanged: handleChanged,
                                      textInputAction: hasText ? TextInputAction.send : TextInputAction.newline,
                                      minLines: 1,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'Message',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        prefixIcon: IconButton(
                                          icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                          onPressed: () {},
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            hasText ? Icons.send : Icons.photo_camera,
                                            color: hasText ? Colors.green : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                          onPressed: () async {
                                            if (!hasText) return;
                                            await threadProvider.sendMessage(threadId: thread.id, senderId: requesterId, text: chatCtrl.text);
                                            chatCtrl.clear();
                                            handleChanged('');
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Consumer<RequestThreadProvider>(
                                  builder: (context, provider, child) {
                                    return provider.isSending
                                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                                        : const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
      chatCtrl.dispose();
      inputFocus.dispose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open request chat: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _sharedChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _sharedMeBubble(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _sharedOtherBubble(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}
