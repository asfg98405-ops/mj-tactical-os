/**
 * MJ Tactical OS - SVG Radial Gauge Engine
 * Handles smooth SVG circular meter animations and tactical color shifting.
 */

class TacticalGauge {
  constructor(elementId, options = {}) {
    this.container = document.getElementById(elementId);
    this.min = options.min || 0;
    this.max = options.max || 100;
    this.unit = options.unit || '%';
    this.title = options.title || 'METRIC';
    this.subtitle = options.subtitle || '';
    this.colorType = options.colorType || 'cyan'; // cyan, dynamic-temp, emerald
    this.circumference = 2 * Math.PI * 60; // r=60 -> ~377

    this.render();
  }

  render() {
    if (!this.container) return;
    this.container.innerHTML = `
      <div class="gauge-title">${this.title}</div>
      <div class="gauge-visual">
        <svg class="gauge-svg" viewBox="0 0 140 140">
          <circle class="gauge-bg-circle" cx="70" cy="70" r="60"></circle>
          <circle class="gauge-bar-circle" id="${this.container.id}-bar" cx="70" cy="70" r="60"></circle>
        </svg>
        <div class="gauge-center-text">
          <span class="gauge-val" id="${this.container.id}-val">--</span>
          <span class="gauge-unit">${this.unit}</span>
        </div>
      </div>
      <div class="gauge-subtitle" id="${this.container.id}-sub">${this.subtitle}</div>
    `;

    this.barEl = document.getElementById(`${this.container.id}-bar`);
    this.valEl = document.getElementById(`${this.container.id}-val`);
    this.subEl = document.getElementById(`${this.container.id}-sub`);
  }

  setValue(val, customSub = null) {
    if (!this.barEl || !this.valEl) return;
    const clamped = Math.max(this.min, Math.min(this.max, val));
    const pct = (clamped - this.min) / (this.max - this.min);
    const offset = this.circumference * (1 - pct);

    this.barEl.style.strokeDashoffset = offset;
    this.valEl.textContent = typeof val === 'number' ? (Number.isInteger(val) ? val : val.toFixed(1)) : val;

    if (customSub !== null && this.subEl) {
      this.subEl.textContent = customSub;
    }

    // Dynamic color tuning
    if (this.colorType === 'dynamic-temp') {
      if (val < 40) {
        this.barEl.style.stroke = '#00f0ff';
      } else if (val < 55) {
        this.barEl.style.stroke = '#f59e0b';
      } else {
        this.barEl.style.stroke = '#ef4444';
      }
    } else if (this.colorType === 'battery') {
      if (val > 25) {
        this.barEl.style.stroke = '#10b981';
      } else {
        this.barEl.style.stroke = '#ef4444';
      }
    }
  }
}

window.TacticalGauge = TacticalGauge;
