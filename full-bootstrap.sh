#!/usr/bin/env bash
# full-bootstrap.sh
# Creates an Azure VM and provisions it as a complete personal dev environment.
# Run from any machine with Azure CLI installed.
# Prompts for all user-specific values — nothing is hardcoded.

set -e

echo ""
echo "=== personal-build-system bootstrap ==="
echo ""
echo "This script will:"
echo "  1. Create an Azure resource group and VM"
echo "  2. Provision the VM with Python, Node, Claude Code, and git"
echo "  3. Copy your SSH key to the VM"
echo "  4. Clone your personal-build-system repo onto the VM"
echo ""
echo "Prerequisites:"
echo "  - Azure CLI installed and logged in (az login)"
echo "  - An SSH keypair at ~/.ssh/id_ed25519"
echo "  - A GitHub repo forked from personal-build-system"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# ─── collect user-specific values ────────────────────────────────────────────

read -p "GitHub username: " GITHUB_USER
read -p "GitHub repo name [personal-build-system]: " GITHUB_REPO
GITHUB_REPO="${GITHUB_REPO:-personal-build-system}"

read -p "VM admin username [$(whoami)]: " ADMIN_USER
ADMIN_USER="${ADMIN_USER:-$(whoami)}"

read -p "Azure resource group name [personal-projects]: " RESOURCE_GROUP
RESOURCE_GROUP="${RESOURCE_GROUP:-personal-projects}"

read -p "Azure region [eastus2]: " LOCATION
LOCATION="${LOCATION:-eastus2}"

read -p "VM name [personal-vm]: " VM_NAME
VM_NAME="${VM_NAME:-personal-vm}"

read -p "VM size [Standard_D2s_v3]: " VM_SIZE
VM_SIZE="${VM_SIZE:-Standard_D2s_v3}"

SSH_PUB_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
if [ ! -f "$SSH_PUB_KEY_PATH" ]; then
  echo ""
  echo "ERROR: No SSH public key found at $SSH_PUB_KEY_PATH"
  echo "Generate one with: ssh-keygen -t ed25519 -C \"your@email.com\""
  exit 1
fi
SSH_PUB_KEY=$(cat "$SSH_PUB_KEY_PATH")

GITHUB_REMOTE="git@github.com:${GITHUB_USER}/${GITHUB_REPO}.git"

echo ""
echo "─── Configuration ───────────────────────────────────────"
echo "  GitHub remote:  $GITHUB_REMOTE"
echo "  VM user:        $ADMIN_USER"
echo "  Resource group: $RESOURCE_GROUP ($LOCATION)"
echo "  VM:             $VM_NAME ($VM_SIZE)"
echo "  SSH key:        $SSH_PUB_KEY_PATH"
echo "─────────────────────────────────────────────────────────"
echo ""
read -p "Proceed? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
echo ""

# ─── azure cli check ─────────────────────────────────────────────────────────
echo "→ Checking Azure CLI..."
if ! command -v az &> /dev/null; then
  echo "  Azure CLI not found. Installing..."
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
  echo "  Azure CLI found: $(az version --query '"azure-cli"' -o tsv)"
fi

echo "→ Checking Azure login..."
if ! az account show &> /dev/null; then
  echo "  Not logged in. Running az login..."
  az login
fi
ACCOUNT=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "  Logged in: $ACCOUNT ($SUBSCRIPTION_ID)"
echo ""

# ─── create resource group ───────────────────────────────────────────────────
echo "→ Creating resource group: $RESOURCE_GROUP in $LOCATION..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none
echo "  Done."
echo ""

# ─── create vm ───────────────────────────────────────────────────────────────
echo "→ Creating VM: $VM_NAME ($VM_SIZE, Ubuntu 22.04, 64GB disk)..."
echo "  This takes 2-3 minutes..."
VM_OUTPUT=$(az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image Ubuntu2204 \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --ssh-key-values "$SSH_PUB_KEY" \
  --os-disk-size-gb 64 \
  --public-ip-sku Standard \
  --location "$LOCATION" \
  --output json)

PUBLIC_IP=$(echo "$VM_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['publicIpAddress'])")
echo "  VM created. Public IP: $PUBLIC_IP"
echo ""

# ─── write provision script ──────────────────────────────────────────────────
echo "→ Writing provision script..."
cat > /tmp/vm-provision.sh << PROVISION
#!/usr/bin/env bash
set -e

echo ""
echo "=== vm provisioning ==="
echo ""

echo "→ Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
echo "  Done."
echo ""

echo "→ Installing Python 3.12..."
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update -qq
sudo apt-get install -y python3.12 python3.12-venv python3.12-dev python3-pip
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
python3.12 -m ensurepip --upgrade
python3.12 -m pip install python-dotenv black ruff pytest
echo "  Python \$(python3.12 --version) — OK"
echo ""

echo "→ Adding ~/.local/bin to PATH..."
grep -q '.local/bin' ~/.bashrc || echo 'export PATH="\$HOME/.local/bin:\$PATH"' >> ~/.bashrc
export PATH="\$HOME/.local/bin:\$PATH"
echo "  Done."
echo ""

echo "→ Installing Node.js 20 via nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="\$HOME/.nvm"
source "\$NVM_DIR/nvm.sh"
nvm install 20
nvm use 20
nvm alias default 20
echo "  Node \$(node --version) — OK"
echo ""

echo "→ Installing Claude Code..."
npm install -g @anthropic-ai/claude-code@latest
echo "  Claude Code \$(claude --version) — OK"
echo ""

echo "→ Configuring git..."
git config --global user.name "${ADMIN_USER}"
git config --global init.defaultBranch main
echo "  Done."
echo ""

echo "→ Creating project directory structure..."
mkdir -p ~/projects/active
mkdir -p ~/projects/archive
echo "  ~/projects/active/"
echo "  ~/projects/archive/"
echo ""

grep -q 'NVM_DIR' ~/.bashrc || cat >> ~/.bashrc << 'NVMRC'
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
NVMRC

echo "=== provisioning complete ==="
PROVISION

chmod +x /tmp/vm-provision.sh
echo "  Done."
echo ""

# ─── wait for ssh ────────────────────────────────────────────────────────────
echo "→ Waiting for SSH..."
for i in {1..20}; do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
    -i ~/.ssh/id_ed25519 "$ADMIN_USER@$PUBLIC_IP" "echo ok" &>/dev/null; then
    echo "  SSH ready."
    break
  fi
  echo "  Waiting... ($i/20)"
  sleep 10
done
echo ""

# ─── provision vm ────────────────────────────────────────────────────────────
echo "→ Copying and running provision script (3-5 minutes)..."
scp -o StrictHostKeyChecking=no \
  -i ~/.ssh/id_ed25519 \
  /tmp/vm-provision.sh \
  "$ADMIN_USER@$PUBLIC_IP:~/vm-provision.sh"

ssh -o StrictHostKeyChecking=no \
  -i ~/.ssh/id_ed25519 \
  "$ADMIN_USER@$PUBLIC_IP" \
  "bash ~/vm-provision.sh"
echo ""

# ─── copy private key ────────────────────────────────────────────────────────
echo "→ Copying SSH private key to VM..."
scp -o StrictHostKeyChecking=no \
  -i ~/.ssh/id_ed25519 \
  ~/.ssh/id_ed25519 \
  "$ADMIN_USER@$PUBLIC_IP:~/.ssh/id_ed25519"
ssh -o StrictHostKeyChecking=no \
  -i ~/.ssh/id_ed25519 \
  "$ADMIN_USER@$PUBLIC_IP" \
  "chmod 600 ~/.ssh/id_ed25519"
echo "  Done."
echo ""

# ─── clone repo ──────────────────────────────────────────────────────────────
echo "→ Cloning $GITHUB_REMOTE on VM..."
ssh -o StrictHostKeyChecking=no \
  -i ~/.ssh/id_ed25519 \
  "$ADMIN_USER@$PUBLIC_IP" \
  "ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null && git clone $GITHUB_REMOTE ~/personal-build-system"
echo "  Done."
echo ""

# ─── write local ssh config ──────────────────────────────────────────────────
echo "→ Adding SSH config entry..."
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "Host $VM_NAME" "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" << SSHCONF

Host $VM_NAME
  HostName $PUBLIC_IP
  User $ADMIN_USER
  IdentityFile ~/.ssh/id_ed25519
SSHCONF
  echo "  Added 'Host $VM_NAME' to ~/.ssh/config"
else
  echo "  Entry already exists in ~/.ssh/config — skipping"
fi
echo ""

# ─── done ────────────────────────────────────────────────────────────────────
echo "=== bootstrap complete ==="
echo ""
echo "  VM public IP:   $PUBLIC_IP"
echo "  SSH shortcut:   ssh $VM_NAME"
echo ""
echo "Next steps:"
echo "  1. ssh $VM_NAME"
echo "  2. Run 'claude' to authenticate with your Anthropic account"
echo "  3. Install superpowers (inside your Claude Code session):"
echo "       /plugin install superpowers@claude-plugins-official"
echo "       /reload-plugins"
echo "  4. Fill out ~/personal-build-system/infra-defaults.md with your real values"
echo "  5. git add infra-defaults.md && git commit -m 'infra: initial' && git push"
echo "  6. Create two Claude Projects at claude.ai:"
echo "     a) Spec Builder — paste spec-builder-prompt.md as the system prompt"
echo "     b) Idea Capture — paste idea-capture-prompt.md as the system prompt"
echo "  7. Start building."
echo ""
echo "  VM management:"
echo "  Stop:    az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_NAME"
echo "  Start:   az vm start --resource-group $RESOURCE_GROUP --name $VM_NAME"
