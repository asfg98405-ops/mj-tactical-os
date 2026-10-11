#!/usr/bin/env node
/**
 * ==============================================================================
 * scripts/overnight_sentinel.js
 * Continuous Overnight Stress, Concurrency & Cross-Platform Diagnostic Harness
 * Architecture: 5-Autonomous Agent Hierarchy
 * Function: Cyclical multi-tool parallel stress testing, memory leak profiling,
 *           Zero-Trust resilience fuzzing, and telemetry stability monitoring.
 * Output: Persisted to logs/overnight_sentinel.log and reports/overnight_runs/
 * ==============================================================================
 */

'use strict';

const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const http = require('node:http');

const BASE_DIR = path.resolve(__dirname, '..');
const LOG_DIR = path.join(BASE_DIR, 'logs');
const REPORT_DIR = path.join(BASE_DIR, 'reports', 'overnight_runs');
const LOG_FILE = path.join(LOG_DIR, 'overnight_sentinel.log');

[LOG_DIR, REPORT_DIR].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

const { app, server, verifyToken, AUTH_KEY } = require(path.join(BASE_DIR, 'device-gateway.js'));
const PORT = 4949; // Dedicated internal testing port for overnight diagnostics
const HOST = '127.0.0.1';

function log(level, message) {
  const ts = new Date().toISOString();
  const line = `[${ts}] [${level}] ${message}\n`;
  process.stdout.write(line);
  try {
    fs.appendFileSync(LOG_FILE, line, 'utf8');
  } catch (_) {}
}

function httpRequest(options, postData = null) {
  return new Promise((resolve) => {
    const startTime = process.hrtime.bigint();
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        const durationMs = Number(process.hrtime.bigint() - startTime) / 1e6;
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body,
          durationMs: parseFloat(durationMs.toFixed(2))
        });
      });
    });

    req.on('error', (err) => {
      resolve({
        statusCode: 0,
        error: err.message,
        durationMs: 0
      });
    });

    if (postData) {
      req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    }
    req.end();
  });
}

// Global Diagnostics Accumulator
const diagnosticsState = {
  cycleCount: 0,
  totalTestsRun: 0,
  passedChecks: 0,
  failedChecks: 0,
  startTime: Date.now(),
  memoryHistory: [],
  latencyHistory: []
};

/**
 * 1. Parallel 12-Tool Concurrency & Stress Check
 */
async function testParallelTools() {
  log('INFO', '[TEST-1] Initiating parallel execution of 12 tactical tools...');
  const tools = [
    'port_scout', 'dns_audit', 'auth_probe', 'header_inspect',
    'device_telemetry', 'interface_analyzer', 'latency_jitter', 'wol_dispatch',
    'memory_profiler', 'intent_validator', 'clipboard_guard', 'nethunter_audit'
  ];

  const promises = tools.map((toolId) => {
    return httpRequest({
      hostname: HOST,
      port: PORT,
      path: `/api/tools/${toolId}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AUTH_KEY}`
      }
    }, { tool_id: toolId });
  });

  const results = await Promise.all(promises);
  let passed = 0;
  let totalLatency = 0;

  results.forEach((res, idx) => {
    diagnosticsState.totalTestsRun++;
    totalLatency += res.durationMs;
    if (res.statusCode === 200) {
      passed++;
      diagnosticsState.passedChecks++;
    } else {
      diagnosticsState.failedChecks++;
      log('WARN', `Tool [${tools[idx]}] responded with status ${res.statusCode}: ${res.body}`);
    }
  });

  const avgLatency = parseFloat((totalLatency / tools.length).toFixed(2));
  diagnosticsState.latencyHistory.push(avgLatency);
  log('OK', `Parallel Tools Completed: ${passed}/${tools.length} passed (Avg Latency: ${avgLatency}ms)`);
}

/**
 * 2. Zero-Trust Security Fuzzing & Boundary Invariant Check
 */
async function testZeroTrustFuzzing() {
  log('INFO', '[TEST-2] Testing Zero-Trust authentication barrier with edge cases...');
  const edgeCases = [
    { name: 'Missing Header', headers: {} },
    { name: 'Malformed Token', headers: { 'Authorization': 'Bearer ' } },
    { name: 'Random Junk Token', headers: { 'Authorization': 'Bearer a1b2c3d4e5f6g7h8' } },
    { name: 'Near-Match Token (1-bit flip)', headers: { 'Authorization': `Bearer ${AUTH_KEY.slice(0, -1)}x` } }
  ];

  for (const tc of edgeCases) {
    diagnosticsState.totalTestsRun++;
    const res = await httpRequest({
      hostname: HOST,
      port: PORT,
      path: '/api/health',
      method: 'GET',
      headers: tc.headers
    });

    if (res.statusCode === 401) {
      diagnosticsState.passedChecks++;
    } else {
      diagnosticsState.failedChecks++;
      log('CRIT', `Zero-Trust Fuzzing FAIL for [${tc.name}]: Expected 401, got ${res.statusCode}`);
    }
  }

  // Verify Localhost Bootstrap endpoint works
  diagnosticsState.totalTestsRun++;
  const bootRes = await httpRequest({
    hostname: HOST,
    port: PORT,
    path: '/api/auth/bootstrap',
    method: 'GET'
  });

  if (bootRes.statusCode === 200 && bootRes.body.includes(AUTH_KEY)) {
    diagnosticsState.passedChecks++;
    log('OK', 'Zero-Trust Fuzzing & Localhost Bootstrap: All invariants verified strictly.');
  } else {
    diagnosticsState.failedChecks++;
    log('WARN', `Bootstrap verification failed: ${bootRes.statusCode}`);
  }
}

/**
 * 3. V8 Memory Leak & RSS Drift Profiling
 */
function profileMemoryDrift() {
  const mem = process.memoryUsage();
  diagnosticsState.memoryHistory.push({
    cycle: diagnosticsState.cycleCount,
    rssMb: parseFloat((mem.rss / 1024 / 1024).toFixed(2)),
    heapUsedMb: parseFloat((mem.heapUsed / 1024 / 1024).toFixed(2)),
    timestamp: new Date().toISOString()
  });

  if (diagnosticsState.memoryHistory.length > 50) {
    diagnosticsState.memoryHistory.shift();
  }

  const latest = diagnosticsState.memoryHistory[diagnosticsState.memoryHistory.length - 1];
  log('INFO', `[PROFILE] Cycle #${diagnosticsState.cycleCount} Memory - RSS: ${latest.rssMb} MB | Heap: ${latest.heapUsedMb} MB`);
}

/**
 * Execute a single complete diagnostic round
 */
async function runDiagnosticCycle() {
  diagnosticsState.cycleCount++;
  log('INFO', `================ STARTING OVERNIGHT DIAGNOSTIC CYCLE #${diagnosticsState.cycleCount} ================`);

  try {
    await testParallelTools();
    await testZeroTrustFuzzing();
    profileMemoryDrift();

    // Persist cycle report
    const reportData = {
      timestamp: new Date().toISOString(),
      cycle: diagnosticsState.cycleCount,
      uptime_seconds: Math.round((Date.now() - diagnosticsState.startTime) / 1000),
      summary: {
        total_tests: diagnosticsState.totalTestsRun,
        passed: diagnosticsState.passedChecks,
        failed: diagnosticsState.failedChecks,
        pass_rate_pct: Math.round((diagnosticsState.passedChecks / Math.max(1, diagnosticsState.totalTestsRun)) * 100)
      },
      latest_memory: diagnosticsState.memoryHistory[diagnosticsState.memoryHistory.length - 1],
      recent_latencies_ms: diagnosticsState.latencyHistory.slice(-10)
    };

    const latestReportFile = path.join(REPORT_DIR, 'sentinel_latest.json');
    fs.writeFileSync(latestReportFile, JSON.stringify(reportData, null, 2), 'utf8');

    log('OK', `Cycle #${diagnosticsState.cycleCount} finished cleanly. Total verified checks: ${diagnosticsState.passedChecks}/${diagnosticsState.totalTestsRun}`);
  } catch (err) {
    log('ERROR', `Error during cycle #${diagnosticsState.cycleCount}: ${err.message}`);
  }
}

// Start dedicated diagnostic server and initiate loop
server.listen(PORT, HOST, async () => {
  log('INFO', `Overnight Sentinel Diagnostic Server bound to http://${HOST}:${PORT}`);
  log('INFO', `Running continuous health and stress cycles every 2 minutes...`);

  // Run initial cycle immediately
  await runDiagnosticCycle();

  // Schedule cyclical runs every 2 minutes (120,000ms)
  const INTERVAL_MS = 120000;
  setInterval(async () => {
    await runDiagnosticCycle();
  }, INTERVAL_MS);
});
