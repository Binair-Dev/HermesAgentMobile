import 'package:flutter/services.dart';
import '../constants.dart';

class NativeBridge {
  static const _channel = MethodChannel(AppConstants.channelName);
  static const _eventChannel = EventChannel(AppConstants.eventChannelName);

  static Future<String> getProotPath() async {
    return await _channel.invokeMethod('getProotPath');
  }

  static Future<String> getArch() async {
    return await _channel.invokeMethod('getArch');
  }

  static Future<String> getFilesDir() async {
    return await _channel.invokeMethod('getFilesDir');
  }

  static Future<String> getNativeLibDir() async {
    return await _channel.invokeMethod('getNativeLibDir');
  }

  static Future<bool> isBootstrapComplete() async {
    return await _channel.invokeMethod('isBootstrapComplete');
  }

  static Future<Map<String, dynamic>> getBootstrapStatus() async {
    final result = await _channel.invokeMethod('getBootstrapStatus');
    return Map<String, dynamic>.from(result);
  }

  static Future<bool> extractRootfs(String tarPath) async {
    return await _channel.invokeMethod('extractRootfs', {'tarPath': tarPath});
  }

  static Future<String> runInProot(String command, {int timeout = 900}) async {
    return await _channel.invokeMethod('runInProot', {'command': command, 'timeout': timeout});
  }

  static Future<bool> startGateway() async {
    return await _channel.invokeMethod('startGateway');
  }

  static Future<bool> stopGateway() async {
    return await _channel.invokeMethod('stopGateway');
  }

  static Future<bool> isGatewayRunning() async {
    return await _channel.invokeMethod('isGatewayRunning');
  }

  static Future<bool> setupDirs() async {
    return await _channel.invokeMethod('setupDirs');
  }

  static Future<bool> writeResolv() async {
    return await _channel.invokeMethod('writeResolv');
  }

  static Future<String> readRootfsFile(String path) async {
    return await _channel.invokeMethod('readRootfsFile', {'path': path});
  }

  static Future<bool> writeRootfsFile(String path, String content) async {
    return await _channel.invokeMethod('writeRootfsFile', {'path': path, 'content': content});
  }

  static Future<bool> hasStoragePermission() async {
    return await _channel.invokeMethod('hasStoragePermission');
  }

  static Future<bool> requestStoragePermission() async {
    return await _channel.invokeMethod('requestStoragePermission');
  }

  static Future<String> getExternalStoragePath() async {
    return await _channel.invokeMethod('getExternalStoragePath');
  }

  static Future<bool> isBatteryOptimized() async {
    return await _channel.invokeMethod('isBatteryOptimized');
  }

  static Future<bool> requestBatteryOptimization() async {
    return await _channel.invokeMethod('requestBatteryOptimization');
  }

  static Future<bool> startTerminalService() async {
    return await _channel.invokeMethod('startTerminalService');
  }

  static Future<bool> stopTerminalService() async {
    return await _channel.invokeMethod('stopTerminalService');
  }

  static Future<bool> startSetupService() async {
    return await _channel.invokeMethod('startSetupService');
  }

  static Future<bool> stopSetupService() async {
    return await _channel.invokeMethod('stopSetupService');
  }

  static void updateSetupNotification(String text, {int progress = -1}) {
    _channel.invokeMethod('updateSetupNotification', {
      'text': text,
      'progress': progress,
    });
  }

  static Stream<String> get gatewayLogStream async* {
    await for (final event in _eventChannel.receiveBroadcastStream()) {
      if (event is String) yield event;
    }
  }
}
