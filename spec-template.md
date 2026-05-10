---
slug: <project-slug>
status: active
created: <YYYY-MM-DD>
---

# <Project Name>

## What this is

One paragraph. Functional boundary. What it does. What it explicitly does NOT do.

## Invocation

The exact interface. CLI signature with all flags, or HTTP endpoint, or import pattern.
Literal, not aspirational. Include an example invocation.

```bash
# Example
python src/main.py --input <file> --output <dir>
```

## Inputs / Outputs

What goes in, what comes out, what format.
Source of input (user, file, API, stdin).
Form of output (stdout, file, side effect).
If there's persistence: what, where, in what format.

## Happy path

Numbered steps. End-to-end. What the user does, what the system does, in sequence.
This is the primary build target.

1. User does X
2. System does Y
3. System outputs Z
4. User sees W

## Edge cases

- [condition] → [behavior]
- [condition] → [behavior]
- [condition] → [behavior]

## Stack

Deviations from defaults only. If it matches stack-defaults.md, omit it.

Example deviations:
- Uses SQLite instead of file-based state (reason: relational queries needed)
- Requires auth: API key via env var `SERVICE_API_KEY`
- Hosted on VM, not local (reason: needs to be always-on)

## File structure

Literal directory tree Claude Code should create.

```
<slug>/
  src/
    main.py
    <other modules>
  tests/
    test_smoke.py
  data/             # omit if no persistence
  SPEC.md
  claude.md
  run.md
  README.md
  requirements.txt
  .env.example
  .gitignore
```

## Smoke test

What to run. What "pass" looks like. Explicit enough that pass/fail is unambiguous.

```bash
pytest tests/test_smoke.py -v
```

Expected output:
- `test_happy_path` — PASSED
- `test_<edge_case_1>` — PASSED
- `test_<edge_case_2>` — PASSED

## Out of scope

Things that might seem implied but are not in this build.

- No web UI — CLI only
- No multi-user support
- No authentication
- No logging beyond stderr
- No retry logic on [X]

---

## Backlog

*(added post-initial-build — leave blank at first)*

- [ ] Feature: ...
- [ ] Feature: ...

## Known issues

*(added post-initial-build — leave blank at first)*

- [ ] Bug: ... — severity: breaks it / degrades it / annoys me

## Current build target

*(used during iteration only — leave blank at initial build)*

One item. What Claude Code is doing right now.
