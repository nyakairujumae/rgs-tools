import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import "../providers/supabase_tool_provider.dart";
import '../providers/supabase_technician_provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'checkin_screen.dart';
import 'web/checkin_screen_web.dart';
import 'shared_tools_screen.dart';
import 'add_tool_issue_screen.dart';
import 'request_new_tool_screen.dart';
import '../models/tool.dart';
import '../widgets/common/rgs_logo.dart';
import 'package:provider/provider.dart';
import '../providers/request_thread_provider.dart';
import '../services/firebase_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../theme/app_theme.dart';
import '../providers/admin_notification_provider.dart';
import '../models/admin_notification.dart';
import '../services/supabase_service.dart';

// Removed placeholder request/report screens; using detailed screens directly

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _selectedIndex = 0;
  bool _isDisposed = false;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TechnicianDashboardScreen(
        key: const ValueKey('tech_dashboard'),
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const RequestNewToolScreen(),
      const AddToolIssueScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseToolProvider>().loadTools();
      context.read<SupabaseTechnicianProvider>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: (_selectedIndex == 1 || _selectedIndex == 2) ? null : AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(context),
          tooltip: 'Notifications',
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const RGSLogo(),
        ),
        centerTitle: true,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoading || authProvider.isLoggingOut) {
                return IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: null,
                );
              }
              
              return PopupMenuButton<String>(
                icon: Icon(Icons.account_circle),
                onSelected: (value) async {
                  if (value == 'logout' && !_isDisposed && mounted) {
                    try {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      await authProvider.signOut();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      debugPrint('Logout error: $e');
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.userFullName ?? 'Technician',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Technician',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index.clamp(0, 2)),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Request Tool',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem),
              label: 'Report Issue',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
              builder: (context) => kIsWeb ? const CheckinScreenWeb() : const CheckinScreen(),
                  ),
                );
              },
              backgroundColor: Colors.green,
        foregroundColor: Colors.white,
              icon: const Icon(Icons.keyboard_return),
              label: const Text('Check In'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final fcmToken = FirebaseMessagingService.fcmToken;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  // Content
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: _loadTechnicianNotifications(authProvider.user?.email),
                          builder: (context, snapshot) {
                            final notifications = snapshot.data ?? [];
                            
                            return ListView(
                              controller: scrollController,
                              padding: EdgeInsets.all(16),
                              children: [
                                // Real Notifications List
                                if (snapshot.connectionState == ConnectionState.waiting)
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (notifications.isNotEmpty) ...[
                                  Text(
                                    'Your Notifications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  ...notifications.map((notification) => _buildNotificationCard(
                                    context,
                                    notification,
                                  )),
                                  SizedBox(height: 24),
                                  Divider(),
                                  SizedBox(height: 16),
                                ] else if (snapshot.connectionState == ConnectionState.done && notifications.isEmpty) ...[
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                                          SizedBox(height: 16),
                                          Text(
                                            'No notifications yet',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'You\'ll see notifications here when you receive tool requests or messages',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadTechnicianNotifications(String? technicianEmail) async {
    if (technicianEmail == null) return [];
    
    try {
      // Load notifications for this technician
      final response = await SupabaseService.client
          .from('admin_notifications')
          .select()
          .eq('technician_email', technicianEmail)
          .order('timestamp', ascending: false)
          .limit(20);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading technician notifications: $e');
      return [];
    }
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final timestamp = notification['timestamp'] != null
        ? DateTime.parse(notification['timestamp'].toString())
        : DateTime.now();
    final isRead = notification['is_read'] as bool? ?? false;
    final type = notification['type'] as String? ?? 'general';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: !isRead
            ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Mark as read
            if (!isRead) {
              try {
                await SupabaseService.client
                    .from('admin_notifications')
                    .update({'is_read': true})
                    .eq('id', notification['id']);
              } catch (e) {
                debugPrint('Error marking notification as read: $e');
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'access_request':
        return Icons.login;
      case 'tool_request':
        return Icons.build;
      case 'maintenance_request':
        return Icons.build_circle;
      case 'issue_report':
        return Icons.report_problem;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'access_request':
        return Colors.blue;
      case 'tool_request':
        return Colors.green;
      case 'maintenance_request':
        return Colors.orange;
      case 'issue_report':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Technician Dashboard Screen - New Design
class TechnicianDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const TechnicianDashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All Tools', 'Shared Tools', 'My Tools', 'Available', 'In Use'];
  late final PageController _sharedToolsController;
  Timer? _autoSlideTimer;

  void _navigateToTab(int index, BuildContext context) {
    widget.onNavigateToTab(index);
  }

  @override
  void initState() {
    super.initState();
    _sharedToolsController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _sharedToolsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SupabaseToolProvider, AuthProvider, SupabaseTechnicianProvider>(
      builder: (context, toolProvider, authProvider, technicianProvider, child) {
        // Filter tools based on selected category
        List<Tool> filteredTools = toolProvider.tools;
        
        final currentUserId = authProvider.userId;

        if (_selectedCategoryIndex == 1) {
          filteredTools = toolProvider.tools.where((tool) => tool.toolType == 'shared').toList();
        } else if (_selectedCategoryIndex == 2) {
          if (currentUserId == null) {
            filteredTools = [];
          } else {
            filteredTools = toolProvider.tools.where((tool) => 
              tool.assignedTo == currentUserId && (tool.status == 'Assigned' || tool.status == 'In Use')
            ).toList();
          }
        } else if (_selectedCategoryIndex == 3) {
          filteredTools = toolProvider.tools.where((tool) => tool.status == 'Available').toList();
        } else if (_selectedCategoryIndex == 4) {
          filteredTools = toolProvider.tools.where((tool) => tool.status == 'In Use').toList();
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredTools = filteredTools.where((tool) =>
            tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (tool.brand?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            tool.category.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        // Featured tools (shared and available)
        final featuredTools = toolProvider.tools.where((tool) => 
          tool.toolType == 'shared' && tool.status == 'Available'
        ).take(10).toList();

        // Latest tools (my tools or all tools if none assigned)
        final myTools = currentUserId == null
            ? <Tool>[]
            : toolProvider.tools.where((tool) => 
                tool.assignedTo == currentUserId && (tool.status == 'Assigned' || tool.status == 'In Use')
              ).toList();
        final latestTools = myTools.isNotEmpty ? myTools : toolProvider.tools.take(10).toList();

        if (toolProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (toolProvider.tools.isEmpty) {
          return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No tools available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Contact your administrator to add tools to the system.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                SizedBox(height: 16),
                ElevatedButton(onPressed: () => toolProvider.loadTools(), child: Text('Retry')),
              ],
            ),
          );
        }

        // Initialize auto-slide when data is available
        _setupAutoSlide(featuredTools);

        return Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Welcome banner (replacing search and quick filters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                    padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                            ),
                  child: Row(
                    children: [
                    Container(
                        width: 56,
                        height: 56,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withValues(alpha: 0.2),
                              Colors.blue.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                      ),
                        child: Icon(Icons.inventory_2, color: Colors.blue, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                            Text(
                              _greeting(authProvider.userFullName),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Manage your tools and access shared resources',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Shared Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Text('Shared Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SharedToolsScreen()),
                        );
                      },
                      child: Text('See All >', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
              ),
              SizedBox(height: 16),

              // Shared Tools Carousel (auto sliding)
              SizedBox(
                height: 160,
                child: featuredTools.isEmpty
                    ? Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No shared tools available', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)))))
                    : PageView.builder(
                        controller: _sharedToolsController,
                        itemCount: featuredTools.length,
                        padEnds: false,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildFeaturedCard(featuredTools[index], context, authProvider.user?.id, technicianProvider.technicians),
                          );
                        },
                      ),
              ),

              SizedBox(height: 32),

              // My Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text('My Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    TextButton(
                      onPressed: () => setState(() { _selectedCategoryIndex = 2; }),
                      child: Text('See All >', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Latest Tools Vertical List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: latestTools.isEmpty
                    ? Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.build, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No tools assigned', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: latestTools.map((tool) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildLatestCard(tool, context, technicianProvider.technicians),
                        )).toList(),
                      ),
              ),

              SizedBox(height: 100),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildFeaturedCard(Tool tool, BuildContext context, String? currentUserId, List<dynamic> technicians) {
    // Same layout as latest card, with a Request button for shared tools
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 148,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 116,
                height: double.infinity,
                color: Theme.of(context).colorScheme.surfaceVariant,
              child: tool.imagePath != null
                    ? (tool.imagePath!.startsWith('http')
                          ? Image.network(
                              tool.imagePath!,
                              fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(true),
                            )
                          : File(tool.imagePath!).existsSync()
                              ? Image.file(
                                  File(tool.imagePath!),
                                  fit: BoxFit.cover,
                              )
                            : _buildPlaceholderImage(true))
                    : _buildPlaceholderImage(true),
              ),
            ),
            SizedBox(width: 12),
          Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
              children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.name,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Show Request button for shared tools that have a holder (badged to someone)
                            // Show for all technicians except the one who has it
                            if (tool.toolType == 'shared' && 
                                tool.assignedTo != null && 
                                tool.assignedTo!.isNotEmpty &&
                                (currentUserId == null || currentUserId != tool.assignedTo))
                              TextButton(
                                onPressed: () => _showRequestChat(context, tool),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Request'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildOutlinedChip(context, _getStatusLabel(tool.status), Theme.of(context).colorScheme.primary),
                            _buildOutlinedChip(context, _getConditionLabel(tool.condition), _getConditionColor(tool.condition)),
                          ],
                        ),
                      ],
                    ),
                        SizedBox(height: 8),
                        if (tool.location != null && tool.location!.isNotEmpty)
                      Row(children: [Icon(Icons.location_on, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)), SizedBox(width: 8), Expanded(child: Text(tool.location!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                    SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.category, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
                      SizedBox(width: 8),
                      Expanded(child: Text(tool.category.toUpperCase(), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 6),
                      Text(tool.toolType.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green)),
                    ]),
                    const SizedBox(height: 4),
                    _holderLine(context, tool, technicians),
                  ],
                ),
              ),
            ),
                      ],
                    ),
      ),
    );
  }

  void _showRequestChat(BuildContext context, Tool tool) async {
    final auth = context.read<AuthProvider>();
    final requesterId = auth.user?.id;
    if (requesterId == null) return;
    // Resolve owner: try tool.assignedTo fallback to requester to avoid errors
    final ownerId = tool.assignedTo ?? 'unknown-owner';
    final threadProvider = context.read<RequestThreadProvider>();
    final thread = await threadProvider.openOrCreateThread(toolId: tool.id ?? 'unknown-tool', ownerId: ownerId, requesterId: requesterId);
    showModalBottomSheet(
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
            return StatefulBuilder(builder: (context, setSheetState) {
              final TextEditingController chatCtrl = TextEditingController();
              final FocusNode inputFocus = FocusNode();
              bool hasText = false;
              void onChanged(String v) {
                final ht = v.trim().isNotEmpty;
                if (ht != hasText) {
                  hasText = ht;
                  setSheetState(() {});
                }
              }
              return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -6)),
                ],
              ),
              child: Column(
                      children: [
                  // Grab handle
                  const SizedBox(height: 8),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(4))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          child: Text(tool.name.isNotEmpty ? tool.name[0].toUpperCase() : 'T', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tool.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Row(children: [
                                _buildOutlinedChip(context, 'Request chat', Theme.of(context).colorScheme.onSurface),
                                const SizedBox(width: 6),
                                _buildOutlinedChip(context, _getStatusLabel(tool.status), Theme.of(context).colorScheme.primary),
                              ]),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Consumer<RequestThreadProvider>(
                      builder: (context, prov, child) {
                        final msgs = prov.messages(thread.id);
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: msgs.length,
                          itemBuilder: (context, index) {
                            final m = msgs[index];
                            final isMe = m.senderId == requesterId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: isMe ? _meBubble(context, m.text) : _otherBubble(context, m.text),
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
                                onChanged: onChanged,
                                textInputAction: hasText ? TextInputAction.send : TextInputAction.newline,
                                minLines: 1,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'Message',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  // left attach icon inside the pill
                                  prefixIcon: IconButton(
                                    icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
                                    onPressed: () {},
                                  ),
                                  // right dynamic action: camera or send
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      hasText ? Icons.send : Icons.photo_camera,
                                      color: hasText ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                    onPressed: () async {
                                      if (hasText) {
                                        await threadProvider.sendMessage(threadId: thread.id, senderId: requesterId, text: chatCtrl.text);
                                        chatCtrl.clear();
                                        onChanged('');
                                      } else {
                                        // open camera placeholder
                                      }
                                    },
                                  ),
                                ),
            ),
          ),
          ),
        ],
      ),
    ),
                  ),
                ],
              ),
            );
            });
          },
        );
      },
    );
  }

  Widget _systemBubble(BuildContext context, String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 12)),
      ),
    );
  }

  Widget _otherBubble(BuildContext context, String text, {String? time}) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(time, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ]
          ],
        ),
      ),
    );
  }

  Widget _meBubble(BuildContext context, String text, {String? time}) {
    return Align(
      alignment: Alignment.centerRight,
              child: Container(
        padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
                  ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 0),
            Text(text, style: const TextStyle(color: Colors.white)),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ]
          ],
                ),
      ),
    );
  }

  Widget _buildLatestCard(Tool tool, BuildContext context, List<dynamic> technicians) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/tool-detail', arguments: tool),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 148,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Left thumbnail (wider like Featured)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 116,
                height: double.infinity,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: tool.imagePath != null
                      ? (tool.imagePath!.startsWith('http')
                            ? Image.network(
                                tool.imagePath!,
                                fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(false),
                              )
                            : File(tool.imagePath!).existsSync()
                                ? Image.file(
                                    File(tool.imagePath!),
                                    fit: BoxFit.cover,
                                )
                              : _buildPlaceholderImage(false))
                      : _buildPlaceholderImage(false),
                ),
              ),
            SizedBox(width: 12),
              Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(tool.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      _buildOutlinedChip(context, _getStatusLabel(tool.status), Theme.of(context).colorScheme.primary),
                      _buildOutlinedChip(context, _getConditionLabel(tool.condition), _getConditionColor(tool.condition)),
                    ]),
                    SizedBox(height: 6),
                        if (tool.location != null && tool.location!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(children: [Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)), SizedBox(width: 6), Expanded(child: Text(tool.location!, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                      ),
                    Row(children: [
                      Icon(Icons.category, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
                      SizedBox(width: 6),
                      Expanded(child: Text(tool.category.toUpperCase(), style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 4),
                      Flexible(child: Text(tool.toolType.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.green), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    SizedBox(height: 2),
                    _holderLine(context, tool, technicians),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildPlaceholderImage(bool isFeatured) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(12), right: isFeatured ? Radius.zero : Radius.circular(12)),
      ),
      child: Icon(Icons.build, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6), size: 32),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildOutlinedChip(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _holderLine(BuildContext context, Tool tool, List<dynamic> technicians) {
    if (tool.assignedTo == null) {
      return Text('No current holder', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)));
    }
    String name = 'Technician';
    for (final t in technicians) {
      if (t.id == tool.assignedTo) {
        final parts = (t.name).trim().split(RegExp(r"\s+"));
        name = parts.isNotEmpty ? parts.first : t.name;
        break;
      }
    }
    return Text('$name has this tool', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)));
  }

  IconData _getCategoryIcon(int index) {
    switch (index) {
      case 0: return Icons.apps;
      case 1: return Icons.share;
      case 2: return Icons.person;
      case 3: return Icons.check_circle;
      case 4: return Icons.build;
      default: return Icons.apps;
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final fcmToken = FirebaseMessagingService.fcmToken;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(16),
                      children: [
                        // FCM Status Card
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      fcmToken != null ? Icons.check_circle : Icons.error_outline,
                                      color: fcmToken != null ? Colors.green : Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'FCM Status',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  fcmToken != null
                                      ? 'Push notifications are enabled'
                                      : 'Push notifications not configured',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                if (fcmToken != null) ...[
                                  SizedBox(height: 12),
                                  Text(
                                    'FCM Token:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SelectableText(
                                      fcmToken,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await FirebaseMessagingService.refreshToken();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Token refreshed')),
                                      );
                                      Navigator.pop(context);
                                      _showNotifications(context);
                                    },
                                    icon: Icon(Icons.refresh),
                                    label: Text('Refresh Token'),
                                  ),
                                ] else ...[
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await FirebaseMessagingService.initialize();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('FCM initialized. Please check again.')),
                                      );
                                      Navigator.pop(context);
                                      _showNotifications(context);
                                    },
                                    icon: Icon(Icons.notifications_active),
                                    label: Text('Initialize FCM'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Test Notification Button
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Test Notification',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Send a test notification to verify FCM is working',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: fcmToken != null
                                      ? () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Test notification sent! Check your device notifications.'),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                          // Note: This requires backend to send the notification
                                          // For now, just show a message
                                        }
                                      : null,
                                  icon: Icon(Icons.send),
                                  label: Text('Send Test Notification'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Info Card
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'About Notifications',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Push notifications will alert you when:\n'
                                  '• Someone requests a tool from you\n'
                                  '• You receive a message in a tool request chat\n'
                                  '• Admin assigns you a new tool\n'
                                  '• Tool maintenance reminders',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available': return 'Available';
      case 'assigned': return 'Assigned';
      case 'in use': return 'In Use';
      case 'maintenance': return 'Maintenance';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available': return Colors.green;
      case 'assigned': return Colors.blue;
      case 'in use': return Colors.orange;
      case 'maintenance': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getConditionLabel(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('fault') || c == 'bad' || c == 'poor') return 'Faulty';
    return 'Good';
  }

  Color _getConditionColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('fault') || c == 'bad' || c == 'poor') return Colors.red;
    return Colors.green;
  }

  String _greeting(String? fullName) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final name = (fullName == null || fullName.trim().isEmpty)
        ? 'Technician'
        : fullName.split(RegExp(r"\s+")).first;
    return '$salutation, $name!';
  }

  void _setupAutoSlide(List<Tool> featuredTools) {
    if (_autoSlideTimer != null || featuredTools.length <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || featuredTools.isEmpty) return;
      final nextPage = (_sharedToolsController.page ?? 0).round() + 1;
      final target = nextPage % featuredTools.length;
      _sharedToolsController.animateToPage(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }
}

