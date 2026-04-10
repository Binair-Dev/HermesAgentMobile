import 'dart:async';
import 'package:flutter/material.dart';
import '../models/gateway_state.dart';
import '../services/gateway_service.dart' as svc;

class GatewayProvider extends ChangeNotifier {
  final svc.GatewayService _gatewayService = svc.GatewayService();
  StreamSubscription? _subscription;
  GatewayState _state = const GatewayState();

  GatewayState get state => _state;
  bool get isRunning => _state.isRunning;
  List<String> get logs => _state.logs;
  String get statusLabel => _state.statusText;
  Color get statusColor {
    switch (_state.status) {
      case GatewayStatus.running:
        return Colors.green;
      case GatewayStatus.starting:
        return Colors.orange;
      case GatewayStatus.error:
        return Colors.red;
      case GatewayStatus.stopped:
        return Colors.grey;
    }
  }

  GatewayProvider() {
    _subscription = _gatewayService.stateStream.listen((state) {
      _state = state;
      notifyListeners();
    });
    // Check if gateway is already running (e.g. after app restart)
    _gatewayService.init();
  }

  Future<void> start() async {
    await _gatewayService.start();
  }

  Future<void> stop() async {
    await _gatewayService.stop();
  }

  Future<bool> checkHealth() async {
    return _gatewayService.checkHealth();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _gatewayService.dispose();
    super.dispose();
  }
}
