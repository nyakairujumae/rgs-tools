import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/themed_button.dart';
import '../widgets/common/themed_text_field.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../services/organization_service.dart';
import '../utils/auth_error_handler.dart';
import '../utils/logger.dart';
import 'admin_home_screen.dart';
import 'auth/login_screen.dart';

// ── Industry presets ──────────────────────────────────────────────────────

class _Preset {
  final String key;
  final String label;
  final IconData icon;
  final String workerLabel;
  final String workerLabelPlural;
  const _Preset({
    required this.key,
    required this.label,
    required this.icon,
    required this.workerLabel,
    required this.workerLabelPlural,
  });
}

const List<_Preset> _presets = [
  _Preset(key: 'hvac',         label: 'HVAC',                  icon: Icons.ac_unit_rounded,            workerLabel: 'Technician',   workerLabelPlural: 'Technicians'),
  _Preset(key: 'electrical',   label: 'Electrical',             icon: Icons.electrical_services_rounded, workerLabel: 'Electrician',  workerLabelPlural: 'Electricians'),
  _Preset(key: 'fm',           label: 'Facilities Management',  icon: Icons.apartment_rounded,           workerLabel: 'Operative',    workerLabelPlural: 'Operatives'),
  _Preset(key: 'construction', label: 'Construction',           icon: Icons.construction_rounded,        workerLabel: 'Site Worker',  workerLabelPlural: 'Site Workers'),
  _Preset(key: 'plumbing',     label: 'Plumbing',               icon: Icons.plumbing_rounded,            workerLabel: 'Plumber',      workerLabelPlural: 'Plumbers'),
  _Preset(key: 'general',      label: 'Other / General',        icon: Icons.business_center_rounded,     workerLabel: 'Worker',       workerLabelPlural: 'Workers'),
];

// ── Step enum ─────────────────────────────────────────────────────────────

enum _Step { welcome, industry, teamLabel, company, account, invite }

// ── Invite row model ──────────────────────────────────────────────────────

class _InviteRow {
  final TextEditingController name       = TextEditingController();
  final TextEditingController email      = TextEditingController();
  final TextEditingController phone      = TextEditingController();
  final TextEditingController department = TextEditingController();

  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    department.dispose();
  }
}

// ── Wizard ────────────────────────────────────────────────────────────────

class AdminOnboardingWizardScreen extends StatefulWidget {
  const AdminOnboardingWizardScreen({super.key});

  @override
  State<AdminOnboardingWizardScreen> createState() =>
      _AdminOnboardingWizardScreenState();
}

class _AdminOnboardingWizardScreenState
    extends State<AdminOnboardingWizardScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 6; // _Step.values.length

  final _pageController = PageController();
  _Step _currentStep = _Step.welcome;
  bool _isLoading = false;
  String? _error;

  // Step data
  _Preset _selectedPreset = _presets.first;
  late final TextEditingController _workerLabelCtrl;
  late final TextEditingController _workerLabelPluralCtrl;
  final _companyNameCtrl = TextEditingController();
  final _slugCtrl        = TextEditingController();
  final _fullNameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmCtrl     = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  final _accountFormKey = GlobalKey<FormState>();

  // Logo
  dynamic _logoFile;
  Uint8List? _logoBytes;

  // Invite step — list of rows per tab
  final List<_InviteRow> _adminInvites    = [_InviteRow()];
  final List<_InviteRow> _techInvites     = [_InviteRow()];
  int _inviteTab = 0; // 0 = admins, 1 = technicians
  bool _inviteSending = false;
  // Per-row result: null = not sent, true = success, false = error
  final Map<int, bool?> _adminResults  = {};
  final Map<int, bool?> _techResults   = {};
  String? _inviteError;

  // Welcome animation
  late final AnimationController _welcomeAnimCtrl;
  late final Animation<double> _welcomeFade;
  late final Animation<Offset> _welcomeSlide;

  @override
  void initState() {
    super.initState();
    _workerLabelCtrl       = TextEditingController(text: _presets.first.workerLabel);
    _workerLabelPluralCtrl = TextEditingController(text: _presets.first.workerLabelPlural);
    _companyNameCtrl.addListener(_autoSlug);

    _welcomeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _welcomeFade = CurvedAnimation(parent: _welcomeAnimCtrl, curve: Curves.easeOut);
    _welcomeSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _welcomeAnimCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _workerLabelCtrl.dispose();
    _workerLabelPluralCtrl.dispose();
    _companyNameCtrl.dispose();
    _slugCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _welcomeAnimCtrl.dispose();
    for (final r in _adminInvites) { r.dispose(); }
    for (final r in _techInvites)  { r.dispose(); }
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _autoSlug() {
    final s = _companyNameCtrl.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (_slugCtrl.text != s) _slugCtrl.text = s;
  }

  void _pickPreset(_Preset p) => setState(() {
        _selectedPreset = p;
        _workerLabelCtrl.text       = p.workerLabel;
        _workerLabelPluralCtrl.text = p.workerLabelPlural;
      });

  void _goTo(_Step s) {
    _pageController.animateToPage(
      s.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() { _currentStep = s; _error = null; });
  }

  void _next() => _goTo(_Step.values[_currentStep.index + 1]);
  void _back() {
    if (_currentStep.index == 0) { Navigator.of(context).pop(); return; }
    _goTo(_Step.values[_currentStep.index - 1]);
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512,
      );
      if (picked == null || !mounted) return;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() { _logoFile = picked; _logoBytes = bytes; });
      } else {
        setState(() { _logoFile = File(picked.path); _logoBytes = null; });
      }
    } catch (_) {}
  }

  // ── Submissions ───────────────────────────────────────────────────────────

  void _submitIndustry() => _next();

  void _submitTeamLabel() {
    if (_workerLabelCtrl.text.trim().isEmpty ||
        _workerLabelPluralCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in both label fields');
      return;
    }
    _next();
  }

  void _submitCompany() {
    if (_companyNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your company name');
      return;
    }
    _autoSlug();
    _next();
  }

  Future<void> _submitAccount() async {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final response = await auth.registerAdmin(
        _fullNameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      if (response.user == null) throw Exception('Registration failed. Please try again.');

      if (response.session != null) {
        // Auto-confirmed — create org right now
        await _createOrg();
      } else {
        // Email confirmation required
        await _showConfirmDialog();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false,
          );
        }
      }
    } catch (e) {
      Logger.debug('Onboarding register error: $e');
      if (mounted) {
        String msg = AuthErrorHandler.getErrorMessage(e);
        if (e.toString().contains('already registered') ||
            e.toString().contains('already exists')) {
          msg = 'This email is already registered. Try signing in instead.';
        }
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrg() async {
    try {
      final orgId = await OrganizationService.createOrganizationAndAssignUser(
        name:               _companyNameCtrl.text.trim(),
        slug:               _slugCtrl.text.trim(),
        industry:           _selectedPreset.key,
        workerLabel:        _workerLabelCtrl.text.trim(),
        workerLabelPlural:  _workerLabelPluralCtrl.text.trim(),
      );

      if (_logoFile != null && orgId != null) {
        try {
          final url = await OrganizationService.uploadOrganizationLogo(_logoFile, orgId);
          if (url != null) {
            await OrganizationService.updateOrganizationSetup(orgId: orgId, logoUrl: url);
          }
        } catch (e) { Logger.debug('Logo upload (non-fatal): $e'); }
      }

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      auth.clearNeedsCompanySetup();
      await auth.refreshAuthState();
      if (orgId != null) context.read<OrganizationProvider>().loadOrganization(orgId);

      // Go to the optional invite step instead of immediately navigating away
      _goTo(_Step.invite);
    } catch (e) {
      Logger.debug('Org creation error: $e');
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
      }
    }
  }

  Future<void> _showConfirmDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Icon(Icons.mark_email_read_rounded, color: AppTheme.secondaryColor, size: 26),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Check your email',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("We've sent a confirmation link to:", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(_emailCtrl.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Text('Once confirmed, sign in and your workspace will be ready.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 640;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 480 : double.infinity),
            child: Column(
              children: [
                _buildTopBar(theme),
                if (_currentStep != _Step.welcome) _buildProgress(theme),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcome(theme),
                      _buildIndustry(theme),
                      _buildTeamLabel(theme),
                      _buildCompany(theme),
                      _buildAccount(theme),
                      _buildInvite(theme),
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

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(ThemeData theme) {
    final stepNum = _currentStep.index;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (_currentStep != _Step.welcome)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _isLoading ? null : _back,
              color: theme.colorScheme.onSurface,
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          if (_currentStep != _Step.welcome)
            Text(
              '$stepNum of ${_totalSteps - 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgress(ThemeData theme) {
    final filled = _currentStep.index;
    final total  = _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        children: List.generate(total, (i) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: i < filled
                  ? AppTheme.primaryColor
                  : context.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      ),
    );
  }

  // ── Step 0: Welcome ───────────────────────────────────────────────────────

  Widget _buildWelcome(ThemeData theme) {
    return FadeTransition(
      opacity: _welcomeFade,
      child: SlideTransition(
        position: _welcomeSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              const Center(child: AppLogo()),
              const SizedBox(height: 40),

              // Headline
              Text(
                'Set up your workspace',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Answer a few questions and we'll tailor\n${AppConfig.appName} to your business.",
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Feature list
              _featureRow(theme, Icons.construction_rounded,    'Tool tracking',    'Assign, audit and manage your equipment.'),
              const SizedBox(height: 20),
              _featureRow(theme, Icons.groups_rounded,          'Team management',  'Onboard field workers, control access.'),
              const SizedBox(height: 20),
              _featureRow(theme, Icons.bar_chart_rounded,       'Reports',          'Export and analyse your operations data.'),
              const SizedBox(height: 52),

              ThemedButton(
                onPressed: _next,
                child: const Text(
                  'Get started',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: TextStyle(fontSize: 13, color: context.secondaryTextColor)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(ThemeData theme, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.cardBorder),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 1: Industry ──────────────────────────────────────────────────────

  Widget _buildIndustry(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(theme, 'What kind of business\ndo you run?',
              "We'll pre-configure departments and tool categories for you."),
          const SizedBox(height: 28),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: _presets.map((p) {
              final sel = _selectedPreset.key == p.key;
              return GestureDetector(
                onTap: () => _pickPreset(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.primaryColor.withOpacity(0.06)
                        : context.cardBackground,
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                    border: Border.all(
                      color: sel ? AppTheme.primaryColor : context.cardBorder,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        p.icon,
                        size: 22,
                        color: sel
                            ? AppTheme.primaryColor
                            : theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                      Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ThemedButton(
            onPressed: _submitIndustry,
            child: const Text('Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Team label ────────────────────────────────────────────────────

  Widget _buildTeamLabel(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(theme, 'What do you call\nyour field team?',
              'This label is used throughout the app wherever team members appear.'),
          const SizedBox(height: 28),

          // Quick-select chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.where((p) => p.key != 'general').map((p) {
              final active = _workerLabelCtrl.text.trim() == p.workerLabel;
              return GestureDetector(
                onTap: () => setState(() {
                  _workerLabelCtrl.text       = p.workerLabel;
                  _workerLabelPluralCtrl.text = p.workerLabelPlural;
                  _error = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primaryColor : context.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppTheme.primaryColor : context.cardBorder,
                    ),
                  ),
                  child: Text(
                    p.workerLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          ThemedTextField(
            controller: _workerLabelCtrl,
            label: 'Singular (e.g. Technician)',
            hint: 'Technician',
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 14),
          ThemedTextField(
            controller: _workerLabelPluralCtrl,
            label: 'Plural (e.g. Technicians)',
            hint: 'Technicians',
            onChanged: (_) => setState(() => _error = null),
          ),

          if (_error != null) _errorBanner(_error!),
          const SizedBox(height: 32),

          ThemedButton(
            onPressed: _submitTeamLabel,
            child: const Text('Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Company name ──────────────────────────────────────────────────

  Widget _buildCompany(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(theme, "What's your\ncompany called?",
              'This will appear in your workspace and on reports.'),
          const SizedBox(height: 28),

          // Logo picker
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  // Preview
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _logoPreview(theme),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add company logo',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 2),
                        Text('Optional · PNG or JPG',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.45))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ThemedTextField(
            controller: _companyNameCtrl,
            label: 'Company name',
            hint: 'e.g. Acme Field Services',
            prefixIcon: Icons.business_outlined,
            onChanged: (_) => setState(() => _error = null),
          ),

          if (_error != null) _errorBanner(_error!),
          const SizedBox(height: 32),

          ThemedButton(
            onPressed: _submitCompany,
            child: const Text('Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _logoPreview(ThemeData theme) {
    if (_logoBytes != null) {
      return Image.memory(_logoBytes!, fit: BoxFit.cover);
    }
    if (_logoFile is File) {
      return Image.file(_logoFile as File, fit: BoxFit.cover);
    }
    return Icon(Icons.add_photo_alternate_outlined,
        color: AppTheme.primaryColor.withOpacity(0.5), size: 24);
  }

  // ── Step 4: Create account ────────────────────────────────────────────────

  Widget _buildAccount(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          _buildSummaryCard(theme),
          const SizedBox(height: 24),

          _stepHeader(theme, 'Create your account',
              "You're almost done. Enter your details below."),
          const SizedBox(height: 24),

          Form(
            key: _accountFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ThemedTextField(
                  controller: _fullNameCtrl,
                  label: 'Full name',
                  hint: 'Your full name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your full name'
                      : null,
                ),
                const SizedBox(height: 14),
                ThemedTextField(
                  controller: _emailCtrl,
                  label: 'Work email',
                  hint: 'you@company.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!AppConfig.isAdminEmailDomain(v)) {
                      return 'Invalid email domain. Use ${AppConfig.adminDomainsDisplay}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                ThemedTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: 'Minimum 6 characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                ThemedTextField(
                  controller: _confirmCtrl,
                  label: 'Confirm password',
                  hint: 'Re-enter password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),

          if (_error != null) _errorBanner(_error!),
          const SizedBox(height: 28),

          ThemedButton(
            onPressed: _isLoading ? null : _submitAccount,
            isLoading: _isLoading,
            child: const Text(
              'Create workspace',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'By continuing you agree to our Terms of Service and Privacy Policy.',
            style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.35)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        children: [
          Icon(_selectedPreset.icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyNameCtrl.text.trim().isEmpty
                      ? 'Your workspace'
                      : _companyNameCtrl.text.trim(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_selectedPreset.label} · ${_workerLabelCtrl.text.trim()}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _goTo(_Step.industry),
            child: Text('Edit',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _stepHeader(ThemeData theme, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              height: 1.4),
        ),
      ],
    );
  }

  Widget _errorBanner(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.25)),
        ),
        child: Text(msg,
            style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
      ),
    );
  }

  // ── Step 5: Invite admins & technicians ───────────────────────────────────

  Future<void> _sendInvites() async {
    final auth = context.read<AuthProvider>();
    final orgProvider = context.read<OrganizationProvider>();
    setState(() { _inviteSending = true; _inviteError = null; });

    // Send admin invites
    for (int i = 0; i < _adminInvites.length; i++) {
      final row = _adminInvites[i];
      if (row.email.text.trim().isEmpty) continue;
      try {
        await auth.createAdminAuthAccount(
          email: row.email.text.trim(),
          name: row.name.text.trim().isEmpty ? row.email.text.trim() : row.name.text.trim(),
          positionId: 'pending', // positions are assigned post-setup
        );
        setState(() => _adminResults[i] = true);
      } catch (_) {
        setState(() => _adminResults[i] = false);
      }
    }

    // Send technician invites
    for (int i = 0; i < _techInvites.length; i++) {
      final row = _techInvites[i];
      if (row.email.text.trim().isEmpty) continue;
      try {
        await auth.createTechnicianAuthAccount(
          email: row.email.text.trim(),
          name: row.name.text.trim().isEmpty ? row.email.text.trim() : row.name.text.trim(),
          department: row.department.text.trim().isEmpty ? null : row.department.text.trim(),
        );
        setState(() => _techResults[i] = true);
      } catch (_) {
        setState(() => _techResults[i] = false);
      }
    }

    setState(() => _inviteSending = false);
  }

  void _finishWizard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AdminHomeScreenErrorBoundary(
          child: AdminHomeScreen(key: const ValueKey('admin_home')),
        ),
      ),
      (r) => false,
    );
  }

  Widget _buildInvite(ThemeData theme) {
    final orgProvider = context.watch<OrganizationProvider>();
    final techLabel = orgProvider.workerLabelPlural.isEmpty
        ? 'Technicians'
        : orgProvider.workerLabelPlural;
    final departments = orgProvider.departments;

    final bool hasSentAny = _adminResults.isNotEmpty || _techResults.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(
            theme,
            'Invite your team',
            "Optional — collect details now and we'll send invite emails. You can always do this from the dashboard.",
          ),
          const SizedBox(height: 20),

          // Tab switcher
          Container(
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              children: [
                _inviteTabButton(theme, 0, 'Admins'),
                _inviteTabButton(theme, 1, techLabel),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Admin rows
          if (_inviteTab == 0) ...[
            // Note: admin invites require positions to be configured first
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Collect details now. Invites are sent when you tap "Send invites". '
                      'You can assign roles/positions after setup.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._adminInvites.asMap().entries.map((e) =>
              _buildInviteRow(
                theme,
                index: e.key,
                row: e.value,
                results: _adminResults,
                departments: const [],
                showDepartment: false,
                onRemove: _adminInvites.length > 1
                    ? () => setState(() {
                          _adminInvites[e.key].dispose();
                          _adminInvites.removeAt(e.key);
                          _adminResults.remove(e.key);
                        })
                    : null,
              ),
            ),
            _addRowButton(theme, () => setState(() => _adminInvites.add(_InviteRow()))),
          ],

          // Technician rows
          if (_inviteTab == 1) ...[
            ..._techInvites.asMap().entries.map((e) =>
              _buildInviteRow(
                theme,
                index: e.key,
                row: e.value,
                results: _techResults,
                departments: departments,
                showDepartment: true,
                onRemove: _techInvites.length > 1
                    ? () => setState(() {
                          _techInvites[e.key].dispose();
                          _techInvites.removeAt(e.key);
                          _techResults.remove(e.key);
                        })
                    : null,
              ),
            ),
            _addRowButton(theme, () => setState(() => _techInvites.add(_InviteRow()))),
          ],

          if (_inviteError != null) _errorBanner(_inviteError!),
          const SizedBox(height: 28),

          // Send invites button (only when there's something to send)
          if (!hasSentAny)
            ThemedButton(
              onPressed: _inviteSending ? null : _sendInvites,
              isLoading: _inviteSending,
              child: const Text(
                'Send invites',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
            ),

          // After sending — finish button
          if (hasSentAny) ...[
            _inviteSummaryBanner(theme),
            const SizedBox(height: 16),
            ThemedButton(
              onPressed: _finishWizard,
              child: const Text(
                'Go to dashboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
            ),
          ],

          const SizedBox(height: 12),
          TextButton(
            onPressed: _inviteSending ? null : _finishWizard,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
              textStyle: const TextStyle(fontSize: 14),
            ),
            child: Text(hasSentAny ? 'Skip remaining' : 'Skip for now'),
          ),
        ],
      ),
    );
  }

  Widget _inviteTabButton(ThemeData theme, int idx, String label) {
    final active = _inviteTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _inviteTab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteRow(
    ThemeData theme, {
    required int index,
    required _InviteRow row,
    required Map<int, bool?> results,
    required List<String> departments,
    required bool showDepartment,
    VoidCallback? onRemove,
  }) {
    final result = results[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result == true
            ? AppTheme.successColor.withOpacity(0.05)
            : result == false
                ? AppTheme.errorColor.withOpacity(0.05)
                : context.cardBackground,
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        border: Border.all(
          color: result == true
              ? AppTheme.successColor.withOpacity(0.4)
              : result == false
                  ? AppTheme.errorColor.withOpacity(0.3)
                  : context.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Person ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
              const Spacer(),
              if (result == true)
                Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.successColor)
              else if (result == false)
                Icon(Icons.error_rounded, size: 16, color: AppTheme.errorColor),
              if (onRemove != null && result == null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close_rounded,
                      size: 16, color: theme.colorScheme.onSurface.withOpacity(0.35)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ThemedTextField(
            controller: row.name,
            label: 'Full name',
            hint: 'e.g. John Smith',
            prefixIcon: Icons.person_outline_rounded,
            enabled: result == null,
          ),
          const SizedBox(height: 10),
          ThemedTextField(
            controller: row.email,
            label: 'Email',
            hint: 'e.g. john@company.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: result == null,
          ),
          const SizedBox(height: 10),
          ThemedTextField(
            controller: row.phone,
            label: 'Phone (optional)',
            hint: 'e.g. +1 234 567 8900',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: result == null,
          ),
          if (showDepartment) ...[
            const SizedBox(height: 10),
            if (departments.isEmpty)
              ThemedTextField(
                controller: row.department,
                label: 'Department (optional)',
                hint: 'e.g. Maintenance',
                prefixIcon: Icons.category_outlined,
                enabled: result == null,
              )
            else
              _departmentDropdown(theme, row, departments, result == null),
          ],
        ],
      ),
    );
  }

  Widget _departmentDropdown(
    ThemeData theme,
    _InviteRow row,
    List<String> departments,
    bool enabled,
  ) {
    return DropdownButtonFormField<String>(
      value: row.department.text.isEmpty ? null : row.department.text,
      decoration: InputDecoration(
        labelText: 'Department (optional)',
        prefixIcon: const Icon(Icons.category_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('— None —')),
        ...departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
      ],
      onChanged: enabled
          ? (v) => setState(() => row.department.text = v ?? '')
          : null,
    );
  }

  Widget _addRowButton(ThemeData theme, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cardBorder, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Add another',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteSummaryBanner(ThemeData theme) {
    final adminSent    = _adminResults.values.where((v) => v == true).length;
    final adminFailed  = _adminResults.values.where((v) => v == false).length;
    final techSent     = _techResults.values.where((v) => v == true).length;
    final techFailed   = _techResults.values.where((v) => v == false).length;
    final total        = adminSent + techSent;
    final failed       = adminFailed + techFailed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: failed > 0
            ? AppTheme.errorColor.withOpacity(0.06)
            : AppTheme.successColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: failed > 0
              ? AppTheme.errorColor.withOpacity(0.25)
              : AppTheme.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            failed > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            size: 18,
            color: failed > 0 ? AppTheme.errorColor : AppTheme.successColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              failed > 0
                  ? '$total invite${total == 1 ? '' : 's'} sent, $failed failed. '
                    'Check the rows marked in red.'
                  : '$total invite${total == 1 ? '' : 's'} sent successfully.',
              style: TextStyle(
                fontSize: 13,
                color: failed > 0 ? AppTheme.errorColor : AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
