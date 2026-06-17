# IT History Journal — Claude Instructions

## Mandatory rules

- **README.md must stay current.** Whenever you add a script to `bin/` or a command to `dip.yml`, document it in the README under the relevant table before finishing the task.
- **Run tests after every change.** Use `bundle exec rspec`. All 44+ examples must pass before reporting a task as done.
- **Run `bundle exec rake build` after every task that involves code changes** to confirm the site builds without errors.
- **Convert plain URLs to markdown links when preparing articles.** Any bare URL in the article body or links section must become `[Label](url)`. Use the site title or a short descriptive label — never leave a raw URL.

## Tech stack

- **Ruby static site generator** — `lib/builder.rb` builds `_site/` from HAML templates + Markdown articles.
- **HAML 6** — use `Haml::Template.new { src }.render(scope, locals)`. `Haml::Engine.new(src)` does not work in v6.
- **Tailwind CSS v3** via `tailwindcss-ruby` gem (standalone binary, no Node needed). Custom colors defined in `tailwind.config.js`. Avoid `/` opacity modifiers in HAML class shorthand (e.g. `text-white/60`) — HAML parses `/` as a self-closing tag marker. Use named colors like `text-white-60` instead.
- **front_matter_parser v1** — use `FrontMatterParser::Parser.new(:md).call(raw)`, not `parse_str`.
- **mini_magick** for image conversion — requires ImageMagick; use `dip convert_to_webp` inside Docker.

## Article structure

```
articles/{lang}/{mon-dd}/{slug}/
  content.md    ← frontmatter + body
  cover.webp    ← optional cover (webp preferred over png/jpg)
```

Slug is derived from the directory name (`james_gosling_was_born` → `james-gosling-was-born`).

## Color system

Dark theme using Patreon-sourced colors defined in `tailwind.config.js`:

| Name | Value | Use |
|---|---|---|
| `page` | `#000000` | Page background |
| `card` | `#000000` | Card surface |
| `raised` | `#282626` | Hover surface |
| `accent` | `#e9def3` | Active links, badge text |
| `accent-muted` | `#c0b4ce` | Nav links, secondary text |
| `accent-dim` | `#55515a` | Badge backgrounds |
| `white-10` … `white-60` | rgba values | Translucent white utilities |

## Key files

| File | Purpose |
|---|---|
| `lib/article.rb` | Parses articles from disk |
| `lib/builder.rb` | Builds `_site/` |
| `lib/render_scope.rb` | HAML rendering scope; provides `partial(name, locals)` |
| `templates/layout.html.haml` | Full page HTML wrapper |
| `templates/index.html.haml` | Index page content |
| `templates/article.html.haml` | Article page content |
| `templates/_article_card.html.haml` | Article card partial |
| `templates/_calendar_widget.html.haml` | Sidebar calendar partial |
| `templates/calendar.html.haml` | Full calendar page |
| `bin/watch` | Dev server + incremental rebuilds |
| `bin/convert_to_webp` | Image → WebP conversion |

## Development commands

```bash
bundle exec rspec          # run tests
bundle exec rake build     # full build (CSS + HTML)
bundle exec ruby bin/watch # dev server on :4000 + file watching
dip rspec                  # tests inside Docker
dip build                  # build inside Docker
dip watch                  # dev server inside Docker
dip convert_to_webp <img>  # convert image to WebP inside Docker
```
