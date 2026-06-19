# How to add a new instruction

When the user asks to "add an instruction" or "remember that …" for a reusable rule:

1. **Create `.agents/{instruction-name}.md`** — write the full instruction there. Use a short kebab-case name that describes the rule (e.g. `updated-at-rule.md`).

2. **Add a bullet to `AGENTS.md`** under the relevant section (usually `## Mandatory rules`). Keep it one concise sentence; link or quote the key constraint. Example:
   ```
   - **Rule label.** Short description. See `.agents/instruction-name.md`.
   ```

3. **Add the same bullet to `CLAUDE.md`** under `## Mandatory rules` using identical wording so both files stay in sync.

The `.agents/` file holds the detailed rationale and edge cases; the bullet in `AGENTS.md` / `CLAUDE.md` is the actionable summary that is always in context.
