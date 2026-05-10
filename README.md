# personal-build-system

Lean idea-to-built-product pipeline for personal use. One conversation to spec, one command to build.

**New here?** See [ONBOARDING.md](ONBOARDING.md) to make this yours.

---

## What this is

A small system that takes an idea ("I want a thing that does X") and produces a working built thing, with the minimum viable structure between the two.

```
Idea
  ↓
Spec Builder (interrogates you until the spec is solid)
  ↓
SPEC.md (rich enough for Claude Code to build without further questions)
  ↓
Claude Code (reads spec, builds it)
  ↓
Built thing
```

## What's in this repo

| File | Purpose |
|------|---------|
| `README.md` | This file. System overview + ignition sequence. |
| `ONBOARDING.md` | How to fork and make this yours on a fresh Azure account. |
| `full-bootstrap.sh` | Creates and provisions your Azure dev VM. Run once per machine. |
| `spec-builder-prompt.md` | Paste into a Claude Project as the system prompt. This is the Spec Builder. |
| `stack-defaults.md` | Your personal build defaults. Referenced by the Spec Builder. |
| `infra-defaults.md` | Where and how things run. Fill in your real values after bootstrap. |
| `spec-template.md` | The blank spec schema. Claude Code reference. |
| `.claude/skills/ship.md` | Deploys a project to Azure App Service (`/ship uat`, `/ship live`) |
| `.claude/skills/backlog.md` | Manages backlogs and build targets across projects (`/backlog`) |
| `idea-capture-prompt.md` | Phase 0 Claude.ai Project prompt for mobile voice idea capture |

---

## Ignition sequence

### Phase 0 — Ideation

An idea arrives. Open the **Idea Capture** Claude Project on mobile and describe it — spoken or typed, rough or polished. The project responds with one structured idea card. Copy it.

On your VM:

```bash
mkdir -p ~/projects/ideas
# paste the idea card into ~/projects/ideas/<slug>.md
```

The card is your input to Phase 3. A note in your phone works too — the card format just makes Phase 3 faster.

---

### Phase 1 — Capture

You have an idea. You're driving, walking, in the shower. Open Claude mobile or drop a note. Don't spec it yet — just capture enough to reconstruct the idea later. One paragraph minimum. The artifact is a rough idea paragraph.

### Phase 2 — Ready check

Before opening the Spec Builder, ask: can I describe the happy path end-to-end in one sentence? If no, keep thinking. If yes, proceed. The Spec Builder will expose gaps anyway — the ready check just prevents wasting a conversation on a half-baked idea.

### Phase 3 — Spec Builder

Open your Personal Build System Claude Project. Drop the idea paragraph. Let it interrogate you. Six exchanges max. At the end you have a `SPEC.md` block. Skim it — 60 seconds. Fix anything obviously wrong before saving. The spec is a contract; don't sign it with known errors.

### Phase 4 — Ignition

On your VM:

```bash
mkdir -p ~/projects/active/<slug>
cd ~/projects/active/<slug>
git init
# paste SPEC.md content into SPEC.md
git add SPEC.md
git commit -m "spec: initial"
```

**Recommended path (superpowers — for anything non-trivial):**

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

**Simple projects (one-shot, no design needed):**

```bash
claude "Read SPEC.md and build this. Write your assumptions and decisions to claude.md."
```

Go do something else. Come back when it's done.

### Phase 5 — Smoke test

Run the smoke test described in `SPEC.md`. Pass means shippable. Fail means: read `claude.md` to find the wrong assumption, fix the spec, re-invoke targeted:

```bash
claude "Read SPEC.md. Fix the issue in Known issues: [X] only. Everything else is context."
```

### Phase 6 — Ship and transition

Working? Update `SPEC.md` frontmatter to `status: active`. Use it. When it stabilizes, `status: maintenance`.

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

---

## Iteration (bug fix or feature)

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

---

## Development vs maintenance

| Status | Meaning | Claude Code cadence |
|--------|---------|-------------------|
| `active` | Being built or actively iterated | Regular |
| `maintenance` | Works, touch only when needed | Infrequent, targeted |
| `archived` | Done or abandoned | Never |

Transition to maintenance:

```bash
# update status: in SPEC.md frontmatter
git commit -am "chore: transition to maintenance"
```

Archive:

```bash
mv ~/projects/active/<slug> ~/projects/archive/<slug>-$(date +%Y%m%d)
```

---

## Project folder structure

```
~/projects/
  active/
    <slug>/
      SPEC.md       <- source of truth
      claude.md     <- Claude Code's assumptions/decisions log
      run.md        <- how to run from a fresh pull
      README.md     <- generated by Claude Code
      /src
      /tests
  archive/
    <slug>-YYYYMMDD/
```

**Rules:**
- A project is either `active` or `archived`. No sub-stages.
- Archive on completion or abandonment. Same action, different reason.
- `SPEC.md` is always the source of truth. If the built thing and the spec disagree, the spec wins.
- `claude.md` is your recovery surface. Read it first when something goes wrong.

---

## In-flight view

```bash
ls ~/projects/active/
```

That's enough until ~7 active projects. After that:

```bash
for d in ~/projects/active/*/; do
  echo "$(basename $d): $(grep 'status:' $d/SPEC.md | head -1)"
done
```

---

## Failure mode recovery

| Type | Symptom | Recovery |
|------|---------|----------|
| Wrong direction, caught early | Two steps in, already wrong | `git reset --hard`, fix spec, re-invoke |
| Partially built, can't unwind | Tangled, don't want to throw away | `git checkout -b rebuild-v2`, fix spec, rebuild on branch |
| Built wrong thing, found at smoke test | Spec was ambiguous, Claude Code chose wrong | Read `claude.md`, fix spec explicitly, re-invoke targeted |

**The rule:** fix the spec first, then fix the code. Never the other way around.

---

## Updating your defaults

- Build tech changed → edit `stack-defaults.md`
- Infra changed → edit `infra-defaults.md`
- Spec schema evolved → edit `spec-template.md`
- Interrogation protocol changed → edit `spec-builder-prompt.md`

---

## New machine setup

```bash
git clone git@github.com:YOUR_USERNAME/personal-build-system.git ~/personal-build-system
bash ~/personal-build-system/full-bootstrap.sh
```

See [ONBOARDING.md](ONBOARDING.md) for the full walkthrough.
