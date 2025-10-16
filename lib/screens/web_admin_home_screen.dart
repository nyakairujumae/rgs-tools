import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_tool_provider.dart';
import '../theme/app_theme.dart';
import '../utils/error_handler.dart';
import '../widgets/common/status_chip.dart';
import 'checkin_screen_web.dart';
import 'checkout_screen_web.dart';
import 'tools_screen.dart';
import 'reports_screen.dart';
import 'technicians_screen.dart';
import 'web_login_screen.dart';

class WebAdminHomeScreen extends StatefulWidget {
  const WebAdminHomeScreen({super.key});

  @override
  State<WebAdminHomeScreen> createState() => _WebAdminHomeScreenState();
}

class _WebAdminHomeScreenState extends State<WebAdminHomeScreen> with ErrorHandlingMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      page: const DashboardPage(),
    ),
    NavigationItem(
      icon: Icons.build,
      label: 'Tools',
      page: const ToolsScreen(),
    ),
    NavigationItem(
      icon: Icons.login,
      label: 'Check In',
      page: const CheckinScreenWeb(),
    ),
    NavigationItem(
      icon: Icons.logout,
      label: 'Check Out',
      page: const CheckoutScreenWeb(),
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Technicians',
      page: const TechniciansScreen(),
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Reports',
      page: const ReportsScreen(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ResponsiveBreakpoints.builder(
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
            
            if (isDesktop) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSidebarHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildSidebarNavigation(),
                ),
              ),
              _buildSidebarFooter(),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _navigationItems.map((item) => item.page).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top App Bar
        _buildTopAppBar(),
        // Main Content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _navigationItems.map((item) => item.page).toList(),
          ),
        ),
        // Bottom Navigation
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build,
              size: 30,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'RGS Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavigation() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _navigationItems.length,
      itemBuilder: (context, index) {
        final item = _navigationItems[index];
        final isSelected = _selectedIndex == index;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF374151),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(color: Color(0xFFE5E7EB)),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF6B7280), size: 20),
            title: const Text(
              'Admin User',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            subtitle: const Text(
              'Administrator',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
              onPressed: () {
                // Navigate back to login
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const WebLoginScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return AppBar(
      title: Text(_navigationItems[_selectedIndex].label),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return IconButton(
              icon: const Icon(Icons.logout),
              onPressed: authProvider.isLoading ? null : () async {
                try {
                  await authProvider.signOut();
                  // Navigate to login screen
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WebLoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  _showErrorSnackBar('Logout failed: $e');
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: _navigationItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'RGS tools Overview',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 24),

          // Stats Grid - Responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
              final crossAxisCount = isDesktop ? 4 : 2;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Tools',
                    '24',
                    Icons.build,
                    Colors.blue,
                    context,
                    () {}, // Navigate to Tools tab
                  ),
                  _buildStatCard(
                    'Technicians',
                    '8',
                    Icons.people,
                    Colors.green,
                    context,
                    () {}, // Navigate to Technicians tab
                  ),
                  _buildStatCard(
                    'Total Value',
                    '\$12,450',
                    Icons.attach_money,
                    Colors.orange,
                    context,
                    () {}, // Navigate to Reports tab
                  ),
                  _buildStatCard(
                    'Need Maintenance',
                    '3',
                    Icons.warning,
                    Colors.red,
                    context,
                    () {}, // Navigate to Tools tab (can filter by maintenance)
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24),

          // Status Overview
          Text(
            'Tool Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          
          // Status Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
              final crossAxisCount = isDesktop ? 3 : 1;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 2.5 : 3.0,
                children: [
                  _buildStatusCard('Available', '18', Colors.green, context),
                  _buildStatusCard('In Use', '5', Colors.orange, context),
                  _buildStatusCard('Maintenance', '1', Colors.red, context),
                ],
              );
            },
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String count, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$count tools',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
