import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';
import 'auth/login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Map<String, dynamic>? _approvalStatus;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadApprovalStatus();
  }
  
  Future<void> _loadApprovalStatus() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final approval = await SupabaseService.client
          .from('pending_user_approvals')
          .select('status, rejection_reason, rejection_count, reviewed_at')
          .eq('user_id', authProvider.user!.id)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _approvalStatus = approval;
          _isLoading = false;
        });
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
                  color: (isRejected ? Colors.red : Colors.orange).withOpacity(0.1),
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
                  color: theme.textTheme.bodyLarge?.color,
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
                  color: theme.textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32),
              
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isRejected ? Colors.red : Colors.orange).withOpacity(0.3),
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
                        SizedBox(width: 8),
                        Text(
                          'Current Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
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
                        color: (isRejected ? Colors.red : Colors.orange).withOpacity(0.1),
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
                      Divider(),
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
                                    color: theme.textTheme.bodyLarge?.color,
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
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
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
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _signOut(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                  color: theme.textTheme.bodyMedium?.color,
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
