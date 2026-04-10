import 'dart:io';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../models/setup_state.dart';
import 'native_bridge.dart';

class BootstrapService {
  final Dio _dio = Dio();

  void _updateSetupNotification(String text, {int progress = -1}) {
    try {
      NativeBridge.updateSetupNotification(text, progress: progress);
    } catch (_) {}
  }

  void _stopSetupService() {
    try {
      NativeBridge.stopSetupService();
    } catch (_) {}
  }

  Future<SetupState> checkStatus() async {
    try {
      final complete = await NativeBridge.isBootstrapComplete();
      if (complete) {
        return const SetupState(
          step: SetupStep.complete,
          progress: 1.0,
          message: 'Setup complete',
        );
      }
      return const SetupState(
        step: SetupStep.checkingStatus,
        progress: 0.0,
        message: 'Setup required',
      );
    } catch (e) {
      return SetupState(
        step: SetupStep.error,
        error: 'Failed to check status: $e',
      );
    }
  }

  Future<void> runFullSetup({
    required void Function(SetupState) onProgress,
  }) async {
    try {
      try {
        await NativeBridge.startSetupService();
      } catch (_) {}

      onProgress(const SetupState(
        step: SetupStep.checkingStatus,
        progress: 0.0,
        message: 'Setting up directories...',
      ));
      _updateSetupNotification('Setting up directories...', progress: 2);
      try { await NativeBridge.setupDirs(); } catch (_) {}
      try { await NativeBridge.writeResolv(); } catch (_) {}

      final arch = await NativeBridge.getArch();
      final rootfsUrl = AppConstants.getRootfsUrl(arch);
      final filesDir = await NativeBridge.getFilesDir();

      const resolvContent = 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n';
      try {
        final configDir = '$filesDir/config';
        final resolvFile = File('$configDir/resolv.conf');
        if (!resolvFile.existsSync()) {
          Directory(configDir).createSync(recursive: true);
          resolvFile.writeAsStringSync(resolvContent);
        }
        final rootfsResolv = File('$filesDir/rootfs/ubuntu/etc/resolv.conf');
        if (!rootfsResolv.existsSync()) {
          rootfsResolv.parent.createSync(recursive: true);
          rootfsResolv.writeAsStringSync(resolvContent);
        }
      } catch (_) {}
      final tarPath = '$filesDir/tmp/ubuntu-rootfs.tar.gz';

      _updateSetupNotification('Downloading Ubuntu rootfs...', progress: 5);
      onProgress(const SetupState(
        step: SetupStep.downloadingRootfs,
        progress: 0.0,
        message: 'Downloading Ubuntu rootfs...',
      ));

      await _dio.download(
        rootfsUrl,
        tarPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            final mb = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
            final notifProgress = 5 + (progress * 25).round();
            _updateSetupNotification('Downloading rootfs: $mb / $totalMb MB', progress: notifProgress);
            onProgress(SetupState(
              step: SetupStep.downloadingRootfs,
              progress: progress,
              message: 'Downloading: $mb MB / $totalMb MB',
            ));
          }
        },
      );

      _updateSetupNotification('Extracting rootfs...', progress: 30);
      onProgress(const SetupState(
        step: SetupStep.extractingRootfs,
        progress: 0.0,
        message: 'Extracting rootfs (this takes a while)...',
      ));
      await NativeBridge.extractRootfs(tarPath);
      onProgress(const SetupState(
        step: SetupStep.extractingRootfs,
        progress: 1.0,
        message: 'Rootfs extracted',
      ));

      _updateSetupNotification('Fixing rootfs permissions...', progress: 45);
      onProgress(const SetupState(
        step: SetupStep.installingPython,
        progress: 0.0,
        message: 'Fixing rootfs permissions...',
      ));
      await NativeBridge.runInProot(
        'chmod -R 755 /usr/bin /usr/sbin /bin /sbin '
        '/usr/local/bin /usr/local/sbin 2>/dev/null; '
        'chmod -R +x /usr/lib/apt/ /usr/lib/dpkg/ /usr/libexec/ '
        '/var/lib/dpkg/info/ /usr/share/debconf/ 2>/dev/null; '
        'chmod 755 /lib/*/ld-linux-*.so* /usr/lib/*/ld-linux-*.so* 2>/dev/null; '
        'mkdir -p /var/lib/dpkg/updates /var/lib/dpkg/triggers; '
        'echo permissions_fixed',
      );

      _updateSetupNotification('Updating package lists...', progress: 48);
      onProgress(const SetupState(
        step: SetupStep.installingPython,
        progress: 0.1,
        message: 'Updating package lists...',
      ));
      await NativeBridge.runInProot('apt-get update -y');

      _updateSetupNotification('Installing base packages...', progress: 52);
      onProgress(const SetupState(
        step: SetupStep.installingPython,
        progress: 0.15,
        message: 'Installing base packages...',
      ));
      await NativeBridge.runInProot(
        'ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime && '
        'echo "Etc/UTC" > /etc/timezone',
      );
      await NativeBridge.runInProot(
        'apt-get install -y --no-install-recommends '
        'ca-certificates git python3 python3-venv python3-pip curl wget',
      );

      _updateSetupNotification('Cloning Hermes Agent...', progress: 70);
      onProgress(const SetupState(
        step: SetupStep.installingHermesAgent,
        progress: 0.0,
        message: 'Cloning Hermes Agent repository...',
      ));
      await NativeBridge.runInProot(
        'cd /root && '
        'rm -rf hermes-agent && '
        'git clone https://github.com/nousresearch/hermes-agent.git hermes-agent',
        timeout: 600,
      );

      _updateSetupNotification('Installing Python dependencies...', progress: 85);
      onProgress(const SetupState(
        step: SetupStep.installingHermesAgent,
        progress: 0.5,
        message: 'Installing Python dependencies...',
      ));
      await NativeBridge.runInProot(
        'cd /root/hermes-agent && '
        'python3 -m venv venv && '
        'source venv/bin/activate && '
        'pip install --upgrade pip && '
        'pip install -r requirements.txt',
        timeout: 1800,
      );

      _updateSetupNotification('Verifying installation...', progress: 96);
      onProgress(const SetupState(
        step: SetupStep.installingHermesAgent,
        progress: 0.9,
        message: 'Verifying Hermes Agent installation...',
      ));
      await NativeBridge.runInProot(
        'test -f /root/hermes-agent/gateway/run.py && echo hermes_ready',
      );
      onProgress(const SetupState(
        step: SetupStep.installingHermesAgent,
        progress: 1.0,
        message: 'Hermes Agent installed',
      ));

      _updateSetupNotification('Setup complete!', progress: 100);
      onProgress(const SetupState(
        step: SetupStep.configuringEnvironment,
        progress: 1.0,
        message: 'Environment configured',
      ));

      _stopSetupService();
      onProgress(const SetupState(
        step: SetupStep.complete,
        progress: 1.0,
        message: 'Setup complete! Ready to start the agent.',
      ));
    } on DioException catch (e) {
      _stopSetupService();
      onProgress(SetupState(
        step: SetupStep.error,
        error: 'Download failed: ${e.message}. Check your internet connection.',
      ));
    } catch (e) {
      _stopSetupService();
      onProgress(SetupState(
        step: SetupStep.error,
        error: 'Setup failed: $e',
      ));
    }
  }
}
