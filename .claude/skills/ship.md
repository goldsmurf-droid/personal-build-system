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
