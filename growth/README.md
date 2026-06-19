# IT History Growth Orchestrator

Terminal-first Ruby control plane for growing IT History Journal traffic and converting more readers into Patreon and Boosty supporters.

The app generates inspectable drafts and reports. It does not publish automatically.

## Setup

### With dip (recommended)

Install dip:

```bash
# macOS / Linux (Homebrew)
brew tap bibendi/dip
brew install dip

# Any OS with Ruby
gem install dip
```

Then provision and run:

```bash
# Set your API keys in the environment, then:
dip provision
```

Daily workflow:

```bash
dip ith help                        # run any ith command
dip ith article promote path/to/article.md
dip test                            # run tests
dip shell                           # open a shell in the container
dip bundle exec rake test           # run tests via bundler directly
```

Pass API keys at runtime (nothing is stored in the container):

```bash
OPENAI_API_KEY=sk-... dip ith article promote examples/sample-article.md
ITH_GROWTH_CONFIG=config/config.fake.yml dip ith article promote examples/sample-article.md
```

### Without dip

```bash
bundle install
bin/ith init
```

Edit `config/config.yml`. The example config uses OpenAI. For local dry runs without API keys, use `config/config.fake.yml`.

Environment variables:

```bash
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
ITH_GROWTH_CONFIG=config/config.yml
```

## Commands

```bash
bin/ith help
bin/ith init
bin/ith articles list
bin/ith article analyze path/to/article.md
bin/ith article promote path/to/article.md
bin/ith seo suggest path/to/article.md
bin/ith distribution generate path/to/article.md
bin/ith conversion path/to/article.md
bin/ith workflow run daily
bin/ith workflow run weekly
bin/ith report weekly
```

## Outputs

Distribution drafts (per-platform Markdown files) are written to the project root:

```text
distribution/articles/<lang>/<mon>/<dd>/<slug>/<platform>.md
```

Other article outputs (analysis, SEO, conversion) are written under:

```text
growth/output/articles/<article-slug>/
```

Logs are JSON lines under:

```text
growth/output/logs/YYYY-MM-DD.log
```

Reports are written to:

```text
growth/output/reports/daily/YYYY-MM-DD.md
growth/output/reports/weekly/YYYY-WW.md
```

The `growth/output/` directory is gitignored. The `distribution/` directory at the project root is tracked in git.

## Example Workflow

```bash
bin/ith article promote ../history-site/content/articles/example.md
```

This runs analysis, distribution drafts, SEO suggestions, and Patreon/Boosty conversion suggestions.

Local fake-provider demo:

```bash
ITH_GROWTH_CONFIG=config/config.fake.yml bin/ith article promote examples/sample-article.md
```

## AI Providers

Set `ai.provider` to `fake`, `openai`, or `anthropic`.

To add another provider:

1. Create `lib/ith_growth/ai/<provider>_client.rb`.
2. Implement `complete(prompt:, system: nil, model: nil, temperature: 0.4)`.
3. Add the provider to `IthGrowth::CLI.context`.

## Distribution Platforms

Distribution platforms live in `IthGrowth::Workflows::DistributionWorkflow::PLATFORMS`. Add the platform name there, then tune `lib/ith_growth/prompts/distribution.md` if it needs special rules.

## Future Integrations

This project keeps workflows independent from the CLI so it can later plug into GitHub issues, GitHub PRs, Paperclip AI, n8n, or a small web dashboard. The likely next step is a GitHub adapter that turns generated suggestions into reviewable issues or pull requests.

## Tests

```bash
# With dip
dip test

# Without dip
bundle exec rake test
```
