import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/gateway_provider.dart';
import '../widgets/gateway_controls.dart';
import '../widgets/status_card.dart';
import 'configure_screen.dart';
import 'onboarding_screen.dart';
import 'terminal_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hermes Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GatewayControls(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'QUICK ACTIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildActionCard(
              theme,
              'Onboarding',
              'Configure API keys and binding',
              icon: Icons.rocket_launch,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              ),
            ),
            _buildActionCard(
              theme,
              'Configure',
              'Edit gateway settings',
              icon: Icons.tune,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfigureScreen()),
              ),
            ),
            _buildActionCard(
              theme,
              'Terminal',
              'Open a proot shell',
              icon: Icons.terminal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TerminalScreen()),
              ),
            ),
            _buildActionCard(
              theme,
              'Logs',
              'View gateway logs',
              icon: Icons.article,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogsScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'STATUS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Consumer<GatewayProvider>(
              builder: (context, provider, _) {
                return _buildStatusCard(
                  theme,
                  'Gateway',
                  provider.statusLabel,
                  icon: provider.isRunning ? Icons.cloud_done : Icons.cloud_off,
                  color: provider.statusColor,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    ThemeData theme,
    String title,
    String subtitle, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    String title,
    String value, {
    required IconData icon,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return StatusCard(
      title: title,
      value: value,
      icon: icon,
      iconColor: color,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
