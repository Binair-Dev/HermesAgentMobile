import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../constants.dart';
import '../services/native_bridge.dart';
import '../services/preferences_service.dart';
import 'setup_wizard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  bool _autoStart = false;
  bool _batteryOptimized = true;
  String _arch = '';
  String _prootPath = '';
  Map<String, dynamic> _status = {};
  bool _loading = true;
  bool _storageGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _prefs.init();
    _autoStart = _prefs.autoStartGateway;

    try {
      final arch = await NativeBridge.getArch();
      final prootPath = await NativeBridge.getProotPath();
      final status = await NativeBridge.getBootstrapStatus();
      final batteryOptimized = await NativeBridge.isBatteryOptimized();
      final storageGranted = await NativeBridge.hasStoragePermission();

      setState(() {
        _batteryOptimized = batteryOptimized;
        _storageGranted = storageGranted;
        _arch = arch;
        _prootPath = prootPath;
        _status = status;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader(theme, 'GENERAL'),
                SwitchListTile(
                  title: const Text('Auto-start gateway'),
                  subtitle: const Text('Start the gateway when the app opens'),
                  value: _autoStart,
                  onChanged: (value) {
                    setState(() => _autoStart = value);
                    _prefs.autoStartGateway = value;
                  },
                ),
                ListTile(
                  title: const Text('Battery Optimization'),
                  subtitle: Text(_batteryOptimized
                      ? 'Optimized (may kill background sessions)'
                      : 'Unrestricted (recommended)'),
                  leading: const Icon(Icons.battery_alert),
                  trailing: _batteryOptimized
                      ? const Icon(Icons.warning, color: AppColors.statusAmber)
                      : const Icon(Icons.check_circle, color: AppColors.statusGreen),
                  onTap: () async {
                    await NativeBridge.requestBatteryOptimization();
                    final optimized = await NativeBridge.isBatteryOptimized();
                    setState(() => _batteryOptimized = optimized);
                  },
                ),
                ListTile(
                  title: const Text('Setup Storage'),
                  subtitle: Text(_storageGranted
                      ? 'Granted — proot can access /sdcard. Revoke if not needed.'
                      : 'Not granted (recommended) — tap to grant only if needed'),
                  leading: const Icon(Icons.sd_storage),
                  trailing: _storageGranted
                      ? const Icon(Icons.warning_amber, color: AppColors.statusAmber)
                      : const Icon(Icons.check_circle, color: AppColors.statusGreen),
                  onTap: () async {
                    await NativeBridge.requestStoragePermission();
                    final granted = await NativeBridge.hasStoragePermission();
                    setState(() => _storageGranted = granted);
                  },
                ),
                const Divider(),
                _sectionHeader(theme, 'SYSTEM INFO'),
                ListTile(
                  title: const Text('Architecture'),
                  subtitle: Text(_arch),
                  leading: const Icon(Icons.memory),
                ),
                ListTile(
                  title: const Text('PRoot path'),
                  subtitle: Text(_prootPath),
                  leading: const Icon(Icons.folder),
                ),
                ListTile(
                  title: const Text('Rootfs'),
                  subtitle: Text(_status['rootfsExists'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.storage),
                ),
                ListTile(
                  title: const Text('Python'),
                  subtitle: Text(_status['pythonInstalled'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.code),
                ),
                ListTile(
                  title: const Text('Hermes Agent'),
                  subtitle: Text(_status['hermesInstalled'] == true
                      ? 'Installed'
                      : 'Not installed'),
                  leading: const Icon(Icons.cloud),
                ),
                const Divider(),
                _sectionHeader(theme, 'MAINTENANCE'),
                ListTile(
                  title: const Text('Export Snapshot'),
                  subtitle: const Text('Backup config to Downloads'),
                  leading: const Icon(Icons.upload_file),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportSnapshot,
                ),
                ListTile(
                  title: const Text('Import Snapshot'),
                  subtitle: const Text('Restore config from backup'),
                  leading: const Icon(Icons.download),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importSnapshot,
                ),
                ListTile(
                  title: const Text('Re-run setup'),
                  subtitle: const Text('Reinstall or repair the environment'),
                  leading: const Icon(Icons.build),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const SetupWizardScreen(),
                    ),
                  ),
                ),
                const Divider(),
                _sectionHeader(theme, 'ABOUT'),
                const ListTile(
                  title: Text('Hermes Agent'),
                  subtitle: Text(
                    'AI Gateway for Android\nVersion ${AppConstants.version}',
                  ),
                  leading: Icon(Icons.info_outline),
                  isThreeLine: true,
                ),
                ListTile(
                  title: const Text('GitHub'),
                  subtitle: const Text('nousresearch/hermes-agent-mobile'),
                  leading: const Icon(Icons.code),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.githubUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(
                  title: const Text('Contact'),
                  subtitle: const Text(AppConstants.authorEmail),
                  leading: const Icon(Icons.email),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:${AppConstants.authorEmail}'),
                  ),
                ),
                const ListTile(
                  title: Text('License'),
                  subtitle: Text(AppConstants.license),
                  leading: Icon(Icons.description),
                ),
              ],
            ),
    );
  }

  Future<String> _getSnapshotPath() async {
    final hasPermission = await NativeBridge.hasStoragePermission();
    if (hasPermission) {
      final sdcard = await NativeBridge.getExternalStoragePath();
      final downloadDir = Directory('$sdcard/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return '$sdcard/Download/hermes-snapshot.json';
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/hermes-snapshot.json';
  }

  Future<void> _exportSnapshot() async {
    try {
      final hermesConfig = await NativeBridge.readRootfsFile('root/.hermes/config.yaml');
      final snapshot = {
        'version': AppConstants.version,
        'timestamp': DateTime.now().toIso8601String(),
        'hermesConfig': hermesConfig,
        'autoStart': _prefs.autoStartGateway,
      };
      final path = await _getSnapshotPath();
      await File(path).writeAsString(const JsonEncoder.withIndent('  ').convert(snapshot));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot saved to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importSnapshot() async {
    try {
      final path = await _getSnapshotPath();
      final file = File(path);
      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No snapshot found at $path')),
        );
        return;
      }
      final content = await file.readAsString();
      final snapshot = jsonDecode(content) as Map<String, dynamic>;
      final hermesConfig = snapshot['hermesConfig'] as String?;
      if (hermesConfig != null) {
        await NativeBridge.writeRootfsFile('root/.hermes/config.yaml', hermesConfig);
      }
      if (snapshot['autoStart'] != null) {
        _prefs.autoStartGateway = snapshot['autoStart'] as bool;
      }
      await _loadSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot restored successfully. Restart the gateway to apply.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
