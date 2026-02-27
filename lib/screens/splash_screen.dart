import 'dart:async';

import 'package:flutter/material.dart';

/// Simple animated splash used while the auth/profile providers warm up.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.timeout = const Duration(seconds: 8),
    this.onTimeout,
  });

  /// How long we keep showing the animated splash before surfacing an action.
  final Duration timeout;

  /// Called once the timeout elapses – useful for logging or metrics.
  final VoidCallback? onTimeout;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    lowerBound: 0.92,
    upperBound: 1.04,
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnimation =
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

  Timer? _statusTimer;
  Timer? _timeoutTimer;
  int _statusIndex = 0;
  bool _showContinue = false;

  static const List<String> _statusMessages = [
    'Preparing secure workspace…',
    'Connecting to Supabase…',
    'Syncing offline cache…',
    'Fetching role & permissions…',
    'Optimizing dashboards…',
  ];

  @override
  void initState() {
    super.initState();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => setState(
        () => _statusIndex = (_statusIndex + 1) % _statusMessages.length,
      ),
    );
    _timeoutTimer = Timer(widget.timeout, () {
      if (!mounted) return;
      setState(() => _showContinue = true);
      widget.onTimeout?.call();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'RGS Tools',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Precision tools management for HVAC pros',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white24,
                  minHeight: 6,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _statusMessages[_statusIndex],
                    key: ValueKey(_statusIndex),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showContinue ? 1 : 0,
                  child: Column(
                    children: [
                      Text(
                        'Taking longer than expected? You can continue anyway.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Continue'),
                        onPressed: widget.onTimeout,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock, color: Colors.white38, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Securely syncing workspace',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
