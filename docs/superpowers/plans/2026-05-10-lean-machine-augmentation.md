# Lean Machine Augmentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend personal-build-system with a `ship` skill (Azure App Service deploy + DNS + cost management), a `backlog` skill (cross-project SPEC.md management), an idea-capture prompt for mobile voice, and full doc updates so the repo is usable by someone who is not Ryan.

**Architecture:** All new deliverables are markdown instruction files (Claude Code skills) or Claude.ai Project prompts — no runtime code, no new dependencies beyond `az` CLI. Skills read from `infra-defaults.md` for portability. Doc updates wire superpowers into the install path and every lifecycle phase.

**Tech Stack:** Azure CLI (`az`), Namecheap XML API, Cloudflare REST API, Claude Code skill system (`.claude/skills/`), markdown.

**Spec:** `docs/superpowers/specs/2026-05-10-lean-machine-augmentation-design.md`

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `.claude/skills/ship.md` | Deploy to Azure App Service |
| Create | `.claude/skills/backlog.md` | Cross-project SPEC.md management |
| Create | `idea-capture-prompt.md` | Phase 0 mobile voice capture prompt |
| Create | `.env.example` | DNS credential keys (no values) |
| Modify | `infra-defaults.md` | Add DNS and Cost sections |
| Modify | `full-bootstrap.sh` | Add superpowers to Next Steps output |
| Modify | `README.md` | Add Phase 0/7/8, update Phase 4, update iteration loop and table |
| Modify | `ONBOARDING.md` | Add superpowers install, domain/DNS, two-project Claude setup |
| Modify | `stack-defaults.md` | Note Azure App Service as Tier 2 hosting via `/ship` |
| Modify | `spec-builder-prompt.md` | Add forker personalization note |

**Verification pattern:** Since all deliverables are markdown/config files, tests are `grep` acceptance checks run before and after each task.

---

## Task 1: Scaffold — create `.claude/skills/` and `.env.example`

**Files:**
- Create: `.claude/skills/` (directory)
- Create: `.env.example`

- [ ] **Step 1: Verify neither exists yet**

```bash
ls .claude/skills/ 2>&1 && echo "EXISTS — skip mkdir" || echo "MISSING — will create"
test -f .env.example && echo "EXISTS — skip" || echo "MISSING — will create"
```

- [ ] **Step 2: Create the skills directory**

```bash
mkdir -p .claude/skills
```

- [ ] **Step 3: Create `.env.example`**

```bash
cat > .env.example << 'EOF'
# DNS credentials — set the keys for your chosen dns-provider (see infra-defaults.md)
# Only the section for your provider is required. Delete the others.

# Namecheap (dns-provider: namecheap)
NAMECHEAP_API_USER=
NAMECHEAP_API_KEY=

# Cloudflare (dns-provider: cloudflare)
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ZONE_ID=
EOF
```

- [ ] **Step 4: Verify**

```bash
ls .claude/skills/
grep -q "NAMECHEAP_API_USER" .env.example && echo "PASS" || echo "FAIL"
grep -q "CLOUDFLARE_API_TOKEN" .env.example && echo "PASS" || echo "FAIL"
```

Expected: directory exists, both PASS.

- [ ] **Step 5: Commit**

Note: git doesn't track empty directories. Don't commit the skills dir yet — it will be committed when `ship.md` is added in Task 4.

```bash
git add .env.example
git commit -m "feat: scaffold .claude/skills dir and .env.example"
```

---

## Task 2: Update `infra-defaults.md`

**Files:**
- Modify: `infra-defaults.md`

- [ ] **Step 1: Verify sections don't exist yet**

```bash
grep -q "## DNS" infra-defaults.md && echo "EXISTS" || echo "MISSING — will add"
grep -q "## Cost" infra-defaults.md && echo "EXISTS" || echo "MISSING — will add"
```

Expected: both MISSING.

- [ ] **Step 2: Append DNS and Cost sections**

Open `infra-defaults.md` and append the following to the end of the file:

```markdown

---

## DNS

- dns-provider: manual   # manual | namecheap | cloudflare
- domain:                # base domain for <slug>.yourdomain.com UAT URLs (e.g. yourdomain.com)

---

## Cost

- monthly-budget-per-project: 20   # USD; budget alerts fire at 80% and 100%
- alert-email:                     # email address for Azure budget alerts
```

- [ ] **Step 3: Verify**

```bash
grep -q "dns-provider" infra-defaults.md && echo "PASS dns-provider" || echo "FAIL"
grep -q "domain:" infra-defaults.md && echo "PASS domain" || echo "FAIL"
grep -q "monthly-budget-per-project" infra-defaults.md && echo "PASS budget" || echo "FAIL"
grep -q "alert-email" infra-defaults.md && echo "PASS alert-email" || echo "FAIL"
```

Expected: all PASS.

- [ ] **Step 4: Commit**

```bash
git add infra-defaults.md
git commit -m "feat: add DNS and Cost sections to infra-defaults"
```

---

## Task 3: Create `idea-capture-prompt.md`

**Files:**
- Create: `idea-capture-prompt.md`

- [ ] **Step 1: Verify file doesn't exist**

```bash
test -f idea-capture-prompt.md && echo "EXISTS" || echo "MISSING — will create"
```

- [ ] **Step 2: Create the file**

Write `idea-capture-prompt.md` with this exact content:

```markdown
# Idea Capture — System Prompt

> Paste this entire file as the system prompt for a Claude.ai Project named "Idea Capture".
> This project is separate from your Spec Builder — it is faster and does not interrogate.
> If you forked this repo, no changes are needed to this file.

---

You are an idea capture assistant for a personal software build pipeline.

When someone describes an idea to you — in any format, spoken or typed, rough or polished — your job is to output exactly one structured idea card and nothing else. No questions, no conversation, no commentary. Just the card.

The card format is:

---
title: <short slug-friendly name, 2-4 words, lowercase-hyphenated>
captured: <today's date, YYYY-MM-DD>
status: idea
---

## The idea
<One paragraph. What it is and what it does. Written in plain language. No jargon.>

## Problem it solves
<One sentence. What frustration or gap does this address?>

## Rough happy path
<One sentence. Subject does X, system does Y, result is Z.>

## Open questions
- <First obvious unknown>
- <Second obvious unknown>
- <Third obvious unknown>

---

If the idea is too vague to fill in a section, make your best inference and mark it with "(inferred)" — do not ask for clarification.

After outputting the card, say nothing else.
```

- [ ] **Step 3: Verify**

```bash
grep -q "Idea Capture" idea-capture-prompt.md && echo "PASS title" || echo "FAIL"
grep -q "status: idea" idea-capture-prompt.md && echo "PASS status field" || echo "FAIL"
grep -q "Rough happy path" idea-capture-prompt.md && echo "PASS happy path" || echo "FAIL"
grep -q "Open questions" idea-capture-prompt.md && echo "PASS open questions" || echo "FAIL"
grep -q "say nothing else" idea-capture-prompt.md && echo "PASS no-commentary rule" || echo "FAIL"
```

Expected: all PASS.

- [ ] **Step 4: Commit**

```bash
git add idea-capture-prompt.md
git commit -m "feat: add idea-capture-prompt for Phase 0 mobile voice capture"
```

---

## Task 4: Create `.claude/skills/ship.md`

**Files:**
- Create: `.claude/skills/ship.md`

- [ ] **Step 1: Verify file doesn't exist**

```bash
test -f .claude/skills/ship.md && echo "EXISTS" || echo "MISSING — will create"
```

- [ ] **Step 2: Create the file**

Write `.claude/skills/ship.md` with this exact content:

````markdown
# Ship — Deploy to Azure App Service

Announce at start: "I'm using the ship skill to deploy **[slug from SPEC.md]** to Azure App Service."

## Purpose

Take a project that works on the dev VM and make it accessible at a real URL. Handles Azure provisioning, deployment, DNS, TLS, cost management, and doc updates in one pass.

## Prerequisites

Before starting, verify all of the following. Stop and tell the user what to fix if anything is missing.

- Azure CLI installed: `az --version`
- Azure CLI logged in: `az account show`
- Current directory is a project root: `SPEC.md` and `run.md` exist here
- `~/personal-build-system/infra-defaults.md` has real values (not placeholders) for:
  `region`, `github-user`, `dns-provider`, `domain`, `monthly-budget-per-project`, `alert-email`
- If `dns-provider` is `namecheap` or `cloudflare`: credentials exist in `~/personal-build-system/.env`

## Usage

Run from inside the project directory:

```bash
cd ~/projects/active/<slug>
```

- `/ship uat` — first deploy: provision Azure resources, deploy code, bind `<slug>.<domain>` as UAT URL
- `/ship live` — promote to production: add a dedicated domain to the existing App Service

---

## Flow — `/ship uat`

### Step 1: Read configuration

Read `~/personal-build-system/infra-defaults.md`. Extract:

| Field | Location in file | Used for |
|-------|-----------------|---------|
| `subscription-id` | `## Azure` | setting active subscription |
| `location` | `## Machines` → dev machine | Azure region |
| `github-user` | `## Source control` | resource tagging |
| `dns-provider` | `## DNS` | which DNS block to follow |
| `domain` | `## DNS` | UAT subdomain base |
| `monthly-budget-per-project` | `## Cost` | budget amount (USD) |
| `alert-email` | `## Cost` | budget alert recipient |

Read `SPEC.md`:
- `slug` from frontmatter; if absent, use the directory name
- Language/runtime: look for `language:` in frontmatter; if absent, infer from files:
  `requirements.txt` present → Python 3.12 | `package.json` present → Node 20

Read `run.md`:
- Find the start command (look for a code block containing `python` or `node` with a port flag, e.g. `--port 8000`)

### Step 2: Verify Azure subscription

```bash
az account show --query "{name:name, id:id}" -o table
```

If the subscription ID doesn't match `infra-defaults.md`:
```bash
az account set --subscription "<subscription-id>"
```

### Step 3: Provision shared infrastructure (idempotent)

```bash
az group create \
  --name rg-personal-shared \
  --location <region> \
  --output none

az appservice plan create \
  --name plan-personal-<region> \
  --resource-group rg-personal-shared \
  --sku B1 \
  --is-linux \
  --output none
```

B1 is the minimum tier that supports custom domains. Both commands are safe to re-run.

### Step 4: Provision per-project resource group

```bash
az group create \
  --name rg-<slug>-personal \
  --location <region> \
  --tags "project=<slug>" "env=uat" "owner=<github-user>" "managed-by=personal-build-system" \
  --output none
```

### Step 5: Create Web App

```bash
PLAN_ID=$(az appservice plan show \
  --name plan-personal-<region> \
  --resource-group rg-personal-shared \
  --query id -o tsv)

az webapp create \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --plan "$PLAN_ID" \
  --runtime "<runtime>" \
  --output none
```

Runtime string: Python 3.12 → `PYTHON:3.12` | Node 20 → `NODE:20-lts`

Tag the Web App:
```bash
az webapp update \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --set tags."project"="<slug>" tags."env"="uat" tags."owner"="<github-user>" tags."managed-by"="personal-build-system" \
  --output none
```

### Step 6: Deploy code

From the project directory:
```bash
az webapp up \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --runtime "<runtime>" \
  --sku B1
```

Wait for completion. If it errors, show the error and stop.

### Step 7: Set startup command

```bash
az webapp config set \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --startup-file "<start command from run.md>" \
  --output none
```

### Step 8: Configure DNS

Get the default App Service hostname (used as the CNAME target):
```bash
DEFAULT_HOST=$(az webapp show \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --query defaultHostName -o tsv)
```

Follow the block for your `dns-provider`:

#### `namecheap`

```bash
source ~/personal-build-system/.env
MY_IP=$(curl -s https://api.ipify.org)
# SLD = second-level domain (e.g. "mydomain"), TLD = extension (e.g. "com")
# Split <domain> from infra-defaults.md accordingly
curl -s "https://api.namecheap.com/xml.response?\
ApiUser=${NAMECHEAP_API_USER}&ApiKey=${NAMECHEAP_API_KEY}\
&UserName=${NAMECHEAP_API_USER}&ClientIp=${MY_IP}\
&Command=namecheap.domains.dns.setHosts\
&SLD=<sld>&TLD=<tld>\
&HostName1=<slug>&RecordType1=CNAME&Address1=${DEFAULT_HOST}&TTL1=1800"
```

Parse the XML response and confirm `Status="OK"`. If not OK, show the error and stop.

#### `cloudflare`

```bash
source ~/personal-build-system/.env
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"CNAME\",\"name\":\"<slug>\",\"content\":\"${DEFAULT_HOST}\",\"ttl\":1,\"proxied\":false}"
```

Parse the JSON response and confirm `"success":true`. If not, show the error and stop.

#### `manual`

Print the record for the user to add at their registrar, then wait:

```
─── DNS record to add ───────────────────────────────────
  Type:    CNAME
  Name:    <slug>
  Value:   <DEFAULT_HOST>
  TTL:     1800 (or "Automatic")
─────────────────────────────────────────────────────────
Add this in your registrar's DNS panel, then press Enter
to continue. (DNS propagation can take up to 30 minutes.)
```

### Step 9: Bind custom domain and enable TLS

```bash
az webapp config hostname add \
  --webapp-name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --hostname <slug>.<domain>

az webapp config ssl create \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --hostname <slug>.<domain>

THUMBPRINT=$(az webapp config ssl list \
  --resource-group rg-<slug>-personal \
  --query "[?subjectName=='<slug>.<domain>'].thumbprint" -o tsv)

az webapp config ssl bind \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --ssl-type SNI \
  --certificate-thumbprint "$THUMBPRINT"
```

### Step 10: Create per-project budget

```bash
az consumption budget create \
  --budget-name "budget-<slug>-personal" \
  --amount <monthly-budget-per-project> \
  --category Cost \
  --time-grain Monthly \
  --resource-group rg-<slug>-personal \
  --notifications '[
    {"enabled":true,"operator":"GreaterThan","threshold":80,"contactEmails":["<alert-email>"],"name":"alert-80"},
    {"enabled":true,"operator":"GreaterThan","threshold":100,"contactEmails":["<alert-email>"],"name":"alert-100"}
  ]'
```

### Step 11: Update project docs

Append to `run.md`:

```markdown
## Production

| | |
|-|-|
| **UAT URL** | https://<slug>.<domain> |
| **App Service** | app-<slug>-personal |
| **Resource group** | rg-<slug>-personal |
| **Tear down** | `az group delete --name rg-<slug>-personal --yes` |
```

In `SPEC.md` frontmatter, set `status: active` and add `uat-url: https://<slug>.<domain>`.

Print summary:
```
✓ Deployed:  https://app-<slug>-personal.azurewebsites.net
✓ UAT URL:   https://<slug>.<domain>
✓ Budget:    $<monthly-budget>/mo, alerts at 80% + 100% → <alert-email>
```

---

## Flow — `/ship live`

### Step 1: Get the production domain

Check `SPEC.md` frontmatter for `live-domain:`. If absent, prompt:
> "What is the dedicated production domain? (e.g. myapp.com)"

### Step 2: Add production domain to App Service

```bash
az webapp config hostname add \
  --webapp-name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --hostname <live-domain>
```

### Step 3: Configure DNS for production domain

Follow the same DNS provider block as Step 8 in `/ship uat`, using:
- Name: `@` (root domain) or `www` as instructed by the user
- Value: the same `$DEFAULT_HOST`

### Step 4: Enable TLS for production domain

```bash
az webapp config ssl create \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --hostname <live-domain>

THUMBPRINT=$(az webapp config ssl list \
  --resource-group rg-<slug>-personal \
  --query "[?subjectName=='<live-domain>'].thumbprint" -o tsv)

az webapp config ssl bind \
  --name app-<slug>-personal \
  --resource-group rg-<slug>-personal \
  --ssl-type SNI \
  --certificate-thumbprint "$THUMBPRINT"
```

### Step 5: Update project docs

In `SPEC.md` frontmatter, add `live-url: https://<live-domain>`.

Update `run.md` Production table to add the live row:

```markdown
## Production

| | |
|-|-|
| **UAT URL** | https://<slug>.<domain> |
| **Live URL** | https://<live-domain> |
| **App Service** | app-<slug>-personal |
| **Resource group** | rg-<slug>-personal |
| **Tear down** | `az group delete --name rg-<slug>-personal --yes` |
```

Print summary:
```
✓ Live URL: https://<live-domain>
```

---

## Teardown reference

```bash
# Remove a single project (per-project RG only — leaves shared plan intact)
az group delete --name rg-<slug>-personal --yes --no-wait

# Remove shared plan (only when removing ALL projects)
az group delete --name rg-personal-shared --yes --no-wait
```
````

- [ ] **Step 3: Verify**

```bash
grep -q "ship uat" .claude/skills/ship.md && echo "PASS ship uat" || echo "FAIL"
grep -q "ship live" .claude/skills/ship.md && echo "PASS ship live" || echo "FAIL"
grep -q "az webapp up" .claude/skills/ship.md && echo "PASS deploy cmd" || echo "FAIL"
grep -q "rg-personal-shared" .claude/skills/ship.md && echo "PASS shared rg" || echo "FAIL"
grep -q "namecheap\|cloudflare\|manual" .claude/skills/ship.md && echo "PASS dns providers" || echo "FAIL"
grep -q "consumption budget create" .claude/skills/ship.md && echo "PASS budget" || echo "FAIL"
grep -q "az group delete" .claude/skills/ship.md && echo "PASS teardown" || echo "FAIL"
```

Expected: all PASS.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/ship.md
git commit -m "feat: add ship skill for Azure App Service deploy"
```

---

## Task 5: Create `.claude/skills/backlog.md`

**Files:**
- Create: `.claude/skills/backlog.md`

- [ ] **Step 1: Verify file doesn't exist**

```bash
test -f .claude/skills/backlog.md && echo "EXISTS" || echo "MISSING — will create"
```

- [ ] **Step 2: Create the file**

Write `.claude/skills/backlog.md` with this exact content:

````markdown
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
````

- [ ] **Step 3: Verify**

```bash
grep -q "/backlog <slug> add" .claude/skills/backlog.md && echo "PASS add" || echo "FAIL"
grep -q "/backlog <slug> bug" .claude/skills/backlog.md && echo "PASS bug" || echo "FAIL"
grep -q "/backlog <slug> target" .claude/skills/backlog.md && echo "PASS target" || echo "FAIL"
grep -q "Current build target" .claude/skills/backlog.md && echo "PASS target section" || echo "FAIL"
grep -q "Known issues" .claude/skills/backlog.md && echo "PASS known issues" || echo "FAIL"
grep -q "~/projects/active" .claude/skills/backlog.md && echo "PASS path" || echo "FAIL"
```

Expected: all PASS.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/backlog.md
git commit -m "feat: add backlog skill for cross-project SPEC.md management"
```

---

## Task 6: Update `full-bootstrap.sh`

**Files:**
- Modify: `full-bootstrap.sh`

- [ ] **Step 1: Verify superpowers not mentioned yet**

```bash
grep -q "superpowers" full-bootstrap.sh && echo "EXISTS" || echo "MISSING — will add"
```

Expected: MISSING.

- [ ] **Step 2: Update the Next Steps output**

Find the `Next steps:` block near the end of `full-bootstrap.sh`. It currently reads:

```bash
echo "Next steps:"
echo "  1. ssh $VM_NAME"
echo "  2. Run 'claude' to authenticate with your Anthropic account"
echo "  3. Fill out ~/personal-build-system/infra-defaults.md with your real values"
echo "  4. git add infra-defaults.md && git commit -m 'infra: initial' && git push"
echo "  5. Create a Claude Project at claude.ai"
echo "     Paste ~/personal-build-system/spec-builder-prompt.md as the system prompt"
echo "  6. Start building."
```

Replace it with:

```bash
echo "Next steps:"
echo "  1. ssh $VM_NAME"
echo "  2. Run 'claude' to authenticate with your Anthropic account"
echo "  3. Install superpowers (inside Claude Code):"
echo "       /plugin install superpowers@claude-plugins-official"
echo "       /reload-plugins"
echo "  4. Fill out ~/personal-build-system/infra-defaults.md with your real values"
echo "  5. git add infra-defaults.md && git commit -m 'infra: initial' && git push"
echo "  6. Create two Claude Projects at claude.ai:"
echo "     a) Spec Builder — paste spec-builder-prompt.md as the system prompt"
echo "     b) Idea Capture — paste idea-capture-prompt.md as the system prompt"
echo "  7. Start building."
```

- [ ] **Step 3: Verify**

```bash
grep -q "superpowers" full-bootstrap.sh && echo "PASS superpowers" || echo "FAIL"
grep -q "plugin install" full-bootstrap.sh && echo "PASS plugin install" || echo "FAIL"
grep -q "idea-capture-prompt" full-bootstrap.sh && echo "PASS idea capture ref" || echo "FAIL"
```

Expected: all PASS.

- [ ] **Step 4: Commit**

```bash
git add full-bootstrap.sh
git commit -m "feat: add superpowers install and two-project setup to bootstrap next steps"
```

---

## Task 7: Update `README.md`

**Files:**
- Modify: `README.md`

This task has multiple sub-changes. Apply each in order.

- [ ] **Step 1: Verify current state**

```bash
grep -q "Phase 0" README.md && echo "EXISTS" || echo "MISSING"
grep -q "superpowers" README.md && echo "EXISTS" || echo "MISSING"
grep -q "ship uat" README.md && echo "EXISTS" || echo "MISSING"
```

Expected: all MISSING.

- [ ] **Step 2: Update the "What's in this repo" table**

Find the table (starts with `| File | Purpose |`). Add three rows after the `spec-template.md` row:

```markdown
| `.claude/skills/ship.md` | Deploys a project to Azure App Service (`/ship uat`, `/ship live`) |
| `.claude/skills/backlog.md` | Manages backlogs and build targets across projects (`/backlog`) |
| `idea-capture-prompt.md` | Phase 0 Claude.ai Project prompt for mobile voice idea capture |
```

- [ ] **Step 3: Add Phase 0 before Phase 1**

Find `### Phase 1 — Capture` and insert before it:

```markdown
### Phase 0 — Ideation

An idea arrives. Open the **Idea Capture** Claude Project on mobile and describe it — spoken or typed, rough or polished. The project responds with one structured idea card. Copy it.

On your VM:

```bash
mkdir -p ~/projects/ideas
# paste the idea card into ~/projects/ideas/<slug>.md
```

The card is your input to Phase 3. A note in your phone works too — the card format just makes Phase 3 faster.

---
```

- [ ] **Step 4: Update Phase 4 — Ignition**

Find the Phase 4 bash block:
```bash
claude "Read SPEC.md and build this. Write your assumptions and decisions to claude.md."
```

Replace the whole Phase 4 section content with:

```markdown
### Phase 4 — Ignition

**Recommended path (superpowers):**

```bash
cd ~/projects/active/<slug>
claude
```

Then inside the Claude Code session:

```
/superpowers:brainstorming    ← structured design conversation → design doc
/superpowers:writing-plans    ← step-by-step implementation plan
/superpowers:executing-plans  ← executes the plan with review checkpoints
```

**Simple projects (no design needed):**

```bash
claude "Read SPEC.md and build this. Write your assumptions and decisions to claude.md."
```

Go do something else. Come back when it's done.
```

- [ ] **Step 5: Add Phase 7 and Phase 8 after Phase 6**

Find `### Phase 6 — Ship and transition` and after its content add:

```markdown
### Phase 7 — Ship (UAT)

Ready for real users? Deploy to Azure App Service:

```bash
cd ~/projects/active/<slug>
/ship uat
```

The skill provisions Azure resources, deploys your code, configures DNS, creates a cost budget, and writes the UAT URL back to `run.md`. Takes 3-5 minutes. Send the URL to someone who isn't you.

### Phase 8 — Ship (Live)

UAT passed? Add a dedicated production domain:

```bash
/ship live
```

No re-deploy. Same App Service, second custom domain.
```

- [ ] **Step 6: Update the Iteration section**

Find the iteration numbered list (the 6 steps starting with `1. Open SPEC.md.`). Replace it with:

```markdown
1. Open `SPEC.md` directly, or manage items from anywhere with `/backlog`:
   - `/backlog <slug> add "feature"` — adds to Backlog
   - `/backlog <slug> bug "bug description"` — adds to Known Issues
   - `/backlog <slug> target "what to build next"` — sets Current Build Target
2. Commit the spec change:
   ```bash
   git commit -am "spec: iteration — <what you're doing>"
   ```
3. Build with the right superpowers skill for the job:
   - New feature → `/superpowers:test-driven-development`
   - Bug fix → `/superpowers:systematic-debugging`
   - Done, ready to ship → `/superpowers:finishing-a-development-branch` then `/ship uat`
4. Smoke test. Commit. Clear `## Current build target`.
```

- [ ] **Step 7: Verify**

```bash
grep -q "Phase 0" README.md && echo "PASS Phase 0" || echo "FAIL"
grep -q "Phase 7" README.md && echo "PASS Phase 7" || echo "FAIL"
grep -q "Phase 8" README.md && echo "PASS Phase 8" || echo "FAIL"
grep -q "superpowers:brainstorming" README.md && echo "PASS superpowers ref" || echo "FAIL"
grep -q "ship uat" README.md && echo "PASS ship uat" || echo "FAIL"
grep -q "/backlog" README.md && echo "PASS backlog ref" || echo "FAIL"
grep -q "ship.md" README.md && echo "PASS ship in table" || echo "FAIL"
grep -q "idea-capture-prompt" README.md && echo "PASS idea capture in table" || echo "FAIL"
```

Expected: all PASS.

- [ ] **Step 8: Commit**

```bash
git add README.md
git commit -m "docs: add Phase 0/7/8, superpowers path, backlog to iteration loop"
```

---

## Task 8: Update `ONBOARDING.md`, `stack-defaults.md`, `spec-builder-prompt.md`

**Files:**
- Modify: `ONBOARDING.md`
- Modify: `stack-defaults.md`
- Modify: `spec-builder-prompt.md`

### `ONBOARDING.md`

- [ ] **Step 1: Verify superpowers not mentioned yet**

```bash
grep -q "superpowers" ONBOARDING.md && echo "EXISTS" || echo "MISSING — will add"
```

Expected: MISSING.

- [ ] **Step 2: Add Step 5a — Install superpowers**

Find `## Step 5 — Authenticate Claude Code` and after its content (before `## Step 6`), insert:

```markdown
## Step 5a — Install superpowers

In your Claude Code session on the VM, run these two commands:

```
/plugin install superpowers@claude-plugins-official
/reload-plugins
```

This installs the skills that power the build loop: brainstorming, planning, test-driven development, debugging, and more. You only need to do this once per VM. If you skip this step, the recommended Phase 4 invocations in `README.md` won't work.

```

- [ ] **Step 3: Add domain/DNS step after Step 6**

Find `## Step 7 — Update stack-defaults.md` and insert before it:

```markdown
## Step 6a — Set up your domain and DNS credentials

The `ship` skill needs a domain to bind UAT subdomains to. You have three options:

**Option A — `manual` (easiest, no credentials needed)**
Set `dns-provider: manual` in `infra-defaults.md`. When you run `/ship uat`, the skill will print the DNS record to add and wait for you to do it manually in your registrar's panel. Works with any registrar.

**Option B — `namecheap`**
If your domain is on Namecheap:
1. Log in to Namecheap → Profile → Tools → API Access → enable API and whitelist your VM's IP
2. Add to `~/personal-build-system/.env` (create if it doesn't exist):
   ```
   NAMECHEAP_API_USER=your-username
   NAMECHEAP_API_KEY=your-api-key
   ```
3. Set `dns-provider: namecheap` in `infra-defaults.md`

**Option C — `cloudflare`**
If your domain's nameservers point to Cloudflare:
1. Cloudflare dashboard → My Profile → API Tokens → Create Token (use "Edit zone DNS" template)
2. Add to `~/personal-build-system/.env`:
   ```
   CLOUDFLARE_API_TOKEN=your-token
   CLOUDFLARE_ZONE_ID=your-zone-id
   ```
3. Set `dns-provider: cloudflare` in `infra-defaults.md`

Set your base domain in `infra-defaults.md`:
```
domain: yourdomain.com
```

If you don't have a domain yet, set `dns-provider: manual` and buy one when you have a project ready to ship.

```

- [ ] **Step 4: Update Step 8 — Create your Claude Project**

Find `## Step 8 — Create your Claude Project` and replace its content with:

```markdown
## Step 8 — Create your Claude Projects

You need two Claude Projects — one for speccing, one for capturing ideas.

**Project 1: Spec Builder**
1. Go to claude.ai → Projects → New Project
2. Name it "Spec Builder"
3. Open `spec-builder-prompt.md` and paste its full contents into the project's system prompt
4. **If you forked this repo:** update the name, role, and personal details in the system prompt to reflect you, not Ryan Goldberg
5. Save

**Project 2: Idea Capture**
1. Create another new project
2. Name it "Idea Capture"
3. Open `idea-capture-prompt.md` and paste its full contents into the system prompt
4. Save — no personalization needed

Use Idea Capture on mobile when an idea arrives. Use Spec Builder when you're ready to spec it out.
```

- [ ] **Step 5: Add `/backlog` mention after first project step**

Find `## Step 9 — Run your first project` and after its content, at the end of the file, append:

```markdown
## Step 10 — Explore the lifecycle tools

Once your first project is built and smoke tests pass, try:

**Manage your backlog from anywhere:**
```bash
/backlog                           # dashboard across all active projects
/backlog <slug>                    # full view + interactive prompt
/backlog <slug> add "next feature" # add to backlog
/backlog <slug> bug "found a bug"  # log an issue
```

**Deploy to the real world:**
```bash
cd ~/projects/active/<slug>
/ship uat   # provision Azure App Service + bind UAT subdomain
/ship live  # add production domain when UAT passes
```

Both skills read your `infra-defaults.md` — they work for any project you build.
```

- [ ] **Step 6: Verify ONBOARDING.md**

```bash
grep -q "superpowers" ONBOARDING.md && echo "PASS superpowers" || echo "FAIL"
grep -q "dns-provider" ONBOARDING.md && echo "PASS dns" || echo "FAIL"
grep -q "Idea Capture" ONBOARDING.md && echo "PASS idea capture project" || echo "FAIL"
grep -q "/backlog" ONBOARDING.md && echo "PASS backlog" || echo "FAIL"
grep -q "/ship uat" ONBOARDING.md && echo "PASS ship" || echo "FAIL"
grep -q "forked this repo" ONBOARDING.md && echo "PASS forker note" || echo "FAIL"
```

Expected: all PASS.

### `stack-defaults.md`

- [ ] **Step 7: Update Tier 2 runtime/hosting note**

Find the `## Runtime / hosting` section. Find the Tier 2 line:
```
- **Tier 2 (cloud):** Deliberate choice only. Explicitly stated in spec.
```

Replace it with:
```markdown
- **Tier 2 (cloud):** Deliberate choice only. Explicitly stated in spec. Default cloud target is Azure App Service, deployed via `/ship uat` from the project directory.
```

- [ ] **Step 8: Verify stack-defaults.md**

```bash
grep -q "Azure App Service" stack-defaults.md && echo "PASS" || echo "FAIL"
grep -q "ship uat" stack-defaults.md && echo "PASS" || echo "FAIL"
```

Expected: both PASS.

### `spec-builder-prompt.md`

- [ ] **Step 9: Add forker note to top of file**

Insert at the very top of `spec-builder-prompt.md`, before the `# Spec Builder` heading:

```markdown
> **If you forked this repo:** Update the name, role, and personal details in this prompt to reflect you before creating your Claude Project. The system prompt is personalized by design — it helps the Spec Builder apply your defaults without asking.

```

- [ ] **Step 10: Verify spec-builder-prompt.md**

```bash
grep -q "forked this repo" spec-builder-prompt.md && echo "PASS" || echo "FAIL"
```

Expected: PASS.

- [ ] **Step 11: Commit all**

```bash
git add ONBOARDING.md stack-defaults.md spec-builder-prompt.md
git commit -m "docs: add superpowers, DNS/domain, idea capture, and ship/backlog to onboarding and stack defaults"
```

---

## Task 9: Final verification and push

- [ ] **Step 1: Run full acceptance check**

```bash
echo "=== Skills ===" && \
  ls .claude/skills/ship.md .claude/skills/backlog.md && \
echo "=== Prompt ===" && \
  ls idea-capture-prompt.md && \
echo "=== .env.example ===" && \
  grep -q "NAMECHEAP_API_USER" .env.example && echo "PASS" || echo "FAIL" && \
echo "=== infra-defaults ===" && \
  grep -q "dns-provider" infra-defaults.md && echo "PASS" && \
  grep -q "monthly-budget-per-project" infra-defaults.md && echo "PASS" || echo "FAIL" && \
echo "=== README ===" && \
  grep -q "Phase 0" README.md && echo "PASS" && \
  grep -q "Phase 7" README.md && echo "PASS" && \
  grep -q "ship uat" README.md && echo "PASS" && \
  grep -q "superpowers:brainstorming" README.md && echo "PASS" || echo "FAIL" && \
echo "=== ONBOARDING ===" && \
  grep -q "superpowers" ONBOARDING.md && echo "PASS" && \
  grep -q "Idea Capture" ONBOARDING.md && echo "PASS" && \
  grep -q "/ship uat" ONBOARDING.md && echo "PASS" || echo "FAIL" && \
echo "=== bootstrap ===" && \
  grep -q "superpowers" full-bootstrap.sh && echo "PASS" || echo "FAIL"
```

Expected: all files present, all greps PASS.

- [ ] **Step 2: Check git status**

```bash
git status
git log --oneline -10
```

Expected: clean working tree, 8+ commits since start of this plan.

- [ ] **Step 3: Push**

```bash
git push origin main
```

---

## Done criteria (from spec)

- [ ] `.claude/skills/ship.md` exists and covers `/ship uat` and `/ship live` with complete `az` CLI commands
- [ ] `.claude/skills/backlog.md` exists and covers all five `/backlog` invocations
- [ ] `idea-capture-prompt.md` exists and produces the correct card format
- [ ] `infra-defaults.md` has `## DNS` and `## Cost` sections
- [ ] `.env.example` documents all DNS credential keys
- [ ] `full-bootstrap.sh` Next Steps output includes superpowers install
- [ ] `README.md` has Phase 0, updated Phase 4, Phase 7, Phase 8, updated iteration loop, updated table
- [ ] `ONBOARDING.md` has superpowers step, domain/DNS step, two-project Claude setup, `/backlog` and `/ship` introduction
- [ ] `stack-defaults.md` references Azure App Service + `/ship` for Tier 2
- [ ] `spec-builder-prompt.md` has forker personalization note
- [ ] Repo is forkable and usable by someone who is not Ryan
