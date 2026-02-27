import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Provider to monitor and expose connectivity status.
/// Re-checks when app resumes so the offline banner clears after reconnecting.
class ConnectivityProvider with ChangeNotifier, WidgetsBindingObserver {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = true;
  StreamSubscription<bool>? _subscription;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initialize() async {
    // Initialize connectivity service
    await _connectivityService.initialize();
    
    // Get initial status
    _isOnline = await _connectivityService.checkConnectivity();
    notifyListeners();

    // Listen to connectivity changes
    _subscription = _connectivityService.connectivityStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckConnectivity();
    }
  }

  Future<void> _recheckConnectivity() async {
    final nowOnline = await _connectivityService.checkConnectivity();
    if (_isOnline != nowOnline) {
      _isOnline = nowOnline;
      notifyListeners();
    }
  }

  /// Public recheck for pull-to-refresh or manual refresh.
  Future<void> recheckConnectivity() => _recheckConnectivity();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}

