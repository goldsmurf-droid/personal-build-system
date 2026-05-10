# Lean Machine Augmentation Design

**Date:** 2026-05-10
**Status:** approved
**Scope:** Extend personal-build-system from "working thing on VM" to "shipped thing in the world" with ongoing lifecycle management and idea capture.

---

## Overview

The existing pipeline takes an idea to a working product running on a dev VM. This design adds three missing pieces:

1. **`ship` skill** — one command from working-on-VM to deployed-on-Azure-App-Service, with DNS and cost management
2. **`backlog` skill** — cross-project SPEC.md management for backlogs, bugs, and build targets
3. **`idea-capture-prompt.md`** — a Phase 0 Claude.ai Project prompt for mobile voice ideation that produces consistent input into the pipeline

Plus the doc updates required to keep the repo usable by others.

---

## Section 1 — Architecture & Placement

### New files

```
personal-build-system/
  .claude/
    skills/
      ship.md           ← new: deploy to Azure App Service
      backlog.md        ← new: cross-project SPEC.md management
  idea-capture-prompt.md  ← new: Phase 0 mobile capture prompt
  docs/
    superpowers/
      specs/
        2026-05-10-lean-machine-augmentation-design.md  ← this file
```

### Updated files

```
  infra-defaults.md     ← add dns, cost, and registrar fields
  README.md             ← add Phase 0, Phase 7, Phase 8; update iteration loop
  ONBOARDING.md         ← add domain setup, DNS credentials, idea capture steps
```

### Design principles

Both skills are Claude Code instruction documents — markdown files that tell Claude what to do. Claude drives the `az` CLI, DNS provider APIs, and file edits. No shell scripts, no daemons, no new runtime dependencies beyond the `az` CLI already required by `full-bootstrap.sh`.

Skills read configuration from `~/personal-build-system/infra-defaults.md`. This makes them portable: anyone who forks the repo and fills in their own `infra-defaults.md` gets working skills.

---

## Section 2 — `ship` skill

### Purpose

Take a project that works on the dev VM and make it accessible to real users at a real URL.

### Invocation

Run from inside the project directory (`~/projects/active/<slug>/`):

- `/ship uat` — first deploy: provision Azure resources, deploy code, bind `<slug>.<your-domain>` as the UAT URL
- `/ship live` — promote to production: add a dedicated domain as a second custom domain on the same App Service, update DNS, update docs

### Flow — `/ship uat`

1. Read `~/personal-build-system/infra-defaults.md` for subscription, resource group prefix, region, DNS provider, domain, alert email, and monthly budget
2. Read project `SPEC.md` for slug, language/runtime, port
3. Read `run.md` for the start command
4. Provision Azure resources (all steps idempotent — skip if already exists):
   - Shared resource group: `rg-personal-shared` (created once, survives across projects)
   - App Service Plan: `plan-personal-<region>` in `rg-personal-shared`
   - Per-project resource group: `rg-<slug>-personal`
   - Web App: `app-<slug>-personal` in `rg-<slug>-personal`
5. Tag all resources: `project=<slug>`, `env=uat`, `owner=<github-username>`, `managed-by=personal-build-system`
6. Deploy via `az webapp up`
7. Bind custom domain `<slug>.<domain>` via DNS provider (see DNS section below)
8. Create Azure Budget scoped to `rg-<slug>-personal`: amount from `infra-defaults.md`, alerts at 80% and 100% to alert email
9. Write `## Production` section to `run.md` with UAT URL
10. Update `SPEC.md` frontmatter: `status: active`, `uat-url: https://<slug>.<domain>`

### Flow — `/ship live`

1. Prompt for dedicated domain if not in `SPEC.md` frontmatter
2. Add dedicated domain as second custom domain on existing App Service (no new infra, no re-deploy)
3. Configure DNS for dedicated domain via DNS provider
4. Update `SPEC.md` frontmatter: `live-url: https://<dedicated-domain>`
5. Update `run.md` Production section with both URLs

### DNS provider abstraction

`infra-defaults.md` specifies `dns-provider:` — one of `namecheap`, `cloudflare`, or `manual`.

| Provider | Mechanism |
|----------|-----------|
| `namecheap` | Namecheap XML API. Requires `NAMECHEAP_API_USER` and `NAMECHEAP_API_KEY` in `.env` |
| `cloudflare` | Cloudflare REST API. Requires `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ZONE_ID` in `.env` |
| `manual` | Skill outputs the exact DNS record(s) to configure. User does it in their registrar UI. No credentials needed. |

The `manual` option is the zero-configuration fallback. Anyone who doesn't want to set up API credentials can still use `ship` — they just do the DNS step themselves.

### Azure best practices enforced

- **Per-project resource groups** — clean teardown via `az group delete --name rg-<slug>-personal`
- **Shared App Service Plan** — cost-efficient, one plan per region across all projects, lives in `rg-personal-shared` which is created once on first `/ship uat` call
- **Consistent tagging** — enables cost analysis by project in Azure Cost Analysis (group by `project` tag)
- **Per-project budget** — automated alerts prevent runaway spend; configured at provision time
- **Naming convention** — `rg-`, `plan-`, `app-` prefixes; `-personal` suffix for disambiguation

### infra-defaults.md additions

```markdown
## DNS
dns-provider: namecheap   # namecheap | cloudflare | manual
domain: yourdomain.com    # base domain for <slug>.yourdomain.com UAT URLs

## Cost
monthly-budget-per-project: 20   # USD; alerts fire at 80% and 100%
alert-email: your@email.com
```

Corresponding `.env.example` additions:

```
# DNS (only required for your dns-provider)
NAMECHEAP_API_USER=
NAMECHEAP_API_KEY=
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ZONE_ID=
```

---

## Section 3 — `backlog` skill

### Purpose

Manage backlogs, known issues, and build targets across all active projects without leaving the CLI or opening individual files.

### Invocation

Can be run from anywhere.

| Command | Behavior |
|---------|----------|
| `/backlog` | Dashboard: lists all active projects with current build target and backlog item count |
| `/backlog <slug>` | Full view of that project's backlog, known issues, and current build target. Prompts for actions. |
| `/backlog <slug> add "<item>"` | Appends item to `## Backlog` in that project's `SPEC.md` |
| `/backlog <slug> bug "<description>"` | Appends item to `## Known issues` in that project's `SPEC.md` |
| `/backlog <slug> target "<item>"` | Sets `## Current build target` in that project's `SPEC.md`, replacing whatever was there |

### Implementation

Pure SPEC.md manipulation. The skill scans `~/projects/active/*/SPEC.md`, parses the relevant sections, and makes targeted edits. No new files, no database, no external dependencies.

### Consistency with existing workflow

The iteration loop in `README.md` (currently manual edits to SPEC.md) is unchanged. `/backlog` is an accelerator for that loop, not a replacement. Both work; use whichever is faster in context.

---

## Section 4 — Doc updates

All updates are required before this work is considered done. The repo is public and intended for others to fork — incomplete docs make the new features invisible.

### `infra-defaults.md`

- Add `## DNS` section (fields above)
- Add `## Cost` section (fields above)
- Remove Namecheap-specific references from any hardcoded positions

### `README.md`

- Add **Phase 0 — Capture** before Phase 1, referencing `idea-capture-prompt.md`
- Add **Phase 7 — Ship (UAT)**: `cd ~/projects/active/<slug>` then `/ship uat`
- Add **Phase 8 — Ship (Live)**: `/ship live` once UAT passes
- Update **Iteration** section: add `/backlog` as the CLI path for managing SPEC.md backlog/bugs
- Add `/backlog` and `/ship` to the **What's in this repo** table

### `ONBOARDING.md`

- Add a step between current steps 6 and 7: **Set up your domain and DNS credentials** — explains the three DNS provider options, how to get API credentials for Namecheap or Cloudflare, or how to use `manual` mode
- Add a step: **Try `/backlog`** after the first project is built
- Mention `idea-capture-prompt.md` in the Claude Project setup step (Step 8): create a second project for idea capture, separate from the Spec Builder

---

## Section 5 — Idea capture (Phase 0)

### Purpose

Bridge the gap between voice ideation on Claude.ai mobile and the structured pipeline. Ideas captured in conversation should not require reformatting before they can enter the Spec Builder.

### `idea-capture-prompt.md`

A Claude.ai Project system prompt, analogous to `spec-builder-prompt.md`. Optimized for mobile voice: no interrogation, just structured capture.

**Behavior:** User describes an idea in natural language (spoken or typed). The project responds with a single structured idea card — no back-and-forth.

**Output format:**

```
---
title: <short slug-friendly name>
captured: <today's date>
status: idea
---

## The idea
<one paragraph — what it is and what it does>

## Problem it solves
<one sentence>

## Rough happy path
<one sentence — subject does X, result is Y>

## Open questions
- <question 1>
- <question 2>
- <question 3>
```

**V1 workflow:**
1. Talk to the Capture project on mobile
2. Copy the idea card output
3. Paste into `~/projects/ideas/<slug>.md` on VM (create `ideas/` dir at project root level)
4. When ready: use the card as input to the Spec Builder (Phase 3)

### Future (out of scope for v1)

An intake endpoint or minimal web UI accepting idea cards from a browser form or Claude.ai skill — no CLI required. Noted here so the v1 file format is designed to be machine-readable when that work is picked up.

---

## Out of scope

- Multi-user or team features
- CI/CD pipelines (GitHub Actions, etc.)
- Container-based deployment (App Service native runtime is sufficient for the default Python/Node stack)
- Registrar support beyond Namecheap, Cloudflare, and manual
- Automated idea sync (v2 of Phase 0)

---

## Done criteria

- `.claude/skills/ship.md` exists and is accurate
- `.claude/skills/backlog.md` exists and is accurate
- `idea-capture-prompt.md` exists and produces the correct output format when pasted into a Claude Project
- `infra-defaults.md` has DNS and Cost sections with correct field names
- `README.md` has Phase 0, Phase 7, Phase 8, and updated iteration loop
- `ONBOARDING.md` has domain/DNS setup step and idea capture step
- All new `.env.example` keys are documented
- Repo is forkable and usable by someone who is not Ryan
