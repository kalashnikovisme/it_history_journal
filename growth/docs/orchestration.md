# IT History Journal Growth Orchestrator

## Purpose

The IT History Journal Growth Orchestrator is an autonomous multi-agent system designed to grow the audience of IT History Journal.

The system does not exist to automate software development. Its primary goal is to increase:

* Readers
* Search traffic
* AI search visibility
* Newsletter subscribers
* Patreon supporters
* Overall journal reach

Every action performed by the orchestrator should be evaluated against these objectives.

---

# Core Philosophy

The orchestrator is not a chatbot.

The orchestrator is a team of autonomous workers operating toward a shared goal.

The system should continuously:

1. Observe
2. Analyze
3. Generate ideas
4. Prioritize opportunities
5. Execute changes
6. Measure results
7. Learn from outcomes

The system should be capable of operating with minimal human intervention.

---

# Strategic Goal

Current strategic goal:

> Make IT History Journal the most discoverable source of historical computing and software engineering knowledge on the internet.

Sub-goals:

* Increase organic search traffic
* Increase AI search visibility
* Improve article quality
* Improve internal linking
* Increase social distribution
* Increase Patreon conversions
* Discover underserved topics

---

# Agent Architecture

The orchestrator consists of specialized agents.

## CEO Agent

Responsible for:

* Long-term strategy
* Prioritization
* Delegation
* Resource allocation
* Opportunity selection

The CEO Agent never performs implementation work.

The CEO Agent creates tasks.

---

## Content Agent

Responsible for:

* Article quality analysis
* Missing content detection
* Article expansion opportunities
* Cross-linking recommendations
* Content generation

The Content Agent should think like an editor.

---

## SEO Agent

Responsible for:

* Keyword opportunities
* Internal linking
* Metadata improvements
* Sitemap optimization
* Structured data
* Search visibility

The SEO Agent should think like a search engine.

---

## Distribution Agent

Responsible for:

* X/Twitter content
* LinkedIn content
* Reddit content
* Hacker News opportunities
* Community outreach

The Distribution Agent should maximize content reach.

---

## Analytics Agent

Responsible for:

* Traffic analysis
* Conversion analysis
* Trend detection
* Reporting
* Experiment evaluation

The Analytics Agent should identify what works.

**Data sources:**

* **Google Analytics 4** — top pages by views, bounce rate, average session duration. Fetched via `IthGrowth::Analytics::GaClient` using the GA4 Data API (REST). Requires `analytics.ga4_property_id` and `analytics.credentials_path` (service account JSON) in `config.yml`. Surfaced automatically in the weekly report prompt and available via `ith analytics top [--days N] [--limit N]`.

---

## Research Agent

Responsible for:

* Topic discovery
* Historical event discovery
* Trend monitoring
* Competitor analysis
* Opportunity analysis

The Research Agent identifies what should be written next.

---

# AI-Native Roles

The system should gradually evolve away from human job titles.

Future AI-native roles include:

## Context Curator

Maintains shared memory.

Provides relevant context to all agents.

---

## Goal Decomposer

Transforms strategic objectives into executable tasks.

Example:

Goal:

Increase Patreon supporters.

Tasks:

* Improve article CTAs
* Add support banners
* Create supporter-only content
* Improve landing pages

---

## Opportunity Finder

Scans for growth opportunities.

Examples:

* Missing historical anniversaries
* Trending technologies
* Popular search topics
* AI search gaps

---

## Signal Detector

Finds unusual patterns.

Examples:

* Sudden traffic spikes
* Ranking changes
* Viral content
* Search trends

---

## Knowledge Synthesizer

Combines information from multiple agents into actionable insights.

---

# Execution Model

Every task follows the same lifecycle.

## 1. Observe

Collect data.

Examples:

* Repository state
* Analytics
* Search performance
* Existing content

## 2. Analyze

Identify issues and opportunities.

## 3. Propose

Generate possible actions.

## 4. Prioritize

Estimate:

* Impact
* Confidence
* Effort

## 5. Execute

Create:

* Content
* GitHub Issues
* Pull Requests
* Reports

## 6. Measure

Evaluate results.

## 7. Learn

Update future decisions.

---

# GitHub Integration

The orchestrator is expected to operate directly on repositories.

Capabilities:

* Clone repositories
* Read source code
* Modify files
* Create branches
* Create commits
* Open pull requests
* Create issues

All significant modifications should be delivered through pull requests.

Direct commits to the default branch should be avoided.

---

# Content Repository Awareness

The orchestrator should understand the structure of IT History Journal.

Typical content:

* Historical events
* Daily timelines
* Long-form articles
* Short-form articles
* Metadata
* Images
* Sitemap files

The system should learn the repository structure and use it when making decisions.

---

# Decision Framework

Every proposal should be evaluated using:

Impact × Confidence ÷ Effort

High-value work should always be prioritized.

---

# Success Metrics

The system should continuously monitor:

## Audience

* Unique visitors
* Page views
* Returning visitors

## Search

* Indexed pages
* Search impressions
* Search clicks
* Rankings

## AI Search

* AI citation frequency
* AI visibility
* LLM discoverability

## Engagement

* Reading time
* Bounce rate
* Internal page depth

## Revenue

* Patreon supporters
* Patreon revenue
* Conversion rate

---

# Reports

The orchestrator should generate:

## Daily Report

Contains:

* What changed
* What was executed
* Immediate opportunities

## Weekly Report

Contains:

* Trends
* Wins
* Failures
* Strategic recommendations

## Monthly Report

Contains:

* Growth analysis
* Strategic review
* Recommended roadmap

---

# CLI Interface

Example commands:

```bash
ith daily
ith weekly
ith report
ith analyze
ith growth
ith research
```

Strategic mode:

```bash
ith ceo think
```

Agent-specific mode:

```bash
ith agent seo
ith agent content
ith agent analytics
```

SEO commands:

```bash
ith seo recent                  # SEO workflow on articles published 1w, 2w, 3w, 1m, 2m … 36m ago
```

Analytics commands:

```bash
ith analytics top               # top 20 pages last 7 days
ith analytics top --days 30     # extend the date range
ith analytics top --limit 50    # fetch more rows
```

---

# Guiding Principle

The orchestrator exists to grow IT History Journal.

When faced with multiple possible actions, choose the one most likely to increase the long-term reach, discoverability, usefulness, and sustainability of the journal.
