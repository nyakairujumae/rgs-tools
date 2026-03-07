import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';
import '../services/organization_service.dart';
import '../utils/logger.dart';
import '../widgets/common/themed_text_field.dart';
import 'admin_home_screen.dart';

// ── Industry preset data ───────────────────────────────────────────────────

class _IndustryPreset {
  final String key;
  final String label;
  final IconData icon;
  final String workerLabel;
  final String workerLabelPlural;

  const _IndustryPreset({
    required this.key,
    required this.label,
    required this.icon,
    required this.workerLabel,
    required this.workerLabelPlural,
  });
}

const List<_IndustryPreset> _industryPresets = [
  _IndustryPreset(
    key: 'hvac',
    label: 'HVAC',
    icon: Icons.ac_unit_outlined,
    workerLabel: 'Technician',
    workerLabelPlural: 'Technicians',
  ),
  _IndustryPreset(
    key: 'electrical',
    label: 'Electrical',
    icon: Icons.electrical_services_outlined,
    workerLabel: 'Electrician',
    workerLabelPlural: 'Electricians',
  ),
  _IndustryPreset(
    key: 'fm',
    label: 'Facilities Management',
    icon: Icons.apartment_outlined,
    workerLabel: 'Operative',
    workerLabelPlural: 'Operatives',
  ),
  _IndustryPreset(
    key: 'construction',
    label: 'Construction',
    icon: Icons.construction_outlined,
    workerLabel: 'Site Worker',
    workerLabelPlural: 'Site Workers',
  ),
  _IndustryPreset(
    key: 'general',
    label: 'General / Other',
    icon: Icons.business_outlined,
    workerLabel: 'Worker',
    workerLabelPlural: 'Workers',
  ),
];

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

// ── Wizard screen ──────────────────────────────────────────────────────────

/// Company setup wizard for new multi-tenant onboarding.
/// Shown when user has no organization_id (first-time signup).
/// Steps: 1 Name → 2 Industry → 3 Logo → 4 Details → 5 Invite (optional)
class CompanySetupWizardScreen extends StatefulWidget {
  const CompanySetupWizardScreen({super.key});

  @override
  State<CompanySetupWizardScreen> createState() => _CompanySetupWizardScreenState();
}

class _CompanySetupWizardScreenState extends State<CompanySetupWizardScreen> {
  static const int _totalSteps = 5;

  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Step 1 — Company name
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();

  // Step 2 — Industry
  _IndustryPreset _selectedPreset = _industryPresets.first; // HVAC default
  late final TextEditingController _workerLabelController;
  late final TextEditingController _workerLabelPluralController;

  // Step 3 — Logo
  dynamic _logoFile;

  // Step 4 — Details
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _createdOrgId;

  // Step 5 — Invite
  final List<_InviteRow> _adminInvites = [_InviteRow()];
  final List<_InviteRow> _techInvites  = [_InviteRow()];
  int _inviteTab = 0;
  bool _inviteSending = false;
  final Map<int, bool?> _adminResults  = {};
  final Map<int, bool?> _techResults   = {};

  @override
  void initState() {
    super.initState();
    _workerLabelController = TextEditingController(text: _selectedPreset.workerLabel);
    _workerLabelPluralController = TextEditingController(text: _selectedPreset.workerLabelPlural);
    _nameController.addListener(_generateSlug);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _workerLabelController.dispose();
    _workerLabelPluralController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    for (final r in _adminInvites) { r.dispose(); }
    for (final r in _techInvites)  { r.dispose(); }
    super.dispose();
  }

  void _generateSlug() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (_slugController.text != slug) {
      _slugController.text = slug;
    }
  }

  void _selectPreset(_IndustryPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _workerLabelController.text = preset.workerLabel;
      _workerLabelPluralController.text = preset.workerLabelPlural;
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentStep = (_currentStep + 1).clamp(0, _totalSteps - 1);
      _error = null;
    });
  }

  // ── Step submissions ───────────────────────────────────────────────────────

  Future<void> _submitStep1() async {
    final name = _nameController.text.trim();
    final slug = _slugController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Company name is required');
      return;
    }
    if (slug.isEmpty) {
      setState(() => _error = 'Company slug is required');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _createdOrgId = await OrganizationService.createOrganizationAndAssignUser(
        name: name,
        slug: slug,
        industry: _selectedPreset.key,
        workerLabel: _workerLabelController.text.trim(),
        workerLabelPlural: _workerLabelPluralController.text.trim(),
      );
      if (!mounted) return;
      _nextPage();
    } catch (e) {
      Logger.debug('Error creating org: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          if (_error!.isEmpty) _error = 'Failed to create organization';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitStep3() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String? logoUrl;
      if (_logoFile != null && _createdOrgId != null) {
        logoUrl = await OrganizationService.uploadOrganizationLogo(
          _logoFile,
          _createdOrgId!,
        );
        if (logoUrl != null) {
          await OrganizationService.updateOrganizationSetup(
            orgId: _createdOrgId!,
            logoUrl: logoUrl,
          );
        }
      }
      if (!mounted) return;
      _nextPage();
    } catch (e) {
      Logger.debug('Error uploading logo: $e');
      if (mounted) {
        setState(() {
          _error = 'Could not upload logo. You can skip and add it later.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitStep4() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_createdOrgId != null) {
        await OrganizationService.updateOrganizationSetup(
          orgId: _createdOrgId!,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        );
      }
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      authProvider.clearNeedsCompanySetup();
      authProvider.refreshAuthState();
      // Reload org config now that org is fully set up
      if (_createdOrgId != null) {
        context.read<OrganizationProvider>().loadOrganization(_createdOrgId!);
      }
      // Go to optional invite step before navigating to dashboard
      _nextPage();
    } catch (e) {
      Logger.debug('Error completing setup: $e');
      if (mounted) {
        setState(() => _error = 'Could not save details');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() {
          _logoFile = kIsWeb ? picked : File(picked.path);
          _error = null;
        });
      }
    } catch (e) {
      Logger.debug('Error picking logo: $e');
      if (mounted) setState(() => _error = 'Could not pick image');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentStep
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Company name ───────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set up your company',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your company details to get started.',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Company name',
              hintText: 'e.g. Acme Services Ltd',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _slugController,
            decoration: const InputDecoration(
              labelText: 'Company slug (URL-friendly)',
              hintText: 'e.g. acme-services',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitStep1,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Industry ───────────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What type of company are you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll set up departments and tool categories to match your industry.',
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          // Industry selection grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: _industryPresets.map((preset) {
              final isSelected = _selectedPreset.key == preset.key;
              return GestureDetector(
                onTap: () => _selectPreset(preset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        preset.icon,
                        size: 32,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preset.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          // Worker label customization
          Text(
            'Your field team members are called…',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _workerLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Singular',
                    hintText: 'e.g. Technician',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _workerLabelPluralController,
                  decoration: const InputDecoration(
                    labelText: 'Plural',
                    hintText: 'e.g. Technicians',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You can change this later in Settings.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Logo ───────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add your company logo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional. You can add it later.',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _logoFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? FutureBuilder<Uint8List>(
                              future: (_logoFile as dynamic).readAsBytes() as Future<Uint8List>,
                              builder: (_, snap) {
                                if (snap.hasData) {
                                  return Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity);
                                }
                                return const Center(child: CircularProgressIndicator());
                              },
                            )
                          : Image.file(_logoFile as File, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 8),
                        Text('Tap to add logo', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: _isLoading ? null : _nextPage,
                child: const Text('Skip'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitStep3,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 4: Company details ────────────────────────────────────────────────

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Company details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional. You can add these later.',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address', hintText: 'e.g. 123 Main St', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone', hintText: 'e.g. +1 234 567 8900', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website', hintText: 'e.g. https://example.com', border: OutlineInputBorder()),
            keyboardType: TextInputType.url,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitStep4,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Invite team (optional) ────────────────────────────────────────

  void _finishWizard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminHomeScreenErrorBoundary(
          child: AdminHomeScreen(key: const ValueKey('admin_home')),
        ),
      ),
    );
  }

  Future<void> _sendInvites() async {
    final auth = context.read<AuthProvider>();
    setState(() => _inviteSending = true);

    for (int i = 0; i < _adminInvites.length; i++) {
      final row = _adminInvites[i];
      if (row.email.text.trim().isEmpty) continue;
      try {
        await auth.createAdminAuthAccount(
          email: row.email.text.trim(),
          name: row.name.text.trim().isEmpty ? row.email.text.trim() : row.name.text.trim(),
          positionId: 'pending',
        );
        setState(() => _adminResults[i] = true);
      } catch (_) {
        setState(() => _adminResults[i] = false);
      }
    }

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

  Widget _buildStep5() {
    final orgProvider = context.watch<OrganizationProvider>();
    final techLabel = orgProvider.workerLabelPlural.isEmpty ? 'Technicians' : orgProvider.workerLabelPlural;
    final departments = orgProvider.departments;
    final bool hasSentAny = _adminResults.isNotEmpty || _techResults.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invite your team',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "Optional. Collect details and send invite emails. You can do this from the dashboard too.",
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Tab switcher
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                _tabButton(0, 'Admins'),
                _tabButton(1, techLabel),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_inviteTab == 0) ...[
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
                      'Collect details now. You can assign roles/positions after setup.',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            ..._adminInvites.asMap().entries.map((e) =>
              _inviteRow(
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
            _addRowBtn(() => setState(() => _adminInvites.add(_InviteRow()))),
          ],

          if (_inviteTab == 1) ...[
            ..._techInvites.asMap().entries.map((e) =>
              _inviteRow(
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
            _addRowBtn(() => setState(() => _techInvites.add(_InviteRow()))),
          ],

          const SizedBox(height: 24),

          if (hasSentAny) ...[
            _summaryBanner(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _finishWizard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Go to dashboard'),
            ),
          ] else
            ElevatedButton(
              onPressed: _inviteSending ? null : _sendInvites,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _inviteSending
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send invites'),
            ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: _inviteSending ? null : _finishWizard,
            child: Text(
              hasSentAny ? 'Skip remaining' : 'Skip for now',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int idx, String label) {
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
              color: active ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inviteRow({
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
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result == true
              ? AppTheme.successColor.withOpacity(0.4)
              : result == false
                  ? AppTheme.errorColor.withOpacity(0.3)
                  : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Person ${index + 1}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
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
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: row.name,
            enabled: result == null,
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'e.g. John Smith',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: row.email,
            enabled: result == null,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'e.g. john@company.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: row.phone,
            enabled: result == null,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              hintText: 'e.g. +1 234 567 8900',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (showDepartment) ...[
            const SizedBox(height: 10),
            if (departments.isEmpty)
              TextField(
                controller: row.department,
                enabled: result == null,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                  hintText: 'e.g. Maintenance',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: row.department.text.isEmpty ? null : row.department.text,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('— None —')),
                  ...departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                ],
                onChanged: result == null
                    ? (v) => setState(() => row.department.text = v ?? '')
                    : null,
              ),
          ],
        ],
      ),
    );
  }

  Widget _addRowBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Add another',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBanner() {
    final adminSent   = _adminResults.values.where((v) => v == true).length;
    final adminFailed = _adminResults.values.where((v) => v == false).length;
    final techSent    = _techResults.values.where((v) => v == true).length;
    final techFailed  = _techResults.values.where((v) => v == false).length;
    final total  = adminSent + techSent;
    final failed = adminFailed + techFailed;

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
                  ? '$total invite${total == 1 ? '' : 's'} sent, $failed failed. Check the rows marked in red.'
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
