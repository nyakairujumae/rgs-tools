import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supabase_tool_provider.dart';
import '../../providers/supabase_technician_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/rgs_logo.dart';
import '../auth/login_screen.dart';
import '../tools_screen.dart';
import 'web_tools_screen.dart';
import '../technicians_screen.dart';
import 'web_technicians_screen.dart';
import '../reports_screen.dart';
import 'web_reports_screen.dart';
import 'web_settings_screen.dart';
import '../add_tool_screen.dart';
import '../bulk_assignment_screen.dart';
import 'web_add_tool_screen.dart';
import 'web_add_technician_screen.dart';
import '../assign_tool_screen.dart';
import 'web_assign_tool_screen.dart';
import '../maintenance_screen.dart';

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> with ErrorHandlingMixin {
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
      page: const WebToolsScreen(), // Web-optimized Tools screen
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Technicians',
      page: const WebTechniciansScreen(), // Web-optimized Technicians screen
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Reports',
      page: const WebReportsScreen(), // Web-optimized Reports screen
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      page: const WebSettingsScreen(), // Web-optimized Settings screen
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
      backgroundColor: const Color(0xFFF8FAFC),
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
          width: 240,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSidebarHeader(),
              Expanded(
                child: _buildSidebarNavigation(),
              ),
              _buildSidebarFooter(),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: Column(
            children: [
              _buildTopHeader(),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top App Bar
        _buildTopHeader(),
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // RGS Logo with proper branding
          const RGSLogo(),
          const SizedBox(height: 16),
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _navigationItems[_selectedIndex].label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6B7280)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Profile
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
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
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF6B7280),
        items: _navigationItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
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
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Evening, Admin!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your HVAC tools and technicians',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
                final crossAxisCount = isDesktop ? 4 : 2;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      'Total Tools',
                      '24',
                      Icons.build,
                      const Color(0xFF3B82F6),
                      context,
                      () {},
                    ),
                    _buildStatCard(
                      'Technicians',
                      '8',
                      Icons.people,
                      const Color(0xFF10B981),
                      context,
                      () {},
                    ),
                    _buildStatCard(
                      'Total Value',
                      '\$12,450',
                      Icons.attach_money,
                      const Color(0xFFF59E0B),
                      context,
                      () {},
                    ),
                    _buildStatCard(
                      'Need Maintenance',
                      '3',
                      Icons.warning,
                      const Color(0xFFEF4444),
                      context,
                      () {},
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            
              // Quick Actions Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
                  final crossAxisCount = isDesktop ? 3 : 2;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      _buildQuickActionCard('Add Tool', Icons.add, const Color(0xFF3B82F6), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WebAddToolScreen()));
                      }),
                      _buildQuickActionCard('Add Technician', Icons.person_add, const Color(0xFF10B981), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WebAddTechnicianScreen()));
                      }),
                      _buildQuickActionCard('Assign Tool', Icons.person_add, const Color(0xFFF59E0B), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WebAssignToolScreen()));
                      }),
                      _buildQuickActionCard('Bulk Assign', Icons.group_add, const Color(0xFF8B5CF6), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkAssignmentScreen()));
                      }),
                      _buildQuickActionCard('Maintenance', Icons.build, const Color(0xFFF97316), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MaintenanceScreen()));
                      }),
                      _buildQuickActionCard('Reports', Icons.analytics, const Color(0xFF8B5CF6), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WebReportsScreen()));
                      }),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),

            // Tool Status Overview
            Text(
              'Tool Status Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
                final crossAxisCount = isDesktop ? 3 : 1;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: isDesktop ? 2.5 : 3.0,
                  children: [
                    _buildStatusCard('Available', '18', const Color(0xFF10B981), context),
                    _buildStatusCard('Assigned', '5', const Color(0xFF3B82F6), context),
                    _buildStatusCard('Maintenance', '1', const Color(0xFFEF4444), context),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+12%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String count, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
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

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
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
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
