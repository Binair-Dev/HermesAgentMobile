/**
 * Hermes Agent Mobile Installer - Handles environment setup for Termux
 */

import { execSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';

const HOME = process.env.HOME || '/data/data/com.termux/files/home';
const PROOT_ROOTFS = '/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs';
const PROOT_UBUNTU_ROOT = path.join(PROOT_ROOTFS, 'ubuntu', 'root');
const HERMES_REPO_URL = 'https://github.com/nousresearch/hermes-agent.git';

export function checkDependencies() {
  const deps = {
    node: false,
    npm: false,
    git: false,
    proot: false
  };

  try {
    execSync('node --version', { stdio: 'pipe' });
    deps.node = true;
  } catch { /* not installed */ }

  try {
    execSync('npm --version', { stdio: 'pipe' });
    deps.npm = true;
  } catch { /* not installed */ }

  try {
    execSync('git --version', { stdio: 'pipe' });
    deps.git = true;
  } catch { /* not installed */ }

  try {
    execSync('which proot-distro', { stdio: 'pipe' });
    deps.proot = true;
  } catch { /* not installed */ }

  return deps;
}

export function installTermuxDeps() {
  console.log('Installing Termux dependencies...');

  const packages = ['nodejs-lts', 'git', 'openssh'];

  try {
    execSync('pkg update -y', { stdio: 'inherit' });
    execSync(`pkg install -y ${packages.join(' ')}`, { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to install Termux packages:', err.message);
    return false;
  }
}

export function configureTermux() {
  console.log('Configuring Termux for background operation...');

  const wakeLockScript = path.join(HOME, '.hermes-mobile', 'wakelock.sh');
  const wakeLockContent = `#!/bin/bash
# Keep Termux awake while Hermes Agent runs
termux-wake-lock
trap "termux-wake-unlock" EXIT
exec "$@"
`;

  fs.writeFileSync(wakeLockScript, wakeLockContent, 'utf8');
  fs.chmodSync(wakeLockScript, '755');

  console.log('Wake-lock script created');
  console.log('');
  console.log('IMPORTANT: Disable battery optimization for Termux in Android settings!');

  return true;
}

export function getInstallStatus() {
  const PROOT_ROOTFS = '/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs';

  let hasProot = false;
  try {
    execSync('command -v proot-distro', { stdio: 'pipe' });
    hasProot = true;
  } catch { /* not installed */ }

  let hasUbuntu = false;
  try {
    hasUbuntu = fs.existsSync(path.join(PROOT_ROOTFS, 'ubuntu'));
  } catch { /* check failed */ }

  let hasHermesInProot = false;
  if (hasUbuntu) {
    try {
      const hermesPath = path.join(PROOT_ROOTFS, 'ubuntu', 'root', 'hermes-agent', 'gateway', 'run.py');
      const hasPython = fs.existsSync(path.join(PROOT_ROOTFS, 'ubuntu', 'usr', 'bin', 'python3'));
      hasHermesInProot = fs.existsSync(hermesPath) && hasPython;
    } catch { /* check failed */ }

    if (!hasHermesInProot) {
      try {
        execSync('proot-distro login ubuntu -- bash -lc "test -d /root/hermes-agent"', { stdio: 'pipe', timeout: 30000 });
        hasHermesInProot = true;
      } catch { /* not installed */ }
    }
  }

  return {
    proot: hasProot,
    ubuntu: hasUbuntu,
    hermesInProot: hasHermesInProot
  };
}

export function installProot() {
  console.log('Installing proot-distro...');
  try {
    execSync('pkg install -y proot-distro', { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to install proot-distro:', err.message);
    return false;
  }
}

export function installUbuntu() {
  console.log('Installing Ubuntu in proot (this may take a while)...');
  try {
    execSync('proot-distro install ubuntu', { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to install Ubuntu:', err.message);
    return false;
  }
}

export function setupProotUbuntu() {
  console.log('Setting up Python and Hermes Agent in Ubuntu...');

  const setupScript = `
    apt update && apt upgrade -y
    apt install -y curl wget git python3 python3-venv python3-pip
    cd /root
    if [ ! -d hermes-agent ]; then
      git clone ${HERMES_REPO_URL} hermes-agent
    fi
    cd hermes-agent
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
  `;

  try {
    execSync(`proot-distro login ubuntu -- bash -c '${setupScript}'`, { stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error('Failed to setup Ubuntu:', err.message);
    return false;
  }
}

export function runInProot(command) {
  return spawn('proot-distro', ['login', 'ubuntu', '--', 'bash', '-c', command], {
    stdio: 'inherit'
  });
}

export function runInProotWithCallback(command, onFirstOutput) {
  let firstOutput = true;

  const proc = spawn('proot-distro', ['login', 'ubuntu', '--', 'bash', '-c', command], {
    stdio: ['inherit', 'pipe', 'pipe']
  });

  proc.stdout.on('data', (data) => {
    if (firstOutput) {
      firstOutput = false;
      onFirstOutput();
    }
    process.stdout.write(data);
  });

  proc.stderr.on('data', (data) => {
    if (firstOutput) {
      firstOutput = false;
      onFirstOutput();
    }
    const str = data.toString();
    if (!str.includes('proot warning') && !str.includes("can't sanitize")) {
      process.stderr.write(data);
    }
  });

  return proc;
}
