import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';
import 'auth/login_screen.dart';
import 'technician_home_screen.dart';

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
    _loadApprovalStatus();
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
  
  Future<void> _checkApprovalAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;
    
    try {
      // Check approval status
      final isApproved = await authProvider.checkApprovalStatus();
      
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
    if (authProvider.user == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      // Get the most recent approval record
      final approval = await SupabaseService.client
          .from('pending_user_approvals')
          .select('status, rejection_reason, rejection_count, reviewed_at')
          .eq('user_id', authProvider.user!.id)
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
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final status = _approvalStatus?['status'] as String?;
    final isRejected = status == 'rejected';
    final isPending = status == 'pending' || status == null;
    final rejectionReason = _approvalStatus?['rejection_reason'] as String?;
    final rejectionCount = _approvalStatus?['rejection_count'] as int? ?? 0;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              
              SizedBox(height: 32),
              
              // Title
              Text(
                isRejected ? 'Account Approval Rejected' : 'Account Pending Approval',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16),
              
              // Description
              Text(
                isRejected 
                  ? 'Your technician account request has been rejected. Please review the reason below and contact your administrator if you have questions.'
                  : 'Your technician account has been created and submitted for admin approval. You will be notified once your account is approved and you can access the system.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32),
              
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isRejected ? Colors.red : Colors.orange)
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDarkMode ? 0.08 : 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                        SizedBox(width: 8),
                        Text(
                          'Current Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                        ),
                      ),
                    ),
                    if (isRejected && rejectionReason != null) ...[
                      SizedBox(height: 16),
                      Divider(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rejection Reason:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
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
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            SizedBox(width: 8),
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
              
              SizedBox(height: 32),
              
              // Refresh Button (for manual check when pending)
              if (!isRejected) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      await _loadApprovalStatus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isLoading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.refresh),
                    label: Text(
                      _isLoading ? 'Checking...' : 'Check Approval Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Status is checked automatically every 5 seconds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
              ],
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _signOut(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Contact Info
              Text(
                'Questions? Contact your administrator',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
