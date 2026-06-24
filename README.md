# IT History Journal

A static site publishing daily articles about IT history, one event per day of the year.

Published at [history.purple-magic.com](https://history.purple-magic.com). Available in English and Russian — the language is chosen automatically based on browser settings.

## Structure

```
articles/
  en/
    may/
      19/
        james_gosling_was_born/
          content.md   ← article text + frontmatter
          cover.webp   ← optional cover image (webp preferred)
  ru/
    may/
      19/
        james_gosling_was_born/
          content.md
templates/           ← HAML page templates
lib/                 ← Ruby build system
bin/                 ← utility scripts
spec/                ← RSpec tests
```

### Article frontmatter

```markdown
---
title: "May 19, 1955 — James Gosling Was Born"
date: "May 19, 1955"
event_date: "1955-05-19"
event_year: 1955
excerpt: "Short summary shown in article cards."
popular: true
topics:
  - programming languages
people:
  - James Gosling
organizations:
  - Sun Microsystems
technologies:
  - Java
sources:
  - title: "Official Java history"
    url: "https://example.com/java-history"
---

Article body in Markdown (GFM).
```

`event_date`, `topics`, `people`, `organizations`, `technologies`, and `sources` power the visible Key facts/Sources sections, Article JSON-LD, and sitemap metadata. Add at least one source for each new article.

### URL mapping

`articles/en/may/19/james_gosling_was_born/content.md` → `/en/may/19/james-gosling-was-born`

### Cover images

Each article can have an optional cover image at `cover.webp` (preferred) or `cover.png` / `cover.jpg`.
Convert a single image to WebP with:

```bash
dip convert_to_webp articles/en/may/19/james_gosling_was_born/cover.png
```

Convert all `cover.png` files in the repository and remove the originals:

```bash
dip convert_covers
```

## Local development

### Installing dip

**macOS / Linux (Homebrew):**
```bash
brew tap bibendi/dip
brew install dip
```

**Any OS with Ruby:**
```bash
gem install dip
```

**Windows:** Use WSL2 with a Linux distribution, then follow the Linux instructions above.

Precompiled binaries are also available at [github.com/bibendi/dip/releases](https://github.com/bibendi/dip/releases).

### Setup

```bash
dip provision
```

Builds the Docker image and installs gems.

### Commands

| Command | Description |
|---|---|
| `dip rspec` | Run RSpec tests |
| `dip build` | Build the static site into `_site/` |
| `dip serve` | Build and serve at http://localhost:4711 |
| `dip watch` | Full build + file watcher + dev server at http://localhost:4711 |
| `dip convert_to_webp <file> [files...]` | Convert images to WebP format |
| `dip convert_covers` | Convert non-WebP covers to `cover.webp`, then generate `thumb.webp` (192×192) from each `cover.webp` |
| `dip rewrite_excerpts [jun-10]` | Rewrite article excerpts via OpenAI API (reads `OPENAI_API_KEY` from `.env.dev`). Pass a date like `jun-10` to limit to that day; omit to rewrite all articles. |
| `dip shell` | Open a shell in the container |
| `dip bundle <args>` | Run bundler commands |
| `dip video <article_folder>` | Generate branded short video from an article (full pipeline) |
| `dip video send <article_folder>` | Send `final.mp4` and YouTube metadata as five separate Telegram messages |
| `dip video text <article_folder>` | Generate narration text only (no audio/render) |
| `dip video part calendar <article_folder>` | Render only the calendar video segment without audio |
| `dip audio <article_folder>` | Generate audio narration (TTS) from an article |
| `dip audio generate FILE.txt OUTPUT.mp3` | Synthesize text from FILE.txt to MP3 using the same TTS model and voice as the article pipeline |
| `dip video_shell` | Open a shell in the video container |
| `dip grow <subcommand>` | Run the growth CLI (SEO, distribution, analytics) |
| `dip growth_shell` | Open a shell in the growth app container |
| `dip grow_test` | Run growth tests |

### Watch mode

`dip watch` does a full initial build (CSS + HTML), starts a server at http://localhost:4711, then listens for file changes:

- **`.md` changed** — rebuilds the affected article page + all index/calendar pages (~0.1s)
- **`.haml` changed** — rebuilds all HTML pages (~0.15s)
- **cover image added/changed** — rebuilds the article the image belongs to

### Scripts

| Script | Description |
|---|---|
| `bin/watch` | Underlying script for `dip watch` |
| `bin/convert_to_webp` | Convert images to WebP (requires ImageMagick; use `dip convert_to_webp` inside Docker) |
| `bin/convert_covers` | Phase 1: convert non-WebP covers to `cover.webp` and delete originals. Phase 2: generate `thumb.webp` (192×192) and `hero.webp` (576×384) from every `cover.webp` |
| `bin/rewrite_excerpts` | Rewrites all article excerpts to short, date-free fact sentences via OpenAI API (gpt-4.1-nano). Run as `OPENAI_API_KEY=sk-... ruby bin/rewrite_excerpts`. Add `--dry-run` to preview without writing. |

`bin/convert_to_webp` options:

| Flag | Default | Description |
|---|---|---|
| `-q`, `--quality N` | `80` | WebP quality 1–100 |
| `-w`, `--max-width N` | — | Resize to fit within this width |
| `-t`, `--thumb-only WxH` | — | Write a W×H centered crop to `thumb.webp` only — use `N` for a square or `WxH` for a rectangle (skips main output) |
| `-n`, `--thumb-name NAME` | `thumb.webp` | Override the output filename for `--thumb-only` |
| `--no-strip` | — | Keep EXIF metadata |

## Video generation

The `video/` module generates branded short vertical videos (1080×1920) from articles.

### Setup

The video pipeline runs in its own Docker container (`video_app`) with ffmpeg, Node.js, and Playwright pre-installed.

Required environment variable in `.env.dev`:
```
OPENAI_API_KEY=sk-...
```

### Commands

```bash
# Full pipeline: narration → TTS audio → YouTube metadata → browser render → final.mp4
dip video articles/ru/jun/21/tim_bray_was_born

# Text only: generate narration.txt without audio or render
dip video text articles/ru/jun/21/tim_bray_was_born

# Audio only: generate narration.txt + narration.mp3
dip audio articles/ru/jun/21/tim_bray_was_born

# Shell in the video container (for debugging)
dip video_shell
```

### Flags

| Flag | Description |
|---|---|
| `--force-text` | Regenerate narration.txt even if it already exists |
| `--force-audio` | Regenerate narration.mp3 even if it already exists |
| `--force-scenes` | Regenerate scenes.json even if it already exists |
| `--force-youtube` | Regenerate the YouTube Shorts title, description, and tags |

### Output files

All output lands in `video/output/{lang}/{mon}/{dd}/{slug}/`:

| File | Description |
|---|---|
| `prompt.txt` | Full prompt sent to OpenAI |
| `narration.txt` | Generated narration text (edit this to re-run audio) |
| `tts-request.json` | TTS request parameters |
| `narration.mp3` | Generated audio (TTS, voice: onyx) |
| `scenes.json` | Scene timing plan |
| `metadata.json` | Article/scene data plus optimized YouTube Shorts title, tags, and a description linking to the journal, Patreon, and PayPal |
| `render-config.json` | Config fed to the JS renderer |
| `browser-recording.webm` | Raw browser recording |
| `final.mp4` | Final composed video |

Run `dip video send <article_folder>` to send `final.mp4`, the YouTube title, full description, link-free description, and tags to `TELEGRAM_CHAT_ID` as five separate Telegram messages. The chat defaults to `122018070`.

### Editing the narration

To tweak the narration before generating audio:

```bash
dip video text articles/ru/jun/21/tim_bray_was_born
# edit video/output/ru/jun/21/tim_bray_was_born/narration.txt
dip audio articles/ru/jun/21/tim_bray_was_born   # picks up edited narration.txt
dip video articles/ru/jun/21/tim_bray_was_born   # re-runs render + compose
```

## Growth / SEO

The `growth/` module provides a CLI for SEO analysis, distribution drafts, and analytics.

### Commands

`seo` is a subcommand namespace — it requires a sub-subcommand before the path:

```bash
# Generate SEO suggestions for an article
dip grow seo suggest articles/en/jun/22/quake_was_released/content.md

# Show SEO progress history + generate a new SEO report
dip grow article seo articles/en/jun/22/quake_was_released/content.md

# Analyze article quality
dip grow article analyze articles/en/jun/22/quake_was_released/content.md

# Run analysis + SEO + conversion drafts in one go
dip grow article promote articles/en/jun/22/quake_was_released/content.md

# Generate social distribution drafts
dip grow distribution generate articles/en/jun/22/quake_was_released/content.md

# Generate Patreon/Boosty conversion suggestions
dip grow conversion articles/en/jun/22/quake_was_released/content.md

# Analytics
dip grow analytics top               # top 20 pages, last 7 days
dip grow analytics top --days 30     # extend the date range
dip grow analytics top --limit 50    # fetch more rows

# Search Console
dip grow search top                  # top queries, last 28 days
dip grow search top --pages          # top pages instead of queries
```

A common mistake is running `dip grow seo <path>` — Thor interprets the path as the missing sub-subcommand. Use `dip grow seo suggest <path>` or `dip grow article seo <path>` instead.

## RSS feeds

The build generates an RSS 2.0 feed for each language:

| URL | Feed |
|---|---|
| `/en/feed.xml` | English articles |
| `/ru/feed.xml` | Russian articles |

Feeds are regenerated automatically on every full build and every time an article is added or changed (watch mode).

## Search indexing

The build generates root-level crawler files:

| URL | Purpose |
|---|---|
| `/robots.txt` | Allows crawlers and points them to `/sitemap.xml` |
| `/sitemap.xml` | Lists every published article URL |

When adding a new article, run `bundle exec rake build` and verify `_site/sitemap.xml` contains the new article URL, `<lastmod>`, and image metadata when the article has a cover image.

## Deployment

Deployed to Cloudflare Pages via GitHub Actions on every push to `main`.

Required secrets in the GitHub repository:
- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
