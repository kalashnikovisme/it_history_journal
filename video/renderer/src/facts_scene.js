/* Facts Scene — overlaid on cover */

class FactsScene {
  constructor(config) {
    this.config = config;
    this.el = null;
    this.textEl = null;
    this.currentText = null;
    // Extract all fact scenes
    this.facts = (config.scenes || []).filter(s => s.id === 'fact');
    this._active = false;
  }

  mount(container) {
    const el = document.createElement('div');
    el.className = 'scene facts-scene';
    el.innerHTML = `<div class="fact-text" id="fact-text"></div>`;
    container.appendChild(el);
    this.el = el;
    this.textEl = el.querySelector('#fact-text');
    return el;
  }

  // Called by main.js on each animation frame with the current clock time
  tick(currentTime) {
    if (!this._active) return;

    // Find which fact should be shown
    const activeFact = this._findActiveFact(currentTime);
    const newText = activeFact ? activeFact.text : null;

    if (newText !== this.currentText) {
      this._switchText(newText);
    }
  }

  _findActiveFact(currentTime) {
    for (const fact of this.facts) {
      if (currentTime >= fact.start && currentTime < fact.start + fact.duration) {
        return fact;
      }
    }
    return null;
  }

  _switchText(text) {
    this.currentText = text;
    if (!this.textEl) return;

    // Fade out
    this.textEl.classList.remove('visible');

    if (!text) return;

    setTimeout(() => {
      if (this.textEl && this.currentText === text) {
        this.textEl.textContent = text;
        // Force reflow
        void this.textEl.offsetHeight;
        this.textEl.classList.add('visible');
      }
    }, 200);
  }

  show() {
    if (!this.el) return;
    this._active = true;
    this.el.classList.add('active');
  }

  hide() {
    if (!this.el) return;
    this._active = false;
    this.el.classList.remove('active');
    this.currentText = null;
    if (this.textEl) {
      this.textEl.classList.remove('visible');
      this.textEl.textContent = '';
    }
  }
}

window.FactsScene = FactsScene;
