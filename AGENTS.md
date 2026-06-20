# IT History Journal — Agent Instructions

## Growth orchestrator

When any discussion involves the `growth/` directory, the growth CLI, growth workflows, or audience/SEO/distribution strategy, read `growth/docs/orchestration.md` first before responding.

## Mandatory rules

- **Adding an instruction.** When asked to add or remember a reusable rule, create `.agents/{instruction-name}.md` and add a summary bullet to both `AGENTS.md` and `CLAUDE.md`. See `.agents/create-instruction.md`.
- **Update growth docs on every growth change.** Whenever you add or modify anything in `growth/` (CLI commands, workflows, clients, config fields), update `growth/docs/` to reflect it before finishing. See `.agents/update-growth-docs.md`.
- **README.md must stay current.** Whenever you add a script to `bin/` or a command to `dip.yml`, add a row to the relevant table in README.md before finishing the task.
- **Never use Wikipedia as a source.** Do not add Wikipedia URLs to the `sources:` list in any article. Use primary or authoritative references only. See `.agents/no-wikipedia-sources.md`.
- **Tests must pass.** Run `bundle exec rspec` after every change. All examples must be green.
- **Build must succeed.** Run `bundle exec rake build` after every task that involves code changes.

## Project overview

Ruby static site generator. Reads Markdown articles from `articles/`, renders HAML templates with Tailwind CSS, writes HTML to `_site/`. Deployed to Cloudflare Pages via GitHub Actions.

## Article layout on disk

```
articles/{lang}/{mon-dd}/{slug}/
  content.md    ← YAML frontmatter + Markdown body
  cover.webp    ← optional cover image (webp preferred)
```

`lang` is `en` or `ru`. `slug` uses underscores on disk, dashes in URLs.

## Adding a new article

1. Add the article under `articles/{lang}/{mon-dd}/{slug}/content.md`.
2. Include AIEO frontmatter when the facts are known: `event_date`, `event_year`, `topics`, `people`, `organizations`, `technologies`, and at least one `sources` entry with `title` and `url`.
3. Run `bundle exec rake build` so `_site/sitemap.xml` is regenerated with the new published article URL.
4. Verify `_site/sitemap.xml` contains the new article URL, `<lastmod>`, and cover image metadata when a cover exists before finishing.

## Key conventions

- **HAML 6 API**: `Haml::Template.new { source }.render(scope, locals)` — not `Haml::Engine.new(source)`.
- **Tailwind opacity classes**: never use `/` in HAML's inline class shorthand (e.g. `.text-white/60`). HAML treats `/` as a self-closing tag marker. Use the named aliases defined in `tailwind.config.js` (`text-white-60`, `border-white-10`, etc.) instead.
- **front_matter_parser v1**: `FrontMatterParser::Parser.new(:md).call(raw)`.
- **Custom colors** live in `tailwind.config.js` — always use them rather than raw hex or arbitrary Tailwind values.
- **Partials**: call `partial('name', locals_hash)` from inside any HAML template. The partial file must be named `_name.html.haml` in `templates/`.

## Adding a new dip command

1. Add the command block to `dip.yml` under `interaction:`.
2. Add a row to the **Commands** table in `README.md`.

## Adding a new script

1. Create the file in `bin/`, make it executable (`chmod +x`).
2. Add a row to the **Scripts** table in `README.md`.
3. If the script needs a system dependency (e.g. ImageMagick), add it to `.dockerdev/Dockerfile.dev`.

## Detailed instructions

### Article editing rules

When editing or preparing an article for publication, do not use H1 headings (`# Heading`) inside the article body. Use H2 (`##`) or lower for any section headings.

### How to add a new instruction

When the user asks to "add an instruction" or "remember that …" for a reusable rule:

1. **Create `.agents/{instruction-name}.md`** — write the full instruction there. Use a short kebab-case name that describes the rule (e.g. `updated-at-rule.md`).

2. **Add a bullet to `AGENTS.md`** under the relevant section (usually `## Mandatory rules`). Keep it one concise sentence; link or quote the key constraint. Example:
   ```
   - **Rule label.** Short description. See `.agents/instruction-name.md`.
   ```

3. **Add the same bullet to `CLAUDE.md`** under `## Mandatory rules` using identical wording so both files stay in sync.

The `.agents/` file holds the detailed rationale and edge cases; the bullet in `AGENTS.md` / `CLAUDE.md` is the actionable summary that is always in context.

## Running the project

```bash
bundle exec rspec           # tests
bundle exec rake build      # full build
bundle exec ruby bin/watch  # dev server + watcher on :4000
```
