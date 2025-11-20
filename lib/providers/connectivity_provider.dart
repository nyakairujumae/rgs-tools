import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Provider to monitor and expose connectivity status
class ConnectivityProvider with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = true;
  StreamSubscription<bool>? _subscription;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initialize();
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
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

