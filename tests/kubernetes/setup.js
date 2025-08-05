/**
 * Kubernetes Test Setup
 * YTEmpire Project
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

// Increase Jest timeout for Kubernetes tests
jest.setTimeout(120000);

// Global setup
beforeAll(async () => {
  console.log('Setting up Kubernetes tests...');

  // Check if kubectl is available
  try {
    await execAsync('kubectl version --client');
  } catch (error) {
    throw new Error('kubectl is not installed or not in PATH');
  }

  // Check if cluster is accessible
  try {
    await execAsync('kubectl cluster-info');
    console.log('Kubernetes cluster is accessible');
  } catch (error) {
    throw new Error(
      'Kubernetes cluster is not accessible. Please ensure kind/minikube is running.'
    );
  }

  // Check if ytempire-dev namespace exists
  try {
    await execAsync('kubectl get namespace ytempire-dev');
    console.log('YTEmpire namespace exists');
  } catch (error) {
    console.log('YTEmpire namespace not found. Please deploy the application first.');
  }
});

// Global teardown
afterAll(async () => {
  console.log('Kubernetes tests completed.');

  // Optional: Clean up test resources
  try {
    await execAsync('kubectl delete pod -n ytempire-dev -l test=true --ignore-not-found=true');
  } catch (error) {
    // Ignore cleanup errors
  }
});

// Helper to suppress console errors during tests
const originalError = console.error;
beforeEach(() => {
  console.error = jest.fn();
});

afterEach(() => {
  console.error = originalError;
});
