/* Calendar Scene — Scene 0 */

class CalendarScene {
  constructor(config) {
    this.config = config;
    this.el = null;
    this.dayEls = [];
    this.targetDay = parseInt(config.day, 10);
    this.animDone = false;
  }

  mount(container) {
    const el = document.createElement('div');
    el.className = 'scene calendar-scene';

    const monthName = this._getMonthName();

    el.innerHTML = `
      <img class="calendar-logo" src="/assets/logo.png" alt="" />
      <div class="calendar-month">${monthName}</div>
      <div class="calendar-grid" id="cal-grid"></div>
    `;
    container.appendChild(el);
    this.el = el;

    this._buildGrid();
    return el;
  }

  _getMonthName() {
    const lang = this.config.language || 'en';
    const monthNamesEn = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const monthNamesRu = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    if (this.config.month_name) return this.config.month_name;
    const monthNum = this._getMonthNum();
    return lang === 'ru' ? monthNamesRu[monthNum] : monthNamesEn[monthNum];
  }

  _getMonthNum() {
    // Derive month number from config or scenes data
    // Fallback: parse from date_display if available
    return 1; // default — main.js should pass full config
  }

  _daysInMonth() {
    // Use year and month from config
    const year = parseInt(this.config.year || new Date().getFullYear(), 10);
    // Find the month from month_name
    const monthMap = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'январь': 1, 'февраль': 2, 'март': 3, 'апрель': 4,
      'май': 5, 'июнь': 6, 'июль': 7, 'август': 8,
      'сентябрь': 9, 'октябрь': 10, 'ноябрь': 11, 'декабрь': 12,
    };
    const mn = this.config.month_name ? this.config.month_name.toLowerCase() : 'january';
    const month = monthMap[mn] || 1;
    return new Date(year, month, 0).getDate();
  }

  _firstDayOfMonth() {
    const year = parseInt(this.config.year || new Date().getFullYear(), 10);
    const monthMap = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'январь': 1, 'февраль': 2, 'март': 3, 'апрель': 4,
      'май': 5, 'июнь': 6, 'июль': 7, 'август': 8,
      'сентябрь': 9, 'октябрь': 10, 'ноябрь': 11, 'декабрь': 12,
    };
    const mn = this.config.month_name ? this.config.month_name.toLowerCase() : 'january';
    const month = monthMap[mn] || 1;
    // 0 = Sunday, 1 = Monday ... convert to Monday-first
    let dow = new Date(year, month - 1, 1).getDay();
    return (dow + 6) % 7; // Monday = 0
  }

  _buildGrid() {
    const grid = this.el.querySelector('#cal-grid');

    const firstDay  = this._firstDayOfMonth();
    const totalDays = this._daysInMonth();

    for (let i = 0; i < firstDay; i++) {
      const empty = document.createElement('div');
      empty.className = 'calendar-day empty';
      grid.appendChild(empty);
    }

    this.dayEls = [];
    for (let d = 1; d <= totalDays; d++) {
      const cell = document.createElement('div');
      cell.className = 'calendar-day';
      if (d === this.targetDay) cell.classList.add('target');
      cell.textContent = d;
      cell.dataset.day = d;
      grid.appendChild(cell);
      this.dayEls.push(cell);
    }
  }

  show() {
    if (!this.el) return;
    this.el.classList.add('active');
    if (!this.animDone) {
      this._animateDays();
    }
  }

  hide() {
    if (!this.el) return;
    this.el.classList.remove('active');
  }

  _animateDays() {
    this.animDone = true;
    const delay = 50; // ms per day
    this.dayEls.forEach((cell, i) => {
      setTimeout(() => {
        cell.classList.add('visible');
        if (parseInt(cell.dataset.day, 10) === this.targetDay) {
          // Zoom the target day after all appear
          setTimeout(() => {
            cell.classList.add('zoom');
          }, this.dayEls.length * delay + 200);
        }
      }, i * delay);
    });
  }
}

window.CalendarScene = CalendarScene;
