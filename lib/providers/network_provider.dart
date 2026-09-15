import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  NetworkProvider() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> results;
    try {
      results = await _connectivity.checkConnectivity();
    } catch (e) {
      results = [ConnectivityResult.none];
    }
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool isCurrentlyOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
    if (_isOffline != isCurrentlyOffline) {
      _isOffline = isCurrentlyOffline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
