import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'role_selection_screen.dart';
import 'auth/login_screen.dart';

// ─────────────────────────────────────────────────────────
// Main screen — single page, cycling animated illustrations
// ─────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _slide = 0;
  static const _slideCount = 3;
  static const _slideDuration = Duration(seconds: 4);

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.value = 1.0;
    _startCycle();
  }

  void _startCycle() {
    Future.delayed(_slideDuration, () {
      if (!mounted) return;
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _slide = (_slide + 1) % _slideCount);
        _fadeCtrl.forward().then((_) => _startCycle());
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _getStarted() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  void _signIn() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 36),

            // ── Logo ──
            Image.asset(
              'assets/images/logo_light.png',
              height: 40,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 32),

            // ── Headline (fades with slide) ──
            FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      _headlines[_slide],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _subtitles[_slide],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Animated illustration ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fade,
                  child: _illustrations[_slide],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Slide dots ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slideCount, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _slide ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _slide
                        ? AppTheme.primaryColor
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _getStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Get started'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _signIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  static const _headlines = [
    'Every tool,\nalways accounted for.',
    'Assign in seconds,\nnot spreadsheets.',
    'Real-time insights\nfor your whole team.',
  ];

  static const _subtitles = [
    'Track status, location, and history for every piece of equipment — from one screen.',
    'Drag a tool to a technician. They get notified instantly. Full audit trail, zero paperwork.',
    'Utilisation rates, costs, and team performance — live, without lifting a pen.',
  ];

  static const _illustrations = [
    _ToolListIllustration(),
    _AssignIllustration(),
    _AnalyticsIllustration(),
  ];
}

// ═══════════════════════════════════════════════════════════
//  ILLUSTRATION 1 — Tool List (cards scroll up in a loop)
// ═══════════════════════════════════════════════════════════
class _ToolListIllustration extends StatefulWidget {
  const _ToolListIllustration();

  @override
  State<_ToolListIllustration> createState() => _ToolListIllustrationState();
}

class _ToolListIllustrationState extends State<_ToolListIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _tools = [
    ('Hilti TE 6-A36',    'In Use',      Color(0xFF2563EB), Icons.handyman_rounded),
    ('Bosch GBH 18V',     'Available',   Color(0xFF059669), Icons.construction_rounded),
    ('DeWalt DCD996',     'Maintenance', Color(0xFFF59E0B), Icons.build_rounded),
    ('Milwaukee M18',     'Available',   Color(0xFF059669), Icons.electrical_services_rounded),
    ('Makita DHR243',     'In Use',      Color(0xFF2563EB), Icons.hardware_rounded),
    ('Stanley FatMax',    'Available',   Color(0xFF059669), Icons.handyman_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Search tools…',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Filter',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Scrolling list
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                const itemH = 60.0;
                final offset = _ctrl.value * _tools.length * itemH;
                return ClipRect(
                  child: Stack(
                    children: List.generate(_tools.length * 2, (i) {
                      final tool = _tools[i % _tools.length];
                      final y = i * itemH - offset;
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: y,
                        height: itemH - 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _ToolRow(
                            name: tool.$1,
                            status: tool.$2,
                            statusColor: tool.$3,
                            icon: tool.$4,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ILLUSTRATION 2 — Assignment flow
// ═══════════════════════════════════════════════════════════
class _AssignIllustration extends StatefulWidget {
  const _AssignIllustration();

  @override
  State<_AssignIllustration> createState() => _AssignIllustrationState();
}

class _AssignIllustrationState extends State<_AssignIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AssignCard(
                  icon: Icons.handyman_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: 'Hilti TE 6-A36',
                  sub: 'Power Drill · Serial #HT-2024',
                  trailing: t > 0.7
                      ? _StatusBadge('Assigned', AppTheme.primaryColor)
                      : _StatusBadge('Available', const Color(0xFF059669)),
                ),

                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(2, double.infinity),
                        painter: _DashedLinePainter(t: t),
                      ),
                      if (t > 0.35 && t < 0.75)
                        Positioned(
                          top: ((t - 0.35) / 0.4).clamp(0, 1) * 60 + 10,
                          child: _TravelDot(color: AppTheme.primaryColor),
                        ),
                      if (t > 0.7)
                        const Positioned(
                          child: Icon(Icons.check_circle_rounded,
                              color: Color(0xFF059669), size: 22),
                        ),
                    ],
                  ),
                ),

                _AssignCard(
                  icon: Icons.person_rounded,
                  iconColor: AppTheme.secondaryColor,
                  title: 'Ahmad Hassan',
                  sub: 'Senior Technician · Site A',
                  trailing: t > 0.7
                      ? _StatusBadge('Notified 🔔', AppTheme.secondaryColor)
                      : _StatusBadge('4 tools', const Color(0xFF64748B)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ILLUSTRATION 3 — Analytics dashboard
// ═══════════════════════════════════════════════════════════
class _AnalyticsIllustration extends StatefulWidget {
  const _AnalyticsIllustration();

  @override
  State<_AnalyticsIllustration> createState() => _AnalyticsIllustrationState();
}

class _AnalyticsIllustrationState extends State<_AnalyticsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _grow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _grow = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bars = [0.55, 0.82, 0.40, 0.93, 0.65, 0.78, 0.88];
    final barColors = [
      AppTheme.primaryColor.withValues(alpha: 0.5),
      AppTheme.primaryColor,
      AppTheme.primaryColor.withValues(alpha: 0.35),
      const Color(0xFF7C3AED),
      AppTheme.primaryColor.withValues(alpha: 0.6),
      AppTheme.primaryColor,
      const Color(0xFF7C3AED).withValues(alpha: 0.7),
    ];

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _grow,
              builder: (_, __) => Row(
                children: [
                  _KpiBox('48', 'Total Tools', AppTheme.primaryColor, Icons.handyman_rounded, _grow.value),
                  const SizedBox(width: 8),
                  _KpiBox('78%', 'Utilisation', const Color(0xFF7C3AED), Icons.pie_chart_rounded, _grow.value),
                  const SizedBox(width: 8),
                  _KpiBox('4', 'Maintenance', const Color(0xFFF59E0B), Icons.build_rounded, _grow.value),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Weekly tool usage',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedBuilder(
                animation: _grow,
                builder: (_, __) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(bars.length, (i) {
                    final delay = i * 0.1;
                    final t = (((_grow.value) - delay) / (1 - delay)).clamp(0.0, 1.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: bars[i] * t,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: barColors[i],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ToolRow extends StatelessWidget {
  final String name;
  final String status;
  final Color statusColor;
  final IconData icon;

  const _ToolRow({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: statusColor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
          ),
        ],
      ),
    );
  }
}

class _AssignCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  final Widget trailing;

  const _AssignCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TravelDot extends StatelessWidget {
  final Color color;
  const _TravelDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final double progress;

  const _KpiBox(this.value, this.label, this.color, this.icon, this.progress);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 5),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final double t;
  _DashedLinePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    const dashH = 6.0;
    const gap = 4.0;
    double y = -(t * (dashH + gap) * 4);
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dashH).clamp(0, size.height)),
        paint,
      );
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.t != t;
}

