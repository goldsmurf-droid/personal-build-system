# Backlog — Cross-Project SPEC.md Manager

Manage backlogs, known issues, and build targets across all active projects without editing files manually.

## Usage

| Command | Behavior |
|---------|----------|
| `/backlog` | Dashboard: list all projects in `~/projects/active/` with current build target and backlog item count |
| `/backlog <slug>` | Full view of one project's backlog, known issues, and current build target. Prompts for an action. |
| `/backlog <slug> add "<item>"` | Append item to `## Backlog` in that project's `SPEC.md` |
| `/backlog <slug> bug "<description>"` | Append item to `## Known issues` in that project's `SPEC.md` |
| `/backlog <slug> target "<item>"` | Replace the content of `## Current build target` with the given item |

All operations edit `~/projects/active/<slug>/SPEC.md` directly. No new files, no database.

---

## Implementation

### `/backlog` — dashboard

Scan:
```bash
ls ~/projects/active/
```

For each directory that contains a `SPEC.md`:
1. Read `## Current build target` — first non-empty, non-heading line after the heading (or `(none)` if absent/empty)
2. Count `- ` bullet lines under `## Backlog` (or `0` if section absent)

Display as a formatted table:
```
Project            Current build target               Backlog
────────────────   ────────────────────────────────   ───────
my-project         Add CSV export                     3 items
another-project    (none)                             0 items
```

If `~/projects/active/` is empty or no `SPEC.md` files found:
```
No active projects found in ~/projects/active/
```

### `/backlog <slug>` — project view

Verify `~/projects/active/<slug>/SPEC.md` exists. If not, list available slugs:
```bash
ls ~/projects/active/
```
Then exit.

Display the content of these three sections from `SPEC.md`:
- `## Current build target`
- `## Backlog`
- `## Known issues`

Then prompt:
```
Actions:
  [a] Add backlog item
  [b] Log a bug (known issue)
  [t] Set build target
  [q] Quit

Choice:
```

Execute the chosen action (same logic as the explicit commands below), then return to the prompt until `[q]`.

### `/backlog <slug> add "<item>"`

In `~/projects/active/<slug>/SPEC.md`:

1. Find `## Backlog`. If absent, append to end of file:
   ```
   ## Backlog
   ```
2. Append under the section:
   ```
   - <item>
   ```

### `/backlog <slug> bug "<description>"`

In `~/projects/active/<slug>/SPEC.md`:

1. Find `## Known issues`. If absent, append to end of file:
   ```
   ## Known issues
   ```
2. Append under the section:
   ```
   - <description>
   ```

### `/backlog <slug> target "<item>"`

In `~/projects/active/<slug>/SPEC.md`:

1. Find `## Current build target`. If absent, append to end of file.
2. Replace everything between the `## Current build target` heading and the next `##` heading (or end of file) with `<item>`.

Result:
```markdown
## Current build target

<item>
```

---

## Notes

- The manual SPEC.md iteration loop in `README.md` still works. `/backlog` is an accelerator, not a replacement.
- These are the same SPEC.md sections Claude Code reads when you invoke `claude "Read SPEC.md. Build the current build target only."` — changes via `/backlog` are immediately picked up.
