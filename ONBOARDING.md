# Onboarding — Make This Yours

This repo is a personal idea-to-built-product pipeline. It was built for one person's setup but is designed to be forked and adapted. This document walks you through taking it from Ryan's configuration to yours, starting from a fresh Azure account.

## What you need before you start

- An Azure account (free trial or pay-as-you-go at portal.azure.com)
- An Anthropic account with Claude access (claude.ai)
- A GitHub account
- A machine to run the bootstrap from — any Linux, macOS, or WSL terminal works

## Step 1 — Fork the repo

Fork `goldsmurf-droid/personal-build-system` to your own GitHub account. Clone it locally just long enough to run the bootstrap — after that, your VM is your dev machine.

```bash
git clone git@github.com:YOUR_USERNAME/personal-build-system.git
cd personal-build-system
```

## Step 2 — Generate an SSH keypair

If you don't already have one at `~/.ssh/id_ed25519`:

```bash
ssh-keygen -t ed25519 -C "your@email.com"
```

Add the public key to your GitHub account: github.com → Settings → SSH and GPG keys → New SSH key. Paste the contents of `~/.ssh/id_ed25519.pub`.

## Step 3 — Install Azure CLI and log in

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
```

Your browser will open for authentication. When it returns, confirm you're on the right subscription:

```bash
az account list --output table
az account set --subscription "YOUR SUBSCRIPTION NAME OR ID"
```

## Step 4 — Run the bootstrap

```bash
bash full-bootstrap.sh
```

The script will prompt you for:

- **GitHub username** — your GitHub handle
- **GitHub repo name** — `personal-build-system` unless you renamed it
- **VM admin username** — your Linux username on the VM (your local username is the default)
- **Azure resource group name** — `personal-projects` is fine
- **Azure region** — `eastus2` is a good default; change if you want a closer region
- **VM name** — `personal-vm` is fine
- **VM size** — `Standard_D2s_v3` (2 vCPU / 8GB) is the tested default

It will show you a summary and ask you to confirm before creating anything. Then it runs for 5-8 minutes and finishes with your VM provisioned, your repo cloned onto it, and an SSH shortcut configured.

**If VM size fails:** Azure has regional capacity limits, especially on new accounts. If `Standard_D2s_v3` is unavailable, try `Standard_D2s_v4` or change the region to `westus2` and rerun.

## Step 5 — Authenticate Claude Code

```bash
ssh personal-vm
claude
```

Follow the prompts. It will open a browser link or give you a code to enter. This ties Claude Code to your Anthropic account.

## Step 6 — Update infra-defaults.md

Fill in your real values. The bootstrap output gives you everything you need:

```bash
cd ~/personal-build-system
nano infra-defaults.md
```

Replace all of Ryan's values with yours. At minimum:
- VM IP address (printed at end of bootstrap)
- VM size and region
- Azure subscription ID (`az account show --query id -o tsv`)
- GitHub username

Then commit and push:

```bash
git add infra-defaults.md
git commit -m "infra: initial values"
git push
```

## Step 7 — Update stack-defaults.md

Open `stack-defaults.md` and update the git config section with your name and email. Everything else can stay as-is unless you have different preferences.

```bash
nano stack-defaults.md
git add stack-defaults.md
git commit -m "stack: update identity"
git push
```

## Step 8 — Create your Claude Project

1. Go to claude.ai → Projects → New Project
2. Name it "Personal Build System" (or whatever you want)
3. Open `spec-builder-prompt.md` and paste its full contents into the project's system prompt field
4. Save

This is your Spec Builder. Every new project starts with a conversation in this Claude Project.

## Step 9 — Run your first project

In your Claude Project, drop your idea. One paragraph. Let the Spec Builder interrogate you. When it outputs a `SPEC.md` block:

```bash
# on your VM
mkdir -p ~/projects/active/your-slug
cd ~/projects/active/your-slug
git init
# paste SPEC.md content into SPEC.md
git add SPEC.md
git commit -m "spec: initial"
claude "Read SPEC.md and build this. Write your assumptions to claude.md."
```

## VM management

Your VM costs money when running. Stop it when you're not using it:

```bash
# stop (deallocate — stops billing for compute)
az vm deallocate --resource-group personal-projects --name personal-vm

# start again
az vm start --resource-group personal-projects --name personal-vm
```

The public IP is static — it survives stop/start cycles. Your SSH config will keep working.

## Updating the system

When this repo gets updates:

```bash
cd ~/personal-build-system
git pull
```

That's it. The system lives in five files. Updates are just file changes.

## Troubleshooting

**VM size not available:** Try a different size (`Standard_D4s_v3`, `Standard_B4ms`) or a different region (`westus2`, `centralus`). Rerun `full-bootstrap.sh` after deleting the failed resource group: `az group delete --name personal-projects --yes`

**Claude Code auth fails:** Make sure you have an active Anthropic account at claude.ai before running `claude` on the VM.

**GitHub clone fails:** Make sure your SSH public key is added to your GitHub account (Step 2) and your private key is on the VM at `~/.ssh/id_ed25519` with permissions `600`.

**pip or black/pytest not found:** Run `source ~/.bashrc` to reload PATH, or log out and back in.
