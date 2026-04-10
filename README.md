# Hermes Agent Mobile

[![Download APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://github.com/Binair-Dev/HermesAgentMobile/releases/latest)
[![Build Flutter APK & AAB](https://github.com/Binair-Dev/HermesAgentMobile/actions/workflows/flutter-build.yml/badge.svg)](https://github.com/Binair-Dev/HermesAgentMobile/actions/workflows/flutter-build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)](https://python.org/)
[![Android](https://img.shields.io/badge/Android-10%2B-brightgreen?logo=android)](https://www.android.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter)](https://flutter.dev/)

> Run **Hermes Agent AI Gateway** on Android — standalone Flutter app with built-in terminal, gateway controls, and one-tap setup. Also available as a Termux CLI package.

> **Credits & Origin**  
> The mobile shell, proot integration, terminal emulator, and app architecture are originally from [**OpenClaw Termux**](https://github.com/mithun50/openclaw-termux) by mithun50. This repository is a fork adapted to run the [**Hermes Agent**](https://github.com/nousresearch/hermes-agent) AI gateway instead of OpenClaw.

---

## What is Hermes Agent Mobile?

Hermes Agent Mobile brings the [Hermes Agent](https://github.com/nousresearch/hermes-agent) AI gateway to Android. It sets up a full Ubuntu environment via **proot**, installs **Python 3**, creates a virtual environment, clones the Hermes Agent repository, and provides a native Flutter UI to manage everything — **no root required**.

### Two Ways to Use

| | **Flutter App** (Standalone) | **Termux CLI** |
|---|---|---|
| Install | Build APK or download release | `npm install -g hermes-agent-mobile` |
| Setup | Tap "Begin Setup" | `hermesx setup` |
| Gateway | Tap "Start Gateway" | `hermesx start` |
| Terminal | Built-in terminal emulator | Termux shell |
| Dashboard | Browser at `localhost:18789` | Browser at `localhost:18789` |

---

## Features

### Flutter App
- **One-Tap Setup** — Downloads Ubuntu rootfs, Python 3, and Hermes Agent automatically
- **Built-in Terminal** — Full terminal emulator with extra keys toolbar, copy/paste, clickable URLs
- **Gateway Controls** — Start/stop gateway with status indicator and health checks
- **AI Providers** — Configure API keys and select models via the in-app onboarding terminal
- **Configure Menu** — Run `hermes setup` in a built-in terminal to manage gateway settings
- **View Logs** — Real-time gateway log viewer with search/filter
- **Onboarding** — Configure API keys and binding directly in-app
- **Settings** — Auto-start, battery optimization, system info, re-run setup
- **Foreground Service** — Keeps the gateway alive in the background with uptime tracking
- **Setup Notifications** — Progress bar notifications during environment setup

### Termux CLI
- **One-Command Setup** — Installs proot-distro, Ubuntu, Python 3, and Hermes Agent
- **Smart Loading** — Shows spinner until the gateway is ready
- **Pass-through Commands** — Run any Hermes Agent command via `hermesx`

---

## Important Warnings

> **Storage Permission** — This app does **NOT** need full storage access to function. If prompted, **deny** the storage permission unless you specifically need proot to access `/sdcard`. Granting `MANAGE_EXTERNAL_STORAGE` allows the proot environment to read and modify **all files** on your device including photos, downloads, and documents. Storage access is now opt-in from Settings only.

> **Battery Optimization** — Disable battery optimization for the app in Android Settings to prevent Android from killing the gateway process in the background. Without this, the gateway may crash silently after a few minutes.

> **First Launch** — The initial setup downloads ~300MB (Ubuntu rootfs + Python + dependencies). Ensure you have a stable internet connection and sufficient storage before starting.

---

## Quick Start

### Flutter App (Recommended)

1. Download the latest APK from [Releases](https://github.com/Binair-Dev/HermesAgentMobile/releases)
2. Install the APK on your Android device
3. Open the app and tap **Begin Setup**
4. Configure your API keys in **Onboarding**
5. Tap **Start Gateway** on the dashboard

Or build from source:

```bash
git clone https://github.com/Binair-Dev/HermesAgentMobile.git
cd HermesAgentMobile/flutter_app
flutter build apk --release
```

### Termux CLI

#### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Binair-Dev/HermesAgentMobile/main/install.sh | bash
```

#### Or via npm

```bash
npm install -g hermes-agent-mobile
hermesx setup
```

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **Android** | 10 or higher (API 29) |
| **Storage** | ~300MB for Ubuntu + Python + Hermes Agent |
| **Architectures** | arm64-v8a, armeabi-v7a, x86_64 |
| **Termux** (CLI only) | From [F-Droid](https://f-droid.org/packages/com.termux/) (NOT Play Store) |

---

## CLI Usage

```bash
# First-time setup (installs proot + Ubuntu + Python + Hermes Agent)
hermesx setup

# Check installation status
hermesx status

# Start Hermes Agent gateway
hermesx start

# Run onboarding to configure API keys
hermesx onboarding

# Enter Ubuntu shell
hermesx shell

# Any Hermes Agent command works directly
hermesx doctor
hermesx gateway --verbose
```

---

## Architecture

```
┌───────────────────────────────────────────────────┐
│                Flutter App (Dart)                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐       │
│  │ Terminal │ │ Gateway  │ │    Logs      │       │
│  │ Emulator │ │ Controls │ │   Viewer     │       │
│  └──────────┘ └──────────┘ └──────────────┘       │
└───────────────────────────────────────────────────┘
                        │
            MethodChannel / EventChannel
                        │
┌───────────────────────────────────────────────────┐
│           Android Service (Kotlin)                │
│         GatewayService │ TerminalService          │
└───────────────────────────────────────────────────┘
                        │
                  proot-distro
                        │
┌───────────────────────────────────────────────────┐
│           Ubuntu Rootfs (ARM64/ARM/x86_64)        │
│  ┌─────────┐ ┌─────────────┐ ┌──────────────┐     │
│  │ Python3 │ │   venv      │ │ hermes-agent │     │
│  │  + pip  │ │  (deps)     │ │  (gateway)   │     │
│  └─────────┘ └─────────────┘ └──────────────┘     │
└───────────────────────────────────────────────────┘
```

---

## Project Structure

```
hermes-agent-mobile/
├── flutter_app/          # Flutter application
│   ├── android/          # Android native code (Kotlin)
│   ├── lib/              # Dart source
│   ├── assets/           # Fonts, icons
│   └── pubspec.yaml
├── bin/hermesx           # Termux CLI entrypoint
├── lib/                  # Termux CLI source
├── install.sh            # Termux one-liner installer
├── package.json          # NPM package manifest
└── README.md
```

---

## Development

### Build the Flutter app

```bash
cd flutter_app
flutter pub get
flutter build apk --release
```

### Run the Termux CLI locally

```bash
npm install
npm link
hermesx --help
```

---

## License

MIT © [Brian Van Bellinghen](mailto:van.bellinghen.brian@gmail.com)
