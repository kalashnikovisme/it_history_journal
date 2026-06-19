---
name: update-growth-docs
description: Require updating growth/docs/ whenever growth features are changed
metadata:
  type: feedback
---

When making any code change to the `growth/` directory — new workflows, new CLI commands, new clients, new config fields, changed behavior — update the relevant docs in `growth/docs/` before finishing the task.

**Why:** The growth system is designed to be an autonomous orchestrator. Its docs (especially `orchestration.md`) define agent roles, capabilities, and the execution model. If code drifts from the docs, future agents and humans reading the docs will have a wrong picture of what the system can do.

**How to apply:**
- New CLI command → document it in the CLI Interface section of `orchestration.md` (or the relevant doc file).
- New workflow or agent capability → add or update the agent's responsibility section.
- New config field → mention it in context where the feature is described.
- New external integration (e.g. analytics API, GA4) → document it as a data source the Analytics Agent can use.
- If no existing doc section fits, add a new section rather than skipping the update.
