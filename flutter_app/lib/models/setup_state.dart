enum SetupStep {
  checkingStatus,
  downloadingRootfs,
  extractingRootfs,
  installingPython,
  installingHermesAgent,
  configuringEnvironment,
  complete,
  error,
}

class SetupState {
  final SetupStep step;
  final double progress;
  final String message;
  final String? error;

  const SetupState({
    this.step = SetupStep.checkingStatus,
    this.progress = 0.0,
    this.message = '',
    this.error,
  });

  SetupState copyWith({
    SetupStep? step,
    double? progress,
    String? message,
    String? error,
  }) {
    return SetupState(
      step: step ?? this.step,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error,
    );
  }

  bool get isComplete => step == SetupStep.complete;
  bool get hasError => step == SetupStep.error;

  String get stepLabel {
    switch (step) {
      case SetupStep.checkingStatus:
        return 'Checking status...';
      case SetupStep.downloadingRootfs:
        return 'Downloading Ubuntu rootfs';
      case SetupStep.extractingRootfs:
        return 'Extracting rootfs';
      case SetupStep.installingPython:
        return 'Installing Python';
      case SetupStep.installingHermesAgent:
        return 'Installing Hermes Agent';
      case SetupStep.configuringEnvironment:
        return 'Configuring environment';
      case SetupStep.complete:
        return 'Setup complete';
      case SetupStep.error:
        return 'Error';
    }
  }

  int get stepNumber {
    switch (step) {
      case SetupStep.checkingStatus:
        return 0;
      case SetupStep.downloadingRootfs:
        return 1;
      case SetupStep.extractingRootfs:
        return 2;
      case SetupStep.installingPython:
        return 3;
      case SetupStep.installingHermesAgent:
        return 4;
      case SetupStep.configuringEnvironment:
        return 5;
      case SetupStep.complete:
        return 6;
      case SetupStep.error:
        return -1;
    }
  }

  static const int totalSteps = 6;
}
