import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResult);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize connectivity service: $e');
    }
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(ConnectivityResult connectivityResult) {
    final wasOnline = _isOnline;

    // Consider online if connection type is available (except none)
    _isOnline = connectivityResult != ConnectivityResult.none;

    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      debugPrint('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Failed to check connectivity: $e');
      return false;
    }
  }

  /// Get detailed connectivity information
  Future<Map<String, dynamic>> getConnectivityInfo() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      return {
        'isOnline': connectivityResult != ConnectivityResult.none,
        'connectionType': connectivityResult.name,
        'hasWifi': connectivityResult == ConnectivityResult.wifi,
        'hasMobile': connectivityResult == ConnectivityResult.mobile,
        'hasEthernet': connectivityResult == ConnectivityResult.ethernet,
      };
    } catch (e) {
      debugPrint('Failed to get connectivity info: $e');
      return {
        'isOnline': false,
        'connectionType': 'none',
        'hasWifi': false,
        'hasMobile': false,
        'hasEthernet': false,
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
