/**
 * ==============================================================================
 * app.js - MJ Tactical OS Cockpit Controller
 * Multi-Agent Interface, Telemetry Engine & 12-Tool Suite Orchestrator
 * ==============================================================================
 */

'use strict';

const APP_STATE = {
  token: localStorage.getItem('mj_tactical_token') || '',
  ws: null,
  wsConnected: false,
  pollTimer: null,
  scanIntervalSec: 5,
  scanMode: 'PASSIVE_AUDIT',
  gatewayArmed: true,
  firewallIsolated: false,
  gauges: {},
  tools: [],
  latestReport: null
};

// --- Initialization ---
document.addEventListener('DOMContentLoaded', () => {
  initToken();
  initNavigation();
  initGauges();
  initControls();
  initToolSuite();
  initReporting();
  registerPWA();

  // Initial Data Fetch & WebSocket Connect
  connectWebSocket();
  fetchInitialData();
  startPolling();
});

// 1. Token & Authentication Management
function initToken() {
  const urlParams = new URLSearchParams(window.location.search);
  const queryToken = urlParams.get('token');
  if (queryToken) {
    APP_STATE.token = queryToken.trim();
    localStorage.setItem('mj_tactical_token', APP_STATE.token);
  }

  updateAuthUI();

  document.getElementById('btn-save-token')?.addEventListener('click', () => {
    const inputVal = document.getElementById('token-input')?.value.trim();
    if (inputVal) {
      APP_STATE.token = inputVal;
      localStorage.setItem('mj_tactical_token', inputVal);
      updateAuthUI();
      closeModal('token-modal');
      connectWebSocket();
      fetchInitialData();
    }
  });

  document.getElementById('btn-open-auth-modal')?.addEventListener('click', () => {
    const input = document.getElementById('token-input');
    if (input) input.value = APP_STATE.token;
    openModal('token-modal');
  });

  document.getElementById('btn-close-token-modal')?.addEventListener('click', () => {
    closeModal('token-modal');
  });
}

function updateAuthUI() {
  const authPill = document.getElementById('auth-status-pill');
  if (authPill) {
    if (APP_STATE.token && APP_STATE.token.length >= 8) {
      authPill.innerHTML = `<span class="dot" style="background:#10b981;"></span> AUTH: ARMED`;
      authPill.className = 'status-pill online';
    } else {
      authPill.innerHTML = `<span class="dot" style="background:#f59e0b;"></span> AUTH: REQUIRED`;
      authPill.className = 'status-pill';
    }
  }
}

function getAuthHeaders() {
  const headers = { 'Content-Type': 'application/json' };
  if (APP_STATE.token) {
    headers['Authorization'] = `Bearer ${APP_STATE.token}`;
  }
  return headers;
}

// 2. Navigation Tabs
function initNavigation() {
  const tabButtons = document.querySelectorAll('.nav-tab-btn');
  tabButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      tabButtons.forEach((b) => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach((tc) => tc.classList.remove('active'));

      btn.classList.add('active');
      const targetId = btn.getAttribute('data-tab');
      const targetEl = document.getElementById(targetId);
      if (targetEl) targetEl.classList.add('active');
    });
  });
}

// 3. Radial Gauges Initialization
function initGauges() {
  APP_STATE.gauges.cpu = new TacticalGauge('gauge-cpu', {
    min: 0,
    max: 100,
    unit: '%',
    title: '⚡ كفاءة المعالج (CPU Load)',
    subtitle: 'System Load Avg'
  });

  APP_STATE.gauges.ram = new TacticalGauge('gauge-ram', {
    min: 0,
    max: 100,
    unit: '%',
    title: '💾 استهلاك الذاكرة (RAM)',
    subtitle: 'RSS Allocations'
  });

  APP_STATE.gauges.battery = new TacticalGauge('gauge-battery', {
    min: 0,
    max: 100,
    unit: '%',
    title: '🔋 بطارية العقدة (Battery)',
    subtitle: 'Charging Active',
    colorType: 'battery'
  });

  APP_STATE.gauges.thermal = new TacticalGauge('gauge-thermal', {
    min: 20,
    max: 80,
    unit: '°C',
    title: '🔥 حرارة الريد ماجيك (SoC)',
    subtitle: 'Internal Sensor',
    colorType: 'dynamic-temp'
  });
}

// 4. Control Deck (Sliders & Switches)
function initControls() {
  // Telemetry Interval Slider
  const slider = document.getElementById('scan-freq-slider');
  const sliderVal = document.getElementById('scan-freq-val');

  if (slider && sliderVal) {
    slider.addEventListener('input', (e) => {
      const val = e.target.value;
      sliderVal.textContent = `${val}s`;
      APP_STATE.scanIntervalSec = parseInt(val, 10);
    });

    slider.addEventListener('change', async (e) => {
      const val = parseInt(e.target.value, 10);
      try {
        await fetch('/api/control/mode', {
          method: 'POST',
          headers: getAuthHeaders(),
          body: JSON.stringify({ interval_sec: val })
        });
        resetPolling();
      } catch (_) {}
    });
  }

  // Scan Mode Selector
  const modeSelect = document.getElementById('scan-mode-select');
  if (modeSelect) {
    modeSelect.addEventListener('change', async (e) => {
      const newMode = e.target.value;
      APP_STATE.scanMode = newMode;
      document.getElementById('mode-status-text').textContent = newMode;
      try {
        await fetch('/api/control/mode', {
          method: 'POST',
          headers: getAuthHeaders(),
          body: JSON.stringify({ mode: newMode })
        });
      } catch (_) {}
    });
  }

  // Gateway Arming Switch
  const armSwitch = document.getElementById('gateway-arm-switch');
  if (armSwitch) {
    armSwitch.addEventListener('change', async (e) => {
      const isArmed = e.target.checked;
      APP_STATE.gatewayArmed = isArmed;
      const statusText = isArmed ? 'ARMED' : 'STANDBY';
      document.getElementById('gateway-status-badge').textContent = statusText;
      try {
        await fetch('/api/control/mode', {
          method: 'POST',
          headers: getAuthHeaders(),
          body: JSON.stringify({ status: statusText })
        });
      } catch (_) {}
    });
  }

  // Loopback Isolation Switch
  const firewallSwitch = document.getElementById('firewall-switch');
  if (firewallSwitch) {
    firewallSwitch.addEventListener('change', async (e) => {
      const isolate = e.target.checked;
      APP_STATE.firewallIsolated = isolate;
      try {
        await fetch('/api/control/firewall', {
          method: 'POST',
          headers: getAuthHeaders(),
          body: JSON.stringify({ loopback_isolated: isolate })
        });
      } catch (_) {}
    });
  }

  // Quick Action: NetHunter Full Audit Button
  document.getElementById('btn-run-full-audit')?.addEventListener('click', () => {
    runTool('nethunter_audit');
  });

  // Quick Action: Ping / Socket Test
  document.getElementById('btn-quick-ping')?.addEventListener('click', () => {
    runTool('port_scout');
  });
}

// 5. 12-Tool Suite Execution Engine
const DEFAULT_TOOLS = [
  { id: 'port_scout', name: 'Port Scout & Socket Handshake', name_ar: 'كاشف المنافذ والاتصال', cat: 'NETWORK', desc: 'Checks TCP port accessibility and handshake latency in ms.' },
  { id: 'dns_audit', name: 'DNS Resolver Benchmark', name_ar: 'تدقيق واختبار محلل DNS', cat: 'NETWORK', desc: 'Measures resolution response times across system nameservers.' },
  { id: 'auth_probe', name: 'Zero-Trust Auth & Ingress Probe', name_ar: 'فحص مناعة الدخول والأمان', cat: 'SECURITY', desc: 'Verifies constant-time token comparison and unauthenticated ingress rejection.' },
  { id: 'header_inspect', name: 'Security Headers Auditor', name_ar: 'فحص ترويسات الأمان HTTP', cat: 'SECURITY', desc: 'Inspects CSP, nosniff, and anti-clickjacking framing protections.' },
  { id: 'device_telemetry', name: 'RedMagic Hardware & Thermal Prober', name_ar: 'حساسات هاتف RedMagic', cat: 'TELEMETRY', desc: 'Reads SoC temperature sensors, battery %, and charging state.' },
  { id: 'interface_analyzer', name: 'Network Interface & CIDR Analyzer', name_ar: 'محلل واجهات الشبكة وكتل العناوين', cat: 'NETWORK', desc: 'Extracts routing tables, subnet masks, loopback isolation, and interface states.' },
  { id: 'latency_jitter', name: 'Packet Latency & Jitter Monitor', name_ar: 'مراقب سرعة الاستجابة والتذبذب', cat: 'NETWORK', desc: 'Calculates round-trip microsecond timings and jitter variances.' },
  { id: 'wol_dispatch', name: 'Wake-on-LAN Magic Packet Dispatcher', name_ar: 'مرسل حزم الإيقاظ الشبكي WoL', cat: 'NETWORK', desc: 'Constructs and transmits RFC compliant UDP magic packets for remote lab nodes.' },
  { id: 'memory_profiler', name: 'V8 Memory Heap & RSS Profiler', name_ar: 'مدقق استهلاك الرام وذاكرة V8', cat: 'SYSTEM', desc: 'Monitors RSS footprint, heap allocation, and flags potential memory leaks.' },
  { id: 'intent_validator', name: 'Android Intent Whitelist Validator', name_ar: 'مدقق القائمة البيضاء لأوامر أندرويد', cat: 'SECURITY', desc: 'Validates system intent dispatch requests against locked security rules.' },
  { id: 'clipboard_guard', name: 'Clipboard Buffer Guard & Inspector', name_ar: 'حارس ومراقب حافظة النظام', cat: 'SECURITY', desc: 'Safely inspects clipboard activity with zero persistent memory leakage.' },
  { id: 'nethunter_audit', name: 'NetHunter Core Health & CVE Posture', name_ar: 'فحص النواة والأمان الشامل لـ NetHunter', cat: 'SECURITY', desc: 'Runs full Kali NetHunter rootless platform audit script and generates report.' }
];

function initToolSuite() {
  const container = document.getElementById('tools-container');
  if (!container) return;

  container.innerHTML = '';
  DEFAULT_TOOLS.forEach((tool) => {
    const card = document.createElement('div');
    card.className = 'tool-card';
    card.id = `card-${tool.id}`;
    card.innerHTML = `
      <div>
        <div class="tool-header">
          <span class="tool-category-badge category-${tool.cat}">${tool.cat}</span>
          <span class="tool-status-state" id="status-${tool.id}">READY</span>
        </div>
        <div class="tool-title">${tool.name}</div>
        <div class="tool-title-ar">${tool.name_ar}</div>
        <div class="tool-desc">${tool.desc}</div>
      </div>
      <div class="tool-footer">
        <span style="font-size:0.7rem; color:var(--text-muted); font-family:var(--font-mono);">${tool.id}</span>
        <button class="btn-run-tool" data-tool="${tool.id}">
          ▶ تشغيل الفحص
        </button>
      </div>
    `;

    card.querySelector('.btn-run-tool').addEventListener('click', () => {
      runTool(tool.id);
    });

    container.appendChild(card);
  });

  // Console Actions (Copy, Download)
  document.getElementById('btn-copy-json')?.addEventListener('click', () => {
    const text = document.getElementById('json-output')?.textContent;
    if (text) {
      navigator.clipboard.writeText(text);
      alert('تم نسخ مخرجات JSON إلى الحافظة.');
    }
  });

  document.getElementById('btn-download-json')?.addEventListener('click', () => {
    const text = document.getElementById('json-output')?.textContent;
    if (text) {
      downloadFile('tool_result.json', text, 'application/json');
    }
  });
}

async function runTool(toolId) {
  const statusEl = document.getElementById(`status-${toolId}`);
  if (statusEl) {
    statusEl.textContent = 'RUNNING...';
    statusEl.style.color = 'var(--cyan-neon)';
  }

  try {
    const res = await fetch(`/api/tools/${toolId}`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({ tool_id: toolId })
    });

    const data = await res.json();
    if (statusEl) {
      statusEl.textContent = data.status === 'OK' ? 'PASS' : 'WARN';
      statusEl.style.color = data.status === 'OK' ? 'var(--emerald)' : 'var(--amber)';
    }

    displayConsoleOutput(toolId, data);
  } catch (err) {
    if (statusEl) {
      statusEl.textContent = 'ERROR';
      statusEl.style.color = 'var(--crimson)';
    }
    displayConsoleOutput(toolId, { error: err.message });
  }
}

function displayConsoleOutput(toolId, data) {
  const consoleTitle = document.getElementById('console-active-tool');
  const jsonBox = document.getElementById('json-output');

  if (consoleTitle) {
    consoleTitle.textContent = `مخرجات الأداة: ${toolId} [${new Date().toLocaleTimeString()}]`;
  }
  if (jsonBox) {
    jsonBox.textContent = JSON.stringify(data, null, 2);
  }
}

// 6. Reports & Forensics
function initReporting() {
  document.getElementById('btn-generate-report')?.addEventListener('click', async () => {
    try {
      const res = await fetch('/api/reports/generate', {
        method: 'POST',
        headers: getAuthHeaders()
      });
      const data = await res.json();
      APP_STATE.latestReport = data.report;

      displayConsoleOutput('FORENSIC_REPORT', data);
      alert(`تم توليد التقرير بنجاح: ${data.report_id}`);
    } catch (e) {
      alert(`فشل توليد التقرير: ${e.message}`);
    }
  });

  document.getElementById('btn-export-report-json')?.addEventListener('click', () => {
    if (!APP_STATE.latestReport) {
      alert('يرجى توليد التقرير أولاً.');
      return;
    }
    downloadFile(`MJ_TACTICAL_AUDIT_${Date.now()}.json`, JSON.stringify(APP_STATE.latestReport, null, 2), 'application/json');
  });

  document.getElementById('btn-export-report-md')?.addEventListener('click', () => {
    if (!APP_STATE.latestReport) {
      alert('يرجى توليد التقرير أولاً.');
      return;
    }
    const r = APP_STATE.latestReport;
    const md = `# 🛡️ تقرير الفحص التكتيكي - MJ TACTICAL OS\n\n- **معرّف التقرير:** \`${r.report_id}\`\n- **التاريخ:** ${r.generated_at}\n- **المشغّل:** ${r.system.operator} (${r.system.founder})\n- **درجة الأمان:** ${r.security_score}/100 [${r.posture}]\n- **استهلاك الرام:** ${r.memory_status.rss}\n\n## مصفوفة الأدوات المفحوصة:\n${r.tools_summary.map((t) => `- **${t.name}** [${t.category}]: ${t.status}`).join('\n')}\n`;
    downloadFile(`MJ_TACTICAL_AUDIT_${Date.now()}.md`, md, 'text/markdown');
  });
}

function downloadFile(filename, content, mime) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// 7. WebSocket Live Streaming
function connectWebSocket() {
  if (APP_STATE.ws) {
    try { APP_STATE.ws.close(); } catch (_) {}
  }

  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const wsUrl = `${protocol}//${window.location.host}/ws?token=${encodeURIComponent(APP_STATE.token)}`;

  try {
    APP_STATE.ws = new WebSocket(wsUrl);

    APP_STATE.ws.onopen = () => {
      APP_STATE.wsConnected = true;
      const wsPill = document.getElementById('ws-status-pill');
      if (wsPill) {
        wsPill.innerHTML = `<span class="dot" style="background:#10b981;"></span> WS: STREAMING`;
        wsPill.className = 'status-pill online';
      }
    };

    APP_STATE.ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        handleWsEvent(msg);
      } catch (_) {}
    };

    APP_STATE.ws.onclose = () => {
      APP_STATE.wsConnected = false;
      const wsPill = document.getElementById('ws-status-pill');
      if (wsPill) {
        wsPill.innerHTML = `<span class="dot" style="background:#f59e0b;"></span> WS: STANDBY`;
        wsPill.className = 'status-pill';
      }
      setTimeout(connectWebSocket, 5000);
    };

    APP_STATE.ws.onerror = () => {
      APP_STATE.wsConnected = false;
    };
  } catch (_) {}
}

function handleWsEvent(msg) {
  if (msg.event === 'live_metrics' && msg.data) {
    const d = msg.data;
    if (d.cpu_load !== undefined && APP_STATE.gauges.cpu) {
      APP_STATE.gauges.cpu.setValue(Math.min(100, Math.round(d.cpu_load * 25)));
    }
    if (d.ram_formatted && APP_STATE.gauges.ram) {
      APP_STATE.gauges.ram.setValue(35, d.ram_formatted);
    }
  } else if (msg.event === 'tool_execution_completed') {
    displayConsoleOutput(msg.data.tool_id, msg.data.result);
  }
}

// 8. REST Polling Fallback
async function fetchInitialData() {
  try {
    // Health Check
    const healthRes = await fetch('/api/health', { headers: getAuthHeaders() });
    if (healthRes.ok) {
      const data = await healthRes.json();
      if (data.memory?.system?.used_percentage && APP_STATE.gauges.ram) {
        APP_STATE.gauges.ram.setValue(data.memory.system.used_percentage, data.memory.process.rss_formatted);
      }
      if (data.system?.load_average && APP_STATE.gauges.cpu) {
        APP_STATE.gauges.cpu.setValue(Math.min(100, Math.round(data.system.load_average[0] * 20)));
      }
      document.getElementById('uptime-display').textContent = data.uptime.process_formatted;
      document.getElementById('node-id-display').textContent = data.system.node_id;
    }

    // Hardware Telemetry
    const devRes = await fetch('/api/device-status', { headers: getAuthHeaders() });
    if (devRes.ok) {
      const dev = await devRes.json();
      if (dev.battery && APP_STATE.gauges.battery) {
        APP_STATE.gauges.battery.setValue(dev.battery.percentage, `${dev.battery.status} (${dev.battery.health})`);
      }
      if (dev.thermal && APP_STATE.gauges.thermal) {
        APP_STATE.gauges.thermal.setValue(dev.thermal.soc_celsius, `SoC State: ${dev.thermal.status}`);
      }
    }
  } catch (_) {}
}

function startPolling() {
  if (APP_STATE.pollTimer) clearInterval(APP_STATE.pollTimer);
  APP_STATE.pollTimer = setInterval(fetchInitialData, APP_STATE.scanIntervalSec * 1000);
}

function resetPolling() {
  startPolling();
}

// Modal Helpers
function openModal(id) {
  document.getElementById(id)?.classList.add('active');
}
function closeModal(id) {
  document.getElementById(id)?.classList.remove('active');
}

// 9. PWA Registration
function registerPWA() {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').catch(() => {});
  }
}
