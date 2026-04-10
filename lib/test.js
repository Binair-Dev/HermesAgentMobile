/**
 * Basic tests for Hermes Agent Mobile
 * Tests module loading, exports, and basic functionality
 */

import { strict as assert } from 'node:assert';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { existsSync, readFileSync } from 'node:fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, '..');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (error) {
    console.log(`  ✗ ${name}`);
    console.log(`    ${error.message}`);
    failed++;
  }
}

async function testAsync(name, fn) {
  try {
    await fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (error) {
    console.log(`  ✗ ${name}`);
    console.log(`    ${error.message}`);
    failed++;
  }
}

async function runTests() {
  console.log('\n🧪 Hermes Agent Mobile Tests\n');

  console.log('📁 File Structure:');

  test('bin/hermesx exists', () => {
    assert.ok(existsSync(join(projectRoot, 'bin/hermesx')));
  });

  test('lib/index.js exists', () => {
    assert.ok(existsSync(join(projectRoot, 'lib/index.js')));
  });

  test('lib/installer.js exists', () => {
    assert.ok(existsSync(join(projectRoot, 'lib/installer.js')));
  });

  test('package.json exists', () => {
    assert.ok(existsSync(join(projectRoot, 'package.json')));
  });

  console.log('\n📦 Module Imports:');

  await testAsync('index.js exports main function', async () => {
    const indexModule = await import('./index.js');
    assert.ok(typeof indexModule.main === 'function');
  });

  await testAsync('installer.js exports setup functions', async () => {
    const installerModule = await import('./installer.js');
    assert.ok(typeof installerModule.setupProotUbuntu === 'function');
    assert.ok(typeof installerModule.installProot === 'function');
    assert.ok(typeof installerModule.getInstallStatus === 'function');
  });

  console.log('\n📋 Package Configuration:');

  test('package.json has required fields', () => {
    const pkg = JSON.parse(readFileSync(join(projectRoot, 'package.json'), 'utf8'));
    assert.ok(pkg.name === 'hermes-agent-mobile');
    assert.ok(pkg.version);
    assert.ok(pkg.main);
    assert.ok(pkg.bin);
    assert.ok(pkg.bin.hermesx);
  });

  test('package.json specifies node engine >= 18', () => {
    const pkg = JSON.parse(readFileSync(join(projectRoot, 'package.json'), 'utf8'));
    assert.ok(pkg.engines?.node);
    const minVersion = parseInt(pkg.engines.node.match(/\d+/)[0]);
    assert.ok(minVersion >= 18, 'Node.js version should be >= 18');
  });

  console.log('\n' + '─'.repeat(40));
  console.log(`\n📊 Results: ${passed} passed, ${failed} failed\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
