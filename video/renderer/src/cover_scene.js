/* Cover Scene — Scene 2 + Title Card */

class TitleCardScene {
  constructor(config) {
    this.config = config;
    this.el = null;
  }

  mount(container) {
    const el = document.createElement('div');
    el.className = 'scene title-scene';
    el.innerHTML = `
      <div class="date-label">${this._escapeHtml(this.config.date_display || '')}</div>
      <div class="title-text">${this._escapeHtml(this.config.title || '')}</div>
    `;
    container.appendChild(el);
    this.el = el;
    return el;
  }

  show() {
    if (!this.el) return;
    this.el.classList.add('active');
  }

  hide() {
    if (!this.el) return;
    this.el.classList.remove('active');
  }

  _escapeHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}

class CoverScene {
  constructor(config) {
    this.config = config;
    this.el = null;
    this.imgEl = null;
    this.parallaxStarted = false;
  }

  mount(container) {
    const el = document.createElement('div');
    el.className = 'scene cover-scene';

    const imgSrc = this.config.cover_url || '';
    el.innerHTML = `
      <div class="cover-image-container">
        ${imgSrc
          ? `<img src="${this._escapeHtml(imgSrc)}" alt="cover" id="cover-img" />`
          : `<div style="width:100%;height:100%;background:#282626;"></div>`
        }
      </div>
      <div class="cover-meta">
        <div class="date-label">${this._escapeHtml(this.config.date_display || '')}</div>
        <div class="title-text">${this._escapeHtml(this.config.title || '')}</div>
      </div>
    `;
    container.appendChild(el);
    this.el = el;
    this.imgEl = el.querySelector('#cover-img');
    return el;
  }

  show() {
    if (!this.el) return;
    this.el.classList.add('active');
    if (this.imgEl && !this.parallaxStarted) {
      this.parallaxStarted = true;
      // Start Ken Burns zoom
      this.imgEl.style.transition = 'transform 20s linear';
      this.imgEl.style.transform = 'scale(1.06)';
    }
  }

  hide() {
    if (!this.el) return;
    this.el.classList.remove('active');
  }

  _escapeHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}

window.TitleCardScene = TitleCardScene;
window.CoverScene = CoverScene;
