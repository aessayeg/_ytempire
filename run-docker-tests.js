#!/usr/bin/env node

/**
 * Docker Test Runner
 * YTEmpire Project
 * 
 * This script orchestrates the complete Docker Compose testing process
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const path = require('path');
const execAsync = promisify(exec);

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function checkPrerequisites() {
  log('\n🔍 Checking prerequisites...', 'cyan');
  
  // Check Docker
  try {
    await execAsync('docker --version');
    log('✓ Docker is installed', 'green');
  } catch (error) {
    log('✗ Docker is not installed or not in PATH', 'red');
    return false;
  }
  
  // Check Docker Compose
  try {
    await execAsync('docker-compose --version');
    log('✓ Docker Compose is installed', 'green');
  } catch (error) {
    log('✗ Docker Compose is not installed or not in PATH', 'red');
    return false;
  }
  
  // Check if Docker daemon is running
  try {
    await execAsync('docker info');
    log('✓ Docker daemon is running', 'green');
  } catch (error) {
    log('✗ Docker daemon is not running. Please start Docker Desktop.', 'red');
    return false;
  }
  
  // Check if required files exist
  const requiredFiles = [
    'docker-compose.yml',
    'frontend/Dockerfile.dev',
    'backend/Dockerfile.dev',
    'jest.docker.config.js'
  ];
  
  for (const file of requiredFiles) {
    try {
      await fs.access(path.join(process.cwd(), file));
      log(`✓ ${file} exists`, 'green');
    } catch (error) {
      log(`✗ ${file} is missing`, 'red');
      return false;
    }
  }
  
  return true;
}

async function cleanupEnvironment() {
  log('\n🧹 Cleaning up environment...', 'cyan');
  
  try {
    await execAsync('docker-compose down -v --remove-orphans');
    log('✓ Cleaned up existing containers and volumes', 'green');
  } catch (error) {
    log('⚠ Warning: Cleanup encountered issues', 'yellow');
  }
}

async function startServices() {
  log('\n🚀 Starting Docker Compose services...', 'cyan');
  
  try {
    await execAsync('docker-compose up -d --build');
    log('✓ Services started successfully', 'green');
    
    // Wait for services to be ready
    log('⏳ Waiting for services to be ready (30 seconds)...', 'yellow');
    await new Promise(resolve => setTimeout(resolve, 30000));
    
    // Check service status
    const { stdout } = await execAsync('docker-compose ps');
    log('\nService Status:', 'bright');
    console.log(stdout);
    
    return true;
  } catch (error) {
    log('✗ Failed to start services', 'red');
    console.error(error.message);
    return false;
  }
}

async function runTests() {
  log('\n🧪 Running Docker tests...', 'cyan');
  
  const testSuites = [
    { name: 'Docker Compose Configuration', command: 'npm run test:docker:compose' },
    { name: 'Service Connectivity', command: 'npm run test:docker:services' },
    { name: 'Integration Tests', command: 'npm run test:docker:integration' }
  ];
  
  const results = {
    passed: 0,
    failed: 0,
    total: testSuites.length
  };
  
  for (const suite of testSuites) {
    log(`\n📋 Running ${suite.name}...`, 'blue');
    
    try {
      const { stdout, stderr } = await execAsync(suite.command);
      console.log(stdout);
      if (stderr) console.error(stderr);
      
      log(`✓ ${suite.name} passed`, 'green');
      results.passed++;
    } catch (error) {
      log(`✗ ${suite.name} failed`, 'red');
      console.error(error.stdout || error.message);
      results.failed++;
    }
  }
  
  return results;
}

async function generateReport(results) {
  log('\n📊 Test Report', 'cyan');
  log('═'.repeat(50), 'bright');
  
  log(`Total Test Suites: ${results.total}`, 'bright');
  log(`Passed: ${results.passed}`, results.passed > 0 ? 'green' : 'red');
  log(`Failed: ${results.failed}`, results.failed > 0 ? 'red' : 'green');
  
  const successRate = (results.passed / results.total * 100).toFixed(1);
  log(`Success Rate: ${successRate}%`, successRate >= 80 ? 'green' : 'red');
  
  // Generate detailed report file
  const report = {
    timestamp: new Date().toISOString(),
    results: results,
    environment: {
      node: process.version,
      platform: process.platform,
      arch: process.arch
    }
  };
  
  await fs.writeFile(
    'docker-test-report.json',
    JSON.stringify(report, null, 2)
  );
  
  log('\n✓ Detailed report saved to docker-test-report.json', 'green');
}

async function showLogs() {
  log('\n📝 Container Logs (last 20 lines each):', 'cyan');
  
  const containers = [
    'ytempire-backend',
    'ytempire-frontend',
    'ytempire-postgresql',
    'ytempire-redis'
  ];
  
  for (const container of containers) {
    try {
      log(`\n${container}:`, 'yellow');
      const { stdout } = await execAsync(`docker logs ${container} --tail 20`);
      console.log(stdout);
    } catch (error) {
      log(`Could not get logs for ${container}`, 'red');
    }
  }
}

async function main() {
  log('\n🏁 YTEmpire Docker Test Runner', 'bright');
  log('═'.repeat(50), 'bright');
  
  // Check prerequisites
  const prereqCheck = await checkPrerequisites();
  if (!prereqCheck) {
    log('\n❌ Prerequisites check failed. Please fix the issues above.', 'red');
    process.exit(1);
  }
  
  // Cleanup environment
  await cleanupEnvironment();
  
  // Start services
  const servicesStarted = await startServices();
  if (!servicesStarted) {
    log('\n❌ Failed to start services. Check Docker logs for details.', 'red');
    process.exit(1);
  }
  
  // Run tests
  const results = await runTests();
  
  // Generate report
  await generateReport(results);
  
  // Show logs if there were failures
  if (results.failed > 0) {
    await showLogs();
  }
  
  // Final summary
  if (results.failed === 0) {
    log('\n✅ All tests passed! Docker Compose setup is working correctly.', 'green');
    log('\nYou can now run:', 'cyan');
    log('  docker-compose up     # Start all services', 'bright');
    log('  docker-compose logs   # View logs', 'bright');
    log('  docker-compose down   # Stop services', 'bright');
  } else {
    log('\n❌ Some tests failed. Please check the logs above.', 'red');
    process.exit(1);
  }
}

// Run the script
main().catch(error => {
  log('\n❌ Unexpected error:', 'red');
  console.error(error);
  process.exit(1);
});