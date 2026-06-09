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
excerpt: "Short summary shown in article cards."
popular: true
---

Article body in Markdown (GFM).
```

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
| `dip serve` | Build and serve at http://localhost:4000 |
| `dip watch` | Full build + file watcher + dev server at http://localhost:4000 |
| `dip convert_to_webp <file> [files...]` | Convert images to WebP format |
| `dip convert_covers` | Convert non-WebP covers to `cover.webp`, then generate `thumb.webp` (192×192) from each `cover.webp` |
| `dip shell` | Open a shell in the container |
| `dip bundle <args>` | Run bundler commands |

### Watch mode

`dip watch` does a full initial build (CSS + HTML), starts a server at http://localhost:4000, then listens for file changes:

- **`.md` changed** — rebuilds the affected article page + all index/calendar pages (~0.1s)
- **`.haml` changed** — rebuilds all HTML pages (~0.15s)
- **cover image added/changed** — rebuilds the article the image belongs to

### Scripts

| Script | Description |
|---|---|
| `bin/watch` | Underlying script for `dip watch` |
| `bin/convert_to_webp` | Convert images to WebP (requires ImageMagick; use `dip convert_to_webp` inside Docker) |
| `bin/convert_covers` | Phase 1: convert non-WebP covers to `cover.webp` and delete originals. Phase 2: generate `thumb.webp` (192×192) and `hero.webp` (576×384) from every `cover.webp` |

`bin/convert_to_webp` options:

| Flag | Default | Description |
|---|---|---|
| `-q`, `--quality N` | `80` | WebP quality 1–100 |
| `-w`, `--max-width N` | — | Resize to fit within this width |
| `-t`, `--thumb-only WxH` | — | Write a W×H centered crop to `thumb.webp` only — use `N` for a square or `WxH` for a rectangle (skips main output) |
| `-n`, `--thumb-name NAME` | `thumb.webp` | Override the output filename for `--thumb-only` |
| `--no-strip` | — | Keep EXIF metadata |

## RSS feeds

The build generates an RSS 2.0 feed for each language:

| URL | Feed |
|---|---|
| `/en/feed.xml` | English articles |
| `/ru/feed.xml` | Russian articles |

Feeds are regenerated automatically on every full build and every time an article is added or changed (watch mode).

## Deployment

Deployed to Cloudflare Pages via GitHub Actions on every push to `main`.

Required secrets in the GitHub repository:
- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
