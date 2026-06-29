/* Main animation orchestrator */

(async () => {
  // ---------------------------------------------------------------------------
  // Load config from URL param ?config=<url>
  // ---------------------------------------------------------------------------
  const params = new URLSearchParams(window.location.search);
  const configUrl = params.get('config');

  let config;
  try {
    if (!configUrl) throw new Error('No ?config= param in URL');
    const resp = await fetch(configUrl);
    if (!resp.ok) throw new Error(`Failed to fetch config: ${resp.status} ${resp.statusText}`);
    config = await resp.json();
  } catch (err) {
    console.error('Failed to load config:', err.message);
    document.body.style.background = '#1a0000';
    document.body.innerHTML = `<div style="color:#f88;font-size:36px;padding:60px;font-family:sans-serif;">
      Config load error: ${err.message}
    </div>`;
    return;
  }

  console.log('[main] Config loaded:', config.title, 'duration:', config.total_duration);

  // ---------------------------------------------------------------------------
  // Setup WebGL background
  // ---------------------------------------------------------------------------
  const canvas = document.getElementById('webgl-canvas');
  const bg = new WebGLBackground();
  bg.init(canvas);
  bg.start();

  // ---------------------------------------------------------------------------
  // Mount scenes
  // ---------------------------------------------------------------------------
  const app = document.getElementById('app');

  const calendarScene   = new CalendarScene(config);
  const titleScene      = new TitleCardScene(config);
  const factsScene      = new FactsScene(config);
  const ctaScene        = new CTAScene(config);

  calendarScene.mount(app);
  titleScene.mount(app);
  factsScene.mount(app);
  ctaScene.mount(app);

  // ---------------------------------------------------------------------------
  // Identify scene timing from config
  // ---------------------------------------------------------------------------
  const scenesById = {};
  for (const s of (config.scenes || [])) {
    if (s.id !== 'fact') {
      // Only track unique non-fact scenes (first occurrence)
      if (!scenesById[s.id]) scenesById[s.id] = s;
    }
  }

  const getScene = (id) => scenesById[id];
  const calScene    = getScene('calendar');
  const titleScCfg  = getScene('title_card');
  const coverScCfg  = getScene('cover');
  const ctaScCfg    = getScene('cta');

  let calShown      = false;
  let titleShown    = false;
  let factsShown    = false;
  let ctaShown      = false;
  let calHidden     = false;
  let titleHidden   = false;
  let factsHidden   = false;

  const totalDuration = config.total_duration || 55;
  let completed = false;

  // ---------------------------------------------------------------------------
  // Clock-driven animation loop
  // ---------------------------------------------------------------------------
  const startTime = performance.now();

  const tick = () => {
    const elapsed = (performance.now() - startTime) / 1000;

    // Calendar
    if (calScene && elapsed >= calScene.start && !calShown) {
      calShown = true;
      calendarScene.show();
    }
    if (calScene && elapsed >= calScene.start + calScene.duration && !calHidden) {
      calHidden = true;
      calendarScene.hide();
    }

    // Title card
    if (titleScCfg && elapsed >= titleScCfg.start && !titleShown) {
      titleShown = true;
      titleScene.show();
    }
    if (titleScCfg && elapsed >= titleScCfg.start + titleScCfg.duration && !titleHidden) {
      titleHidden = true;
      titleScene.hide();
    }

    // Fact scene — cover top + title left + emotion right
    if (coverScCfg && elapsed >= coverScCfg.start && !factsShown) {
      factsShown = true;
      factsScene.show();
    }

    factsScene.tick(elapsed);

    // Hide fact scene when CTA starts
    if (ctaScCfg && elapsed >= ctaScCfg.start) {
      if (!ctaShown) {
        ctaShown = true;
        if (!factsHidden) {
          factsHidden = true;
          factsScene.hide();
        }
        ctaScene.show();
      }
    }

    // Complete
    if (!completed && elapsed >= totalDuration) {
      completed = true;
      console.log('[main] Animation complete at', elapsed.toFixed(2), 's');
      window.dispatchEvent(new Event('video:complete'));
      bg.stop();
      return;
    }

    requestAnimationFrame(tick);
  };

  requestAnimationFrame(tick);
})();
