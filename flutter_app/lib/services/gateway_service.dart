import 'dart:async';
import 'dart:io';
import '../constants.dart';
import '../models/gateway_state.dart';
import 'native_bridge.dart';
import 'preferences_service.dart';

class GatewayService {
  Timer? _healthTimer;
  Timer? _initialDelayTimer;
  StreamSubscription? _logSubscription;
  final _stateController = StreamController<GatewayState>.broadcast();
  GatewayState _state = const GatewayState();
  DateTime? _startingAt;
  bool _startInProgress = false;

  static String _ts(String msg) => '${DateTime.now().toUtc().toIso8601String()} $msg';

  Stream<GatewayState> get stateStream => _stateController.stream;
  GatewayState get state => _state;

  void _updateState(GatewayState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  Future<void> init() async {
    final prefs = PreferencesService();
    await prefs.init();

    try { await NativeBridge.setupDirs(); } catch (_) {}
    try { await NativeBridge.writeResolv(); } catch (_) {}
    try {
      final filesDir = await NativeBridge.getFilesDir();
      const resolvContent = 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n';
      final resolvFile = File('$filesDir/config/resolv.conf');
      if (!resolvFile.existsSync()) {
        Directory('$filesDir/config').createSync(recursive: true);
        resolvFile.writeAsStringSync(resolvContent);
      }
      final rootfsResolv = File('$filesDir/rootfs/ubuntu/etc/resolv.conf');
      if (!rootfsResolv.existsSync()) {
        rootfsResolv.parent.createSync(recursive: true);
        rootfsResolv.writeAsStringSync(resolvContent);
      }
    } catch (_) {}

    final alreadyRunning = await NativeBridge.isGatewayRunning();
    if (alreadyRunning) {
      _startingAt = DateTime.now();
      _updateState(_state.copyWith(
        status: GatewayStatus.starting,
        logs: [..._state.logs, _ts('[INFO] Gateway process detected, reconnecting...')],
      ));
      _subscribeLogs();
      _startHealthCheck();
    } else if (prefs.autoStartGateway) {
      _updateState(_state.copyWith(
        logs: [..._state.logs, _ts('[INFO] Auto-starting gateway...')],
      ));
      await start();
    }
  }

  void _subscribeLogs() {
    _logSubscription?.cancel();
    _logSubscription = NativeBridge.gatewayLogStream.listen((log) {
      final logs = [..._state.logs, log];
      if (logs.length > 500) {
        logs.removeRange(0, logs.length - 500);
      }
      _updateState(_state.copyWith(logs: logs));
    });
  }

  Future<void> start() async {
    if (_startInProgress) return;
    _startInProgress = true;

    _updateState(_state.copyWith(
      status: GatewayStatus.starting,
      clearError: true,
      logs: [..._state.logs, _ts('[INFO] Starting gateway...')],
    ));

    try {
      try { await NativeBridge.setupDirs(); } catch (_) {}
      try { await NativeBridge.writeResolv(); } catch (_) {}
      try {
        final filesDir = await NativeBridge.getFilesDir();
        const resolvContent = 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n';
        final resolvFile = File('$filesDir/config/resolv.conf');
        if (!resolvFile.existsSync()) {
          Directory('$filesDir/config').createSync(recursive: true);
          resolvFile.writeAsStringSync(resolvContent);
        }
        final rootfsResolv = File('$filesDir/rootfs/ubuntu/etc/resolv.conf');
        if (!rootfsResolv.existsSync()) {
          rootfsResolv.parent.createSync(recursive: true);
          rootfsResolv.writeAsStringSync(resolvContent);
        }
      } catch (_) {}

      _startingAt = DateTime.now();
      await NativeBridge.startGateway();
      _subscribeLogs();
      _startHealthCheck();
    } catch (e) {
      _updateState(_state.copyWith(
        status: GatewayStatus.error,
        errorMessage: 'Failed to start: $e',
        logs: [..._state.logs, _ts('[ERROR] Failed to start: $e')],
      ));
    } finally {
      _startInProgress = false;
    }
  }

  Future<void> stop() async {
    _cancelAllTimers();
    _logSubscription?.cancel();
    _startingAt = null;

    try {
      await NativeBridge.stopGateway();
      _updateState(GatewayState(
        status: GatewayStatus.stopped,
        logs: [..._state.logs, _ts('[INFO] Gateway stopped')],
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        status: GatewayStatus.error,
        errorMessage: 'Failed to stop: $e',
      ));
    }
  }

  void _cancelAllTimers() {
    _initialDelayTimer?.cancel();
    _initialDelayTimer = null;
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  void _startHealthCheck() {
    _cancelAllTimers();
    _initialDelayTimer = Timer(const Duration(seconds: 30), () {
      _initialDelayTimer = null;
      if (_state.status == GatewayStatus.stopped) return;
      _checkHealth();
      _healthTimer = Timer.periodic(
        const Duration(milliseconds: AppConstants.healthCheckIntervalMs),
        (_) => _checkHealth(),
      );
    });
  }

  Future<void> _checkHealth() async {
    try {
      final isRunning = await NativeBridge.isGatewayRunning();
      if (isRunning && _state.status != GatewayStatus.running) {
        _updateState(_state.copyWith(
          status: GatewayStatus.running,
          startedAt: DateTime.now(),
          logs: [..._state.logs, _ts('[INFO] Gateway is running')],
        ));
      } else if (!isRunning && _state.status != GatewayStatus.stopped) {
        if (_startingAt != null &&
            _state.status == GatewayStatus.starting &&
            DateTime.now().difference(_startingAt!).inSeconds < 120) {
          _updateState(_state.copyWith(
            logs: [..._state.logs, _ts('[INFO] Starting, waiting for gateway...')],
          ));
          return;
        }
        _updateState(_state.copyWith(
          status: GatewayStatus.stopped,
          logs: [..._state.logs, _ts('[WARN] Gateway process not running')],
        ));
        _cancelAllTimers();
      }
    } catch (_) {
      final isRunning = await NativeBridge.isGatewayRunning();
      if (!isRunning && _state.status != GatewayStatus.stopped) {
        if (_startingAt != null &&
            _state.status == GatewayStatus.starting &&
            DateTime.now().difference(_startingAt!).inSeconds < 120) {
          _updateState(_state.copyWith(
            logs: [..._state.logs, _ts('[INFO] Starting, waiting for gateway...')],
          ));
          return;
        }
        _updateState(_state.copyWith(
          status: GatewayStatus.stopped,
          logs: [..._state.logs, _ts('[WARN] Gateway process not running')],
        ));
        _cancelAllTimers();
      }
    }
  }

  Future<bool> checkHealth() async {
    return NativeBridge.isGatewayRunning();
  }

  void dispose() {
    _cancelAllTimers();
    _logSubscription?.cancel();
    _stateController.close();
  }
}
