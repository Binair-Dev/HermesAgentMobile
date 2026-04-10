import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../constants.dart';
import '../models/setup_state.dart';
import '../providers/setup_provider.dart';
import '../widgets/progress_step.dart';
import 'dashboard_screen.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Consumer<SetupProvider>(
          builder: (context, provider, _) {
            final state = provider.state;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Image.asset(
                    'assets/ic_launcher.png',
                    width: 64,
                    height: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Setup Hermes Agent',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _started
                        ? 'Setting up the environment. This may take several minutes.'
                        : 'This will download Ubuntu, Python, and Hermes Agent into a self-contained environment.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _buildSteps(state, theme),
                  ),
                  if (state.hasError) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  state.error ?? 'Unknown error',
                                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.isComplete)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _goToDashboard(context),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Go to Dashboard'),
                      ),
                    )
                  else if (!_started || state.hasError)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: provider.isRunning
                            ? null
                            : () {
                                setState(() => _started = true);
                                provider.runSetup();
                              },
                        icon: const Icon(Icons.download),
                        label: Text(_started ? 'Retry Setup' : 'Begin Setup'),
                      ),
                    ),
                  if (!_started) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Requires ~500MB of storage and an internet connection',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'by ${AppConstants.authorName} | ${AppConstants.orgName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSteps(SetupState state, ThemeData theme) {
    final steps = [
      (1, 'Download Ubuntu rootfs', SetupStep.downloadingRootfs),
      (2, 'Extract rootfs', SetupStep.extractingRootfs),
      (3, 'Install Python', SetupStep.installingPython),
      (4, 'Install Hermes Agent', SetupStep.installingHermesAgent),
      (5, 'Configure environment', SetupStep.configuringEnvironment),
    ];

    return ListView(
      children: [
        for (final (num, label, step) in steps)
          ProgressStep(
            stepNumber: num,
            label: state.step == step ? state.message : label,
            isActive: state.step == step,
            isComplete: state.stepNumber > step.index || state.isComplete,
            hasError: state.hasError && state.step == step,
            progress: state.step == step ? state.progress : null,
          ),
        if (state.isComplete) ...[
          const ProgressStep(
            stepNumber: 6,
            label: 'Setup complete!',
            isComplete: true,
          ),
        ],
      ],
    );
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }
}
