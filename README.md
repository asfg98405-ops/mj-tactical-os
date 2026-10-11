<div align="center">

<img src="public/assets/dragon-crest.svg" alt="MJ Tactical OS Logo" width="140" height="140" />

# 🐉 MJ TACTICAL OS
### Sovereign Cyber Command Center & Edge Diagnostic Gateway
**Architecture: 5-Autonomous Agent Hierarchy | Edition: Cyber Blue Dragon | Founder: MJ**

[![License: MIT / Commercial Dual](https://img.shields.io/badge/License-Dual%20MIT%20%2F%20Commercial-00f0ff.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Kali%20NetHunter%20Rootless%20%7C%20Termux%20%7C%20Linux-0077ff.svg?style=flat-square)](https://kali.org)
[![Node.js](https://img.shields.io/badge/Node.js-v18%2B%20%2F%20v24-38bdf8.svg?style=flat-square)](https://nodejs.org)
[![Security Model](https://img.shields.io/badge/Security-Zero--Trust%20Bearer%20Auth-10b981.svg?style=flat-square)](#-zero-trust-security-architecture)
[![Test Suite](https://img.shields.io/badge/CI%20Verification-30%2F30%20PASSED%20(100%25)-emerald.svg?style=flat-square)](test/test_suite.js)

[**العربية**](#-الوصف-العربي-للمنظومة) | [**English Documentation**](#-english-overview) | [**12-Tool Suite**](#-12-tool-network--security-suite) | [**Commercial Licensing**](#-commercial-licensing--pricing-tiers)

---
</div>

## 🌐 English Overview

**MJ Tactical OS** is a sovereign, hermetic cyber command center and edge security gateway engineered specifically for mobile security terminals (RedMagic, Android ARM64) and rootless Kali NetHunter environments. Operating natively on port `4848`, it unifies high-frequency hardware telemetry, real-time WebSocket event streaming, and an interactive Cyber Blue Dragon PWA dashboard with a zero-trust hardened diagnostic suite.

---

## 🇸🇦 الوصف العربي للمنظومة

**منظومة MJ Tactical OS** هي مركز قيادة وسيطرة سيبرانية متقدم وبوابة عمليات حافة (Edge Gateway) مبنية وفق أعلى درجات الانضباط الهندسي للعمل على الهواتف الذكية المتقدمة (مثل RedMagic) وبيئات **Kali NetHunter Rootless (PRoot)** ونظام Termux. تعمل المنظومة على منفذ `4848` المحمي بالكامل بنظام الأمان الصفري (Zero-Trust) مع لوحة قيادة PWA تفاعلية بثيم **التنين السيبراني الأزرق** وشعار المؤسس **MJ**.

---

## 🏛️ Multi-Agent Architecture (الهيكل الخماسي للوكلاء الذاتيين)

To maintain maximum engineering rigor, the platform is structured around a 5-Autonomous Agent hierarchy:

```
                     ┌──────────────────────────────────────────────────┐
                     │   1. وكيل الإدارة والتنسيق العام (Lead Orchestrator) │
                     │      (إدارة تدفق العمل، المهام، ومعايير القبول)     │
                     └────────────────────────┬─────────────────────────┘
                                              │
         ┌────────────────────────────────────┼────────────────────────────────────┐
         ▼                                    ▼                                    ▼
┌─────────────────────────────────┐  ┌─────────────────────────────────┐  ┌─────────────────────────────────┐
│  2. مشرف الهندسة والتطوير        │  │  3. مراقب العمليات والعتاد      │  │  4. مدقق الأمان والجودة         │
│     (Engineering Supervisor)    │  │     (Operations Monitor)        │  │     (Security & QA Auditor)      │
├─────────────────────────────────┤  ├─────────────────────────────────┤  ├─────────────────────────────────┤
│ • بناء واجهة PWA التفاعلية      │  │ • مراقبة استهلاك الرام والحرارة │  │ • فحص تسريب البيانات الشخصية   │
│ • ربط الـ APIs مع كالي وTermux  │  │ • مراقبة قنوات WebSockets الحية │  │ • تدقيق كود الفحص والأمان       │
│ • ضبط عناصر التحكم والسلايدرات  │  │ • التأكد من ثبات خادم البوابة   │  │ • فحص استيفاء اختبارات الـ CI   │
└─────────────────────────────────┘  └─────────────────────────────────┘  └─────────────────────────────────┘
                                              │
                                              ▼
                     ┌──────────────────────────────────────────────────┐
                     │    5. مدير التراخيص والنشر (Release Manager)    │
                     │      (إدارة مستودع GitHub وتوثيق الملكية لـ MJ)   │
                     └──────────────────────────────────────────────────┘
```

1. **Lead Orchestrator (وكيل الإدارة والتنسيق):** Breaks down project roadmap, enforces acceptance criteria, and synchronizes milestones.
2. **Engineering Supervisor (مشرف الهندسة البرمجية):** Architects the PWA Cockpit, manages the 12-tool network suite, and binds the REST & WebSocket contracts.
3. **Operations Monitor (مراقب العمليات والعتاد):** Monitors port 4848 uptime, streams RedMagic thermal/battery telemetry, and calibrates scan frequency sliders (1s-60s).
4. **Security & QA Auditor (مدقق الأمان والجودة):** Enforces Zero-Trust isolation, timing-safe authentication, zero private data leakage, and ensures 100% test passing.
5. **Release & Governance Manager (مدير التراخيص والنشر):** Governs commercial ownership under Founder MJ, subscription packages, and repository integrity.

---

## 🚀 Features & Capabilities

- 🐉 **Cyber Blue Dragon PWA Cockpit:** Futuristic, high-contrast, responsive interface with SVG radial gauges and offline Service Worker caching.
- ⚡ **Live Sensor Telemetry:** Real-time SoC temperature (°C), battery charge rate, CPU load average, and RAM memory utilization.
- 🎛️ **Tactical Control Deck:** Adjustable sampling frequency slider (1s to 60s), Scan Mode selector (Passive, Stealth, Deep, Aggressive), and strict loopback firewall isolation toggles.
- 🛠️ **12-Tool Network & Security Suite:** Full array of defensive network audit and diagnostic tools directly integrated into the dashboard.
- 📑 **Forensic Reporting Engine:** Generates signed, structured JSON and Markdown audit reports with one click.
- 🔒 **Zero-Trust Loopback Isolation:** Constant-time token verification resistant to timing attacks; zero hardcoded secrets.

---

## 🛠️ 12-Tool Network & Security Suite (مصفوفة الأدوات الـ 12)

| # | Tool Identifier | Name (English / Arabic) | Category | Description |
|---|---|---|---|---|
| **01** | `port_scout` | **Port Scout**<br>كاشف المنافذ وسرعة الاتصال | `NETWORK` | Checks TCP socket reachability and measures millisecond connection handshake latency. |
| **02** | `dns_audit` | **DNS Resolver Benchmark**<br>تدقيق واختبار محلل النطاقات | `NETWORK` | Measures resolution response times across system nameservers and validates answer records. |
| **03** | `auth_probe` | **Zero-Trust Auth Probe**<br>فحص مناعة الدخول والأمان الصفري | `SECURITY` | Tests constant-time token comparison resistance and verifies unauthorized ingress rejection (HTTP 401). |
| **04** | `header_inspect` | **Security Headers Auditor**<br>فحص ترويسات الأمان HTTP | `SECURITY` | Inspects CSP, X-Frame-Options, X-Content-Type-Options, and anti-clickjacking framing defenses. |
| **05** | `device_telemetry` | **Hardware & Thermal Prober**<br>حساسات عتاد RedMagic | `TELEMETRY` | Ingests battery %, charging status, and SoC temperature sensors via Termux API. |
| **06** | `interface_analyzer` | **Interface & CIDR Analyzer**<br>محلل واجهات الشبكة وكتل العناوين | `NETWORK` | Extracts routing tables, IPv4/IPv6 CIDR prefixes, and verifies loopback isolation. |
| **07** | `latency_jitter` | **Latency & Jitter Monitor**<br>مراقب سرعة الاستجابة والتذبذب | `NETWORK` | Calculates round-trip microsecond timings and statistical jitter variance across local sockets. |
| **08** | `wol_dispatch` | **Wake-on-LAN Dispatcher**<br>مرسل حزم الإيقاظ الشبكي WoL | `NETWORK` | Constructs and broadcasts standard UDP magic packets to wake remote research nodes. |
| **09** | `memory_profiler` | **V8 Memory & RSS Profiler**<br>مدقق استهلاك الرام وذاكرة V8 | `SYSTEM` | Monitors Node.js V8 heap usage, external allocations, RSS footprint, and detects leaks. |
| **10** | `intent_validator` | **Android Intent Whitelist Validator**<br>مدقق القائمة البيضاء لأوامر أندرويد | `SECURITY` | Validates Android Intent execution requests against strictly locked security whitelists. |
| **11** | `clipboard_guard` | **Clipboard Buffer Guard**<br>حارس ومراقب حافظة النظام | `SECURITY` | Safely queries Android clipboard activity with zero persistent storage of sensitive data. |
| **12** | `nethunter_audit` | **NetHunter Core Health & CVE Posture**<br>فحص النواة والأمان الشامل لكالي | `SECURITY` | Executes the full Kali NetHunter platform audit script and generates a forensic report. |

---

## 💎 Commercial Licensing & Pricing Tiers (باقات الاشتراك والترخيص التجاري)

**MJ Tactical OS** is distributed under a **Dual License model**: open-source under the MIT License for community and research use, and commercial licensing for production teams and studios:

| Package Tier | Monthly Price | Target Audience | Included Capabilities |
|---|---|---|---|
| **Indie Tier** | **$9 / mo** | Solo Developers & Enthusiasts | • Single Tactical Edge Node<br>• Core 12-Tool Suite<br>• Interactive PWA Cockpit<br>• Monthly community patches |
| **Studio Tier** *(Popular)* | **$29 / mo** | Teams & Software Studios | • Up to 5 Synchronized Tactical Nodes<br>• High-Frequency WebSocket Streaming (1s)<br>• Custom Intent & Automation Bridge<br>• Export Unified Reports (JSON & MD)<br>• Priority Engineering Support |
| **Enterprise Tier** | **$99 / mo** | Enterprises & SOC Operations | • Unlimited Edge & Mobile Field Nodes<br>• Dedicated Kali NetHunter Rootless Customization<br>• Full Air-Gapped SLA & Sovereign Deployment<br>• Perpetual Commercial License by Founder MJ |

---

## ⚡ Quickstart Guide

### 1. Clone & Setup
```bash
git clone https://github.com/asfg98405-ops/mj-tactical-os.git
cd mj-tactical-os
npm install
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env if you wish to set custom port or static auth key
```

### 3. Run Automated Tests
```bash
npm test
```
*Expected: 30 / 30 PASSED (100% Hermetic Success)*

### 4. Launch Gateway & Cockpit
```bash
npm start
```

Access the interactive Cockpit in your browser:
```
http://127.0.0.1:4848/
```

---

## 🛡️ Zero-Trust Security Architecture

1. **Loopback Binding by Default:** Gateway binds strictly to `127.0.0.1:4848` unless configured otherwise.
2. **Constant-Time Cryptographic Auth:** Bearer token validation utilizes `crypto.timingSafeEqual` over fixed-length buffer hashes.
3. **Dynamic Key Generation:** Generates a high-entropy 32-byte hex token on first initialization stored in mode `0600` `.gateway_token`.
4. **Hermetic Rootless Execution:** Zero requirements for root/superuser privileges, preventing privilege escalation vectors.

---

## 📜 Contributing & Governance

Please consult [CONTRIBUTING.md](CONTRIBUTING.md) for engineering standards, commit guidelines, and PR procedures.

---

<div align="center">
<sub>Designed and engineered by Founder <b>MJ</b> and the 5-Autonomous Agent Collective.</sub>
</div>
