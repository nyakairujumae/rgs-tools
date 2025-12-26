import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';
import '../services/last_route_service.dart';
import 'auth/login_screen.dart';
import 'technician_home_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/themed_button.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Map<String, dynamic>? _approvalStatus;
  bool _isLoading = true;
  Timer? _pollingTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LastRouteService.saveLastRoute('/pending-approval');
    });
    _bootstrapApprovalStatus();
    // Start polling for approval status every 5 seconds
    _startPolling();
  }
  
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
  
  void _startPolling() {
    // Check approval status every 5 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkApprovalAndNavigate();
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _bootstrapApprovalStatus() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      await authProvider.initialize();
    }
    if (mounted) {
      await _redirectIfNotTechnicianOrApproved(authProvider);
    }
    await _loadApprovalStatus();
  }

  Future<void> _redirectIfNotTechnicianOrApproved(AuthProvider authProvider) async {
    final user = authProvider.user ?? SupabaseService.client.auth.currentUser;
    if (user == null) return;

    // Prefer provider role if available, otherwise fall back to metadata.
    final roleFromProvider = authProvider.userRole;
    final roleFromMetadata = user.userMetadata?['role'] as String?;
    final isAdmin = roleFromProvider == UserRole.admin || roleFromMetadata == 'admin';
    final isTechnician = roleFromProvider == UserRole.technician || roleFromMetadata == 'technician';

    if (isAdmin && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
      return;
    }

    if (isTechnician && authProvider.user != null) {
      final isApproved = await authProvider.checkApprovalStatus();
      if (isApproved == true && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/technician', (route) => false);
      }
    }
  }

  Future<void> _checkApprovalAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ??
        SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Check approval status
      bool? isApproved;
      if (authProvider.user != null) {
        isApproved = await authProvider.checkApprovalStatus();
      } else {
        final approval = await SupabaseService.client
            .from('pending_user_approvals')
            .select('status')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (approval != null) {
          final status = approval['status'] as String?;
          isApproved = status == 'approved';
        }
      }
      
      if (isApproved == true && mounted) {
        // User is approved! Reload their role and navigate to technician home
        debugPrint('✅ User approved! Navigating to technician home...');
        
        // Reload user role to ensure it's updated
        await authProvider.initialize();
        
        if (mounted && authProvider.isAuthenticated && authProvider.isTechnician) {
          // Cancel polling timer
          _pollingTimer?.cancel();
          
          // Navigate to technician home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TechnicianHomeScreen()),
            (route) => false,
          );
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Your account has been approved! Welcome to RGS HVAC Services.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking approval status: $e');
    }
  }
  
  Future<void> _loadApprovalStatus() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ??
        SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      // Get the most recent approval record
      final approval = await SupabaseService.client
          .from('pending_user_approvals')
          .select('status, rejection_reason, rejection_count, reviewed_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _approvalStatus = approval;
          _isLoading = false;
        });
        
        // Check if approved and navigate if needed
        await _checkApprovalAndNavigate();
      }
    } catch (e) {
      debugPrint('Error loading approval status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = _approvalStatus?['status'] as String?;
    final isRejected = status == 'rejected';
    final isPending = status == 'pending' || status == null;
    final rejectionReason = _approvalStatus?['rejection_reason'] as String?;
    final rejectionCount = _approvalStatus?['rejection_count'] as int? ?? 0;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.scaffoldBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(context.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: context.spacingLarge),
                
                // Main Card Container
                Container(
                  padding: EdgeInsets.all(context.spacingLarge * 1.5),
                  decoration: context.cardDecoration,
                  child: Column(
                    children: [
                      // Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: (isRejected ? Colors.red : Colors.orange)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRejected ? Icons.cancel : Icons.pending_actions,
                          size: 60,
                          color: isRejected ? Colors.red : Colors.orange,
                        ),
                      ),
                      
                      SizedBox(height: context.spacingLarge * 2),
                      
                      // Title
                      Text(
                        isRejected ? 'Account Approval Rejected' : 'Account Pending Approval',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: context.spacingMedium),
                      
                      // Description
                      Text(
                        isRejected 
                          ? 'Your technician account request has been rejected. Please review the reason below and contact your administrator if you have questions.'
                          : 'Your technician account has been created and submitted for admin approval. You will be notified once your account is approved and you can access the system.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: context.spacingLarge * 2),
                      
                      // Status Card
                      Container(
                        padding: EdgeInsets.all(context.spacingLarge),
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                          border: Border.all(
                            color: (isRejected ? Colors.red : Colors.orange)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isRejected ? Icons.info_outline : Icons.info_outline,
                                  color: isRejected ? Colors.red : Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: context.spacingSmall),
                                Text(
                                  'Current Status',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.spacingMedium),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.spacingMedium,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (isRejected ? Colors.red : Colors.orange)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isRejected ? 'Rejected' : 'Pending Admin Approval',
                                style: TextStyle(
                                  color: isRejected ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isRejected && rejectionReason != null) ...[
                              SizedBox(height: context.spacingLarge),
                              Divider(
                                color: theme.dividerColor,
                                height: 1,
                              ),
                              SizedBox(height: context.spacingMedium),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: context.spacingSmall),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rejection Reason:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: context.spacingMicro),
                                        Text(
                                          rejectionReason,
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (isRejected && rejectionCount >= 2) ...[
                              SizedBox(height: context.spacingMedium),
                              Container(
                                padding: EdgeInsets.all(context.spacingMedium),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(context.borderRadiusSmall),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.red, size: 20),
                                    SizedBox(width: context.spacingSmall),
                                    Expanded(
                                      child: Text(
                                        'Warning: This is rejection #$rejectionCount. After 3 rejections, your account will be permanently deleted.',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: context.spacingLarge * 2),
                
                // Refresh Button (for manual check when pending)
                if (!isRejected) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ThemedButton(
                      onPressed: _isLoading ? null : () async {
                        setState(() => _isLoading = true);
                        await _loadApprovalStatus();
                      },
                      isLoading: _isLoading,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isLoading) ...[
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: context.spacingSmall),
                          ],
                          Text(
                            _isLoading ? 'Checking...' : 'Check Approval Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.spacingMedium),
                  Text(
                    'Status is checked automatically every 5 seconds',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.spacingLarge),
                ],
                
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _signOut(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: AppTheme.getCardBorder(context),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: context.spacingLarge),
                
                // Contact Info
                Text(
                  'Questions? Contact your administrator',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: context.spacingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signOut(BuildContext context) async {
    try {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
