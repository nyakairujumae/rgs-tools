import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    _connectivityController.add(_isOnline);

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      final wasOnline = _isOnline;
      _isOnline = result.any((r) => _isConnected([r]));
      
      // Only notify if status changed
      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        debugPrint('🌐 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      }
    });
  }

  /// Check if connectivity result indicates online status
  bool _isConnected(List<ConnectivityResult> results) {
    // On web, we assume online (browser handles connectivity)
    if (kIsWeb) {
      return true;
    }

    // Check if any result indicates connectivity
    for (final result in results) {
      if (result != ConnectivityResult.none) {
        return true;
      }
    }
    return false;
  }

  /// Check current connectivity status and notify stream if changed
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final nowOnline = _isConnected(result);
    if (_isOnline != nowOnline) {
      _isOnline = nowOnline;
      _connectivityController.add(_isOnline);
      debugPrint('🌐 Connectivity re-check: ${_isOnline ? "Online" : "Offline"}');
    }
    return _isOnline;
  }

  void dispose() {
    _connectivityController.close();
  }
}



