# IT History Journal

A static site publishing daily articles about IT history, one event per day of the year.

Published at [history.purple-magic.com](https://history.purple-magic.com). Available in English and Russian — the language is chosen automatically based on browser settings.

## Structure

- `articles/en/<mon-dd>/<slug>.md` — English articles
- `articles/ru/<mon-dd>/<slug>.md` — Russian articles
- `templates/` — HAML page templates
- `lib/` — Ruby build scripts
- `spec/` — RSpec tests

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

`articles/en/may-19/james_gosling_was_born.md` → `/en/may-19/james-gosling-was-born`

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
| `dip shell` | Open a shell in the container |
| `dip bundle <args>` | Run bundler commands |

## Deployment

Deployed to Cloudflare Pages via GitHub Actions on every push to `main`.

Required secrets in the GitHub repository:
- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
