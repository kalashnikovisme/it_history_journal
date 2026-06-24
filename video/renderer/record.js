#!/usr/bin/env node

'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const { spawnSync } = require('child_process');
const { chromium } = require('playwright');

const VIEWPORT = { width: 1080, height: 1920 };
const DEFAULT_TIMEOUT_MS = 180000;

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

const parseArgs = (argv) => {
  const args = {
    headful: false,
    quiet: false,
    timeout: DEFAULT_TIMEOUT_MS,
    output: 'browser-recording.webm',
    cover: null,
    config: null,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--config') {
      args.config = argv[i + 1];
      i += 1;
    } else if (arg === '--output') {
      args.output = argv[i + 1];
      i += 1;
    } else if (arg === '--cover') {
      args.cover = argv[i + 1];
      i += 1;
    } else if (arg === '--timeout') {
      args.timeout = Number(argv[i + 1]);
      i += 1;
    } else if (arg === '--headful') {
      args.headful = true;
    } else if (arg === '--quiet') {
      args.quiet = true;
    } else if (arg === '--help') {
      args.help = true;
    }
  }

  return args;
};

const showHelp = () => {
  console.log(`Usage: node record.js --config <path> --output <webm-path> [options]

Options:
  --config <path>       Path to render-config.json (required)
  --output <path>       Output .webm file path (default: browser-recording.webm)
  --cover <path>        Absolute path to cover image file
  --timeout <ms>        Timeout in milliseconds (default: ${DEFAULT_TIMEOUT_MS})
  --headful             Run browser with UI (for debugging)
  --help                Show this help message
`);
};

// ---------------------------------------------------------------------------
// MIME types
// ---------------------------------------------------------------------------

const contentTypes = {
  '.html': 'text/html',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.mp3':  'audio/mpeg',
  '.wav':  'audio/wav',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg':  'image/svg+xml',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

// ---------------------------------------------------------------------------
// Static server + cover mapping
// ---------------------------------------------------------------------------

const serveStatic = (rootDir, coverPath, assetsDir) => {
  const server = http.createServer((req, res) => {
    const requestPath = decodeURIComponent(req.url.split('?')[0]);

    if (requestPath.startsWith('/assets/')) {
      const assetPath = path.join(assetsDir, path.basename(requestPath));
      if (fs.existsSync(assetPath)) {
        fs.readFile(assetPath, (err, data) => {
          if (err) {
            res.statusCode = 500;
            res.end('Error reading asset');
            return;
          }
          const ext = path.extname(assetPath).toLowerCase();
          res.setHeader('Content-Type', contentTypes[ext] || 'application/octet-stream');
          res.end(data);
        });
        return;
      }
    }

    // Serve cover image at /cover/<filename>
    if (coverPath && requestPath.startsWith('/cover/')) {
      const filename = path.basename(requestPath);
      const expectedFilename = path.basename(coverPath);
      if (filename === expectedFilename && fs.existsSync(coverPath)) {
        fs.readFile(coverPath, (err, data) => {
          if (err) {
            res.statusCode = 500;
            res.end('Error reading cover');
            return;
          }
          const ext = path.extname(coverPath).toLowerCase();
          res.setHeader('Content-Type', contentTypes[ext] || 'image/webp');
          res.end(data);
        });
        return;
      }
    }

    const safeSuffix = path.normalize(requestPath).replace(/^\.+/, '');
    const filePath = path.join(rootDir, safeSuffix === '/' ? 'index.html' : safeSuffix);

    if (!filePath.startsWith(rootDir)) {
      res.statusCode = 403;
      res.end('Forbidden');
      return;
    }

    fs.stat(filePath, (err, stats) => {
      if (err) {
        res.statusCode = 404;
        res.end('Not found');
        return;
      }

      const resolvedPath = stats.isDirectory()
        ? path.join(filePath, 'index.html')
        : filePath;

      fs.readFile(resolvedPath, (readErr, data) => {
        if (readErr) {
          res.statusCode = 500;
          res.end('Error reading file');
          return;
        }
        const ext = path.extname(resolvedPath).toLowerCase();
        res.setHeader('Content-Type', contentTypes[ext] || 'application/octet-stream');
        res.end(data);
      });
    });
  });

  return new Promise((resolve, reject) => {
    server.listen(0, () => {
      const { port } = server.address();
      resolve({ server, port });
    });
    server.on('error', reject);
  });
};

// ---------------------------------------------------------------------------
// ffmpeg helpers
// ---------------------------------------------------------------------------

const ensureFfmpeg = () => {
  const result = spawnSync('ffmpeg', ['-version'], { stdio: 'ignore' });
  if (result.status !== 0) {
    throw new Error('ffmpeg is required. Install it (apt-get install ffmpeg).');
  }
};

const trimFirstFrame = (inputPath, outputPath, quiet = false) => {
  ensureFfmpeg();
  const args = [
    '-y',
    ...(quiet ? ['-loglevel', 'quiet'] : []),
    '-i', inputPath,
    '-vf', 'trim=start=0.2,setpts=PTS-STARTPTS',
    '-c:v', 'libvpx-vp9',
    '-an',
    outputPath,
  ];
  const result = spawnSync('ffmpeg', args, { stdio: quiet ? 'pipe' : 'inherit' });
  if (result.status !== 0) {
    throw new Error('ffmpeg failed to trim the first frame.');
  }
};

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const main = async () => {
  const args = parseArgs(process.argv.slice(2));

  if (args.help) {
    showHelp();
    return;
  }

  if (!args.config) {
    console.error('Missing required --config argument.');
    showHelp();
    process.exit(1);
  }

  const configPath = path.resolve(args.config);
  if (!fs.existsSync(configPath)) {
    throw new Error(`Config file not found: ${configPath}`);
  }

  const outputPath = path.resolve(args.output);
  const coverPath  = args.cover ? path.resolve(args.cover) : null;
  const rootDir    = path.resolve(__dirname);
  const assetsDir  = path.resolve(__dirname, '../assets');

  // Create tmpVideoDir inside rootDir so the static server can serve files from it
  const tmpVideoDir = fs.mkdtempSync(path.join(rootDir, 'tmp-video-'));

  const { server, port } = await serveStatic(rootDir, coverPath, assetsDir);
  if (!args.quiet) console.log(`Static server running on port ${port}`);

  // Parse config and inject cover_url before serving it
  let config;
  try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch (e) {
    throw new Error(`Failed to parse config JSON: ${e.message}`);
  }

  if (coverPath && fs.existsSync(coverPath)) {
    config.cover_url = `http://localhost:${port}/cover/${path.basename(coverPath)}`;
  } else {
    config.cover_url = null;
  }

  // Write patched config inside tmpVideoDir (within rootDir so static server can serve it)
  const patchedConfigPath = path.join(tmpVideoDir, 'config.json');
  fs.writeFileSync(patchedConfigPath, JSON.stringify(config));

  const pageUrl = `http://localhost:${port}/index.html?config=${encodeURIComponent(
    `http://localhost:${port}/${path.relative(rootDir, patchedConfigPath)}`
  )}`;

  let browser;
  try {
    browser = await chromium.launch({ headless: !args.headful });
    const context = await browser.newContext({
      recordVideo: { dir: tmpVideoDir, size: VIEWPORT },
      viewport: VIEWPORT,
    });
    const page = await context.newPage();

    if (!args.quiet) {
      page.on('console', (msg) => {
        console.log(`[browser] ${msg.type()}: ${msg.text()}`);
      });
    }
    page.on('pageerror', (err) => {
      console.error(`[browser] Page error: ${err.message}`);
    });

    if (!args.quiet) console.log(`Loading: ${pageUrl}`);
    await page.goto(pageUrl, { waitUntil: 'load' });

    // Wait for the animation to signal completion
    await page.evaluate((timeout) =>
      new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error('Timeout waiting for video:complete')), timeout);
        window.addEventListener('video:complete', () => {
          clearTimeout(timer);
          resolve();
        }, { once: true });
      }), args.timeout
    );

    await page.waitForTimeout(500);

    const video = page.video();
    await page.close();
    await context.close();

    const rawWebm = await video.path();
    if (!args.quiet) console.log(`Raw recording: ${rawWebm}`);

    // Trim first frame
    const trimmedWebm = outputPath.replace(/\.webm$/, '.trimmed.webm');
    trimFirstFrame(rawWebm, trimmedWebm, args.quiet);

    // Move trimmed to final output path
    fs.renameSync(trimmedWebm, outputPath);

    // Cleanup
    fs.rmSync(rawWebm, { force: true });
    fs.rmSync(tmpVideoDir, { recursive: true, force: true });
    fs.rmSync(patchedConfigPath, { force: true });

    if (!args.quiet) console.log(`Browser recording saved to ${outputPath}`);
  } finally {
    if (browser) {
      await browser.close();
    }
    server.close();
  }
};

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
