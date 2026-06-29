/* Facts Scene — cover (top) + title left + emotion image right */

class FactsScene {
  constructor(config) {
    this.config = config;
    this.facts = (config.scenes || []).filter(s => s.id === 'fact' && s.emotion);
    this.currentFactIdx = -1;
    this._active = false;
    this.el = null;
    this.emotionImg = null;
    this.coverImg = null;
  }

  mount(container) {
    const el = document.createElement('div');
    el.className = 'fact-scene';

    const coverHtml = this.config.cover_url
      ? `<img class="fact-cover-img" src="${this._esc(this.config.cover_url)}" alt="" />`
      : `<div class="fact-cover-placeholder"></div>`;

    el.innerHTML = `
      <div class="fact-cover-wrap">${coverHtml}</div>
      <div class="fact-bottom">
        <div class="fact-title">${this._esc(this.config.title || '')}</div>
        <div class="fact-emotion-wrap">
          <img class="fact-emotion-img" src="" alt="" />
        </div>
      </div>
    `;

    container.appendChild(el);
    this.el = el;
    this.emotionImg = el.querySelector('.fact-emotion-img');
    this.coverImg = el.querySelector('.fact-cover-img');
    return el;
  }

  show() {
    if (!this.el) return;
    this._active = true;
    this.el.classList.add('active');
    if (this.coverImg) {
      this.coverImg.style.transition = 'transform 25s linear';
      this.coverImg.style.transform = 'scale(1.05)';
    }
  }

  hide() {
    if (!this.el) return;
    this._active = false;
    this.el.classList.remove('active');
  }

  tick(currentTime) {
    if (!this._active) return;

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

    if (activeIdx !== -1) {
      this._setEmotion(this.facts[activeIdx].emotion, activeIdx);
    }
  }

  _setEmotion(emotion, idx) {
    if (!this.emotionImg) return;
    this.emotionImg.classList.remove('emotion-visible');
    setTimeout(() => {
      if (this.currentFactIdx !== idx) return;
      this.emotionImg.src = `/assets/emotions/${emotion}.png`;
      void this.emotionImg.offsetWidth;
      this.emotionImg.classList.add('emotion-visible');
    }, 250);
  }

  _esc(str) {
    return String(str)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
}

window.FactsScene = FactsScene;
