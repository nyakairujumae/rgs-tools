import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Provider to monitor and expose connectivity status.
/// Re-checks when app resumes so the offline banner clears after reconnecting.
class ConnectivityProvider with ChangeNotifier, WidgetsBindingObserver {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = true;
  StreamSubscription<bool>? _subscription;
  Timer? _pollingTimer;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initialize() async {
    await _connectivityService.initialize();

    _isOnline = await _connectivityService.checkConnectivity();
    notifyListeners();

    _subscription = _connectivityService.connectivityStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      // Start polling when offline so banner clears as soon as internet returns
      if (!isOnline) {
        _startPolling();
      } else {
        _stopPolling();
      }
    });
  }

  void _startPolling() {
    if (_pollingTimer != null) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final nowOnline = await _connectivityService.checkConnectivity();
      if (nowOnline != _isOnline) {
        _isOnline = nowOnline;
        notifyListeners();
      }
      if (_isOnline) _stopPolling();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
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
    if (!_isOnline) _startPolling();
  }

  /// Public recheck for pull-to-refresh or manual refresh.
  Future<void> recheckConnectivity() => _recheckConnectivity();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _stopPolling();
    super.dispose();
  }
}

