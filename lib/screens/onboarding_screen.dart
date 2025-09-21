import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to RGS Tools',
      subtitle: 'Professional Tool Management for HVAC Teams',
      description: 'Manage your tools, track assignments, and optimize costs with our comprehensive solution designed for 50+ technicians across multiple locations.',
      icon: Icons.build,
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      title: 'Permanent Assignments',
      subtitle: 'Tools Assigned Long-Term',
      description: 'Assign tools to technicians permanently. Tools are only checked in during leave periods, reducing paperwork and improving accountability.',
      icon: Icons.person_add,
      color: AppTheme.secondaryColor,
    ),
    OnboardingPage(
      title: 'Multi-Location Support',
      subtitle: 'Manage Tools Across Sites',
      description: 'Track tools across multiple locations in Dubai. Know exactly where each tool is and who is responsible for it.',
      icon: Icons.location_on,
      color: AppTheme.accentColor,
    ),
    OnboardingPage(
      title: 'Cost Analytics',
      subtitle: 'Track ROI and Reduce Losses',
      description: 'Monitor tool values, track depreciation, and identify cost-saving opportunities. Replace paper-based tracking with digital insights.',
      icon: Icons.analytics,
      color: AppTheme.successColor,
    ),
    OnboardingPage(
      title: 'Maintenance Scheduling',
      subtitle: 'Keep Tools in Perfect Condition',
      description: 'Schedule maintenance, track repairs, and ensure tools are always ready for use. Prevent costly downtime and extend tool life.',
      icon: Icons.schedule,
      color: AppTheme.warningColor,
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
      body: SafeArea(
        child: Column(
          children: [
            // Header with Logo
            _buildHeader(),
            
            // Progress Indicator
            _buildProgressIndicator(),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            
            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // RGS Logo
          Container(
            width: 120,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'RGS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'HVAC SERVICES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Welcome to RGS Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _pages.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          SizedBox(width: 16),
          Text(
            '${_currentPage + 1}/${_pages.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          
          SizedBox(height: 48),
          
          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // Subtitle
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 24),
          
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Skip Button
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          
          const Spacer(),
          
          // Next/Get Started Button
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: _currentPage < _pages.length - 1 ? _nextPage : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
