/* Character Scene — emotion image overlay, bottom of screen, random x per fact */

class CharacterScene {
  constructor(config) {
    this.config = config;
    this.el = null;
    this.imgEl = null;
    this.facts = (config.scenes || []).filter(s => s.id === 'fact' && s.emotion);
    this.currentEmotion = null;
    this.currentFactIdx = -1;
    // Pre-compute one random x position per fact so it's stable across ticks
    this.xPositions = this.facts.map(() => this._randomX());
  }

  mount(container) {
    const el = document.createElement('div');
    el.className = 'character-overlay';
    el.innerHTML = '<img class="character-img" src="" alt="" />';
    container.appendChild(el);
    this.el = el;
    this.imgEl = el.querySelector('.character-img');
    return el;
  }

  tick(currentTime) {
    if (!this.el) return;

    let activeIdx = -1;
    for (let i = 0; i < this.facts.length; i++) {
      const f = this.facts[i];
      if (currentTime >= f.start && currentTime < f.start + f.duration) {
        activeIdx = i;
        break;
      }
    }

    if (activeIdx === this.currentFactIdx) return;
    this.currentFactIdx = activeIdx;

    if (activeIdx === -1) {
      this._hide();
    } else {
      this._show(this.facts[activeIdx].emotion, activeIdx);
    }
  }

  _show(emotion, idx) {
    if (!this.el) return;

    // Fade out first, then swap image and position, then fade back in
    this.el.classList.remove('character-visible');

    setTimeout(() => {
      if (this.currentFactIdx !== idx) return; // superseded
      this.imgEl.src = `/assets/emotions/${emotion}.png`;
      this.el.style.left = `${this.xPositions[idx]}px`;
      void this.el.offsetWidth; // force reflow
      this.el.classList.add('character-visible');
    }, 300);
  }

  _hide() {
    if (!this.el) return;
    this.el.classList.remove('character-visible');
  }

  _randomX() {
    const imgWidth = 400;
    const margin   = 60;
    return Math.floor(Math.random() * (1080 - imgWidth - margin * 2)) + margin;
  }
}

window.CharacterScene = CharacterScene;
