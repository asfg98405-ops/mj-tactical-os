# Contributing to MJ Tactical OS 🐉

Welcome to the **MJ Tactical OS** engineering collective. We appreciate your interest in contributing to our sovereign cyber command and diagnostic operations platform.

---

## 🏛️ 1. Multi-Agent Governance Model (المنظومة الخماسية)

All architectural enhancements and pull requests are evaluated across our 5 Autonomous Engineering Agent pillars:

1. **👑 Lead Orchestrator:** Validates operational acceptance criteria and milestone alignment.
2. **⚙️ Engineering Supervisor:** Ensures UI/PWA components adhere to the Cyber Blue Dragon design system and Express/WebSocket contracts.
3. **📊 Operations Monitor:** Verifies runtime memory efficiency, socket stability on port 4848, and real-time telemetry streaming.
4. **🛡️ Security & QA Auditor:** Enforces Zero-Trust isolation, timing-safe authentication, and checks that tests maintain a 100% pass rate.
5. **🚀 Release & Governance Manager:** Oversees dual-licensing compliance, international documentation, and release integrity under Founder MJ.

---

## 📋 2. Strict Engineering Guidelines

### A. Zero Secret Leakage (Zero-Trust)
- **Never commit `.env`, `.gateway_token`, or personal credentials to Git.**
- Use `.env.example` exclusively for documenting configuration options.
- The repository is actively scanned for leaked tokens or personal identifiable information (PII).

### B. Rootless & Android Portability
- All tools and scripts must execute without requiring `root` or `sudo` access (compatible with PRoot / Kali NetHunter rootless / Termux).
- Avoid binary dependencies outside standard POSIX utilities (`socat`, `jq`, `curl`, `netcat`, `sh`).

### C. Automated Testing Before Submitting
Before pushing any code or opening a PR, ensure that the comprehensive test suite passes with 100% success:

```bash
npm test
```

All 30+ verification checks must succeed.

---

## 🛠️ 3. Pull Request Workflow

1. **Fork the repository** on GitHub.
2. **Create a descriptive feature branch:**
   ```bash
   git checkout -b feat/tactical-gauge-enhancement
   ```
3. **Commit your changes** using Conventional Commits:
   - `feat:` New features or tools
   - `fix:` Bug fixes or vulnerability mitigation
   - `docs:` Documentation improvements
   - `refactor:` Code refactoring without behavior change
   - `test:` Adding or refining test cases
4. **Run local verification:**
   ```bash
   npm test
   npm run audit
   ```
5. **Submit your Pull Request** with a detailed summary and reference issue.

---

## 🔒 4. Security Vulnerability Disclosure

If you discover a security vulnerability in MJ Tactical OS:
- **Do not open a public issue.**
- Submit an advisory directly to the project security team or via private repository reporting.
- Responsible disclosures will receive rapid triage from the Security & QA Auditor agent.

---

*Thank you for helping build sovereign, disciplined edge engineering!*
