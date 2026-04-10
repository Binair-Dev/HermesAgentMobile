/**
 * Hermes Agent Mobile — Main entry point
 */

import {
  configureTermux,
  getInstallStatus,
  installProot,
  installUbuntu,
  setupProotUbuntu,
  runInProot
} from './installer.js';
import { spawn } from 'child_process';

const VERSION = '0.1.0';

function printBanner() {
  console.log(`
╔═══════════════════════════════════════════╗
║     Hermes Agent Mobile v${VERSION}           ║
║     AI Agent for Android                  ║
╚═══════════════════════════════════════════╝
`);
}

function printHelp() {
  console.log(`
Usage: hermesx <command> [args...]

Commands:
  setup       Full installation (proot + Ubuntu + Python + Hermes Agent)
  status      Check installation status
  start       Start Hermes Agent gateway (inside proot)
  configure   Run Hermes interactive setup wizard
  shell       Open Ubuntu shell with Hermes ready
  logs        Tail Hermes gateway logs
  help        Show this help message

Examples:
  hermesx setup             # First-time setup
  hermesx start             # Start Hermes gateway
  hermesx configure         # Configure API keys
  hermesx shell             # Enter Ubuntu shell
`);
}

async function runSetup() {
  console.log('Starting Hermes Agent setup for Termux...\n');
  console.log('This will install: proot-distro → Ubuntu → Python → Hermes Agent\n');

  let status = getInstallStatus();

  // Step 1: Install proot-distro
  console.log('[1/5] Checking proot-distro...');
  if (!status.proot) {
    console.log('  Installing proot-distro...');
    installProot();
  } else {
    console.log('  ✓ proot-distro installed');
  }
  console.log('');

  // Step 2: Install Ubuntu
  console.log('[2/5] Checking Ubuntu in proot...');
  status = getInstallStatus();
  if (!status.ubuntu) {
    console.log('  Installing Ubuntu (this takes a while)...');
    installUbuntu();
  } else {
    console.log('  ✓ Ubuntu installed');
  }
  console.log('');

  // Step 3: Setup Python and Hermes Agent in Ubuntu
  console.log('[3/5] Setting up Python and Hermes Agent in Ubuntu...');
  status = getInstallStatus();
  if (!status.hermesInProot) {
    setupProotUbuntu();
  } else {
    console.log('  ✓ Hermes Agent already installed in proot');
  }
  console.log('');

  // Step 4: Configure Termux wake-lock
  console.log('[4/4] Configuring Termux...');
  configureTermux();
  console.log('');

  // Done
  console.log('═══════════════════════════════════════════');
  console.log('Setup complete!');
  console.log('');
  console.log('Next steps:');
  console.log('  1. Run configuration: hermesx configure');
  console.log('  2. Start agent:       hermesx start');
  console.log('');
  console.log('═══════════════════════════════════════════');
}

function showStatus() {
  process.stdout.write('Checking installation status...');
  const status = getInstallStatus();
  process.stdout.write('\r' + ' '.repeat(35) + '\r');

  console.log('Installation Status:\n');

  console.log('Termux:');
  console.log(`  proot-distro:     ${status.proot ? '✓ installed' : '✗ missing'}`);
  console.log(`  Ubuntu (proot):   ${status.ubuntu ? '✓ installed' : '✗ not installed'}`);
  console.log('');

  if (status.ubuntu) {
    console.log('Inside Ubuntu:');
    console.log(`  Hermes Agent:     ${status.hermesInProot ? '✓ installed' : '✗ not installed'}`);
    console.log('');
  }

  if (status.proot && status.ubuntu && status.hermesInProot) {
    console.log('Status: ✓ Ready to run!');
    console.log('');
    console.log('Commands:');
    console.log('  hermesx start       # Start Hermes gateway');
    console.log('  hermesx configure   # Configure API keys');
    console.log('  hermesx shell       # Enter Ubuntu shell');
  } else {
    console.log('Status: ✗ Setup incomplete');
    console.log('Run: hermesx setup');
  }
}

function startGateway() {
  const status = getInstallStatus();

  if (!status.proot || !status.ubuntu) {
    console.error('proot/Ubuntu not installed. Run: hermesx setup');
    process.exit(1);
  }

  if (!status.hermesInProot) {
    console.error('Hermes Agent not installed in proot. Run: hermesx setup');
    process.exit(1);
  }

  console.log('Starting Hermes Agent gateway...\n');

  const gateway = runInProot('cd /root/hermes-agent && source venv/bin/activate && python gateway/run.py');

  gateway.on('error', (err) => {
    console.error('\nFailed to start gateway:', err.message);
  });

  gateway.on('close', (code) => {
    console.log(`\nGateway exited with code ${code}`);
  });
}

function runConfigure() {
  const status = getInstallStatus();

  if (!status.proot || !status.ubuntu || !status.hermesInProot) {
    console.error('Setup not complete. Run: hermesx setup');
    process.exit(1);
  }

  console.log('Running Hermes setup wizard...\n');

  const proc = runInProot('cd /root/hermes-agent && source venv/bin/activate && python -m hermes_cli.main setup');

  proc.on('error', (err) => {
    console.error('Failed to run configure:', err.message);
  });
}

function runLogs() {
  const status = getInstallStatus();

  if (!status.proot || !status.ubuntu || !status.hermesInProot) {
    console.error('Setup not complete. Run: hermesx setup');
    process.exit(1);
  }

  console.log('Tailing Hermes logs...\n');

  const proc = runInProot('cd /root/hermes-agent && source venv/bin/activate && tail -f agent.log errors.log 2>/dev/null || journalctl -f -u hermes');

  proc.on('error', (err) => {
    console.error('Failed to tail logs:', err.message);
  });
}

function openShell() {
  const status = getInstallStatus();

  if (!status.proot || !status.ubuntu) {
    console.error('proot/Ubuntu not installed. Run: hermesx setup');
    process.exit(1);
  }

  console.log('Entering Ubuntu shell (Hermes Agent ready)...');
  console.log('Type "exit" to return to Termux\n');

  const shell = spawn('proot-distro', ['login', 'ubuntu'], {
    stdio: 'inherit'
  });

  shell.on('error', (err) => {
    console.error('Failed to open shell:', err.message);
  });
}

export async function main(args) {
  const command = args[0] || 'help';

  printBanner();

  switch (command) {
    case 'setup':
    case 'install':
      await runSetup();
      break;

    case 'status':
      showStatus();
      break;

    case 'start':
    case 'run':
      startGateway();
      break;

    case 'configure':
    case 'config':
      runConfigure();
      break;

    case 'logs':
      runLogs();
      break;

    case 'shell':
    case 'ubuntu':
      openShell();
      break;

    case 'help':
    case '--help':
    case '-h':
      printHelp();
      break;

    default:
      console.log(`Unknown command: ${command}`);
      printHelp();
      process.exit(1);
  }
}
