/* CTA Scene — final branded screen */

class CTAScene {
  constructor(config) {
    this.config = config;
    this.el = null;
  }

  mount(container) {
    const lang = this.config.language || 'en';
    const siteUrl = this.config.site_url || 'history.purple-magic.com';

    let tagline, logoText;
    if (lang === 'ru') {
      logoText = 'IT History Journal';
      tagline  = 'Подписывайтесь';
    } else {
      logoText = 'IT History Journal';
      tagline  = 'Follow';
    }

    const el = document.createElement('div');
    el.className = 'scene cta-scene';
    el.innerHTML = `
      <div class="cta-logo">${this._escapeHtml(logoText)}</div>
      <div class="cta-divider"></div>
      <div class="cta-tagline">${this._escapeHtml(tagline)}</div>
      <div class="cta-url">${this._escapeHtml(siteUrl)}</div>
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

window.CTAScene = CTAScene;
