# Infra Defaults

Where and how personal projects run. Fill this out for your environment. The Spec Builder reads this so you don't get asked the same questions every time.

---

## Machines

### Dev machine(s)

```
# Example — replace with your actual inventory
hostname: <your-dev-hostname>
os: <macOS / Linux distro + version>
python: 3.11.x (verify with `python3 --version`)
claude-code: installed at <path>
git: configured, SSH key to GitHub/Bitbucket
notes: <anything unusual>
```

Add additional dev machines as needed.

### VM / remote host (Tier 1)

```
hostname: <your-vm-hostname-or-IP>
os: <Linux distro + version>
user: <ssh user>
ssh-key: <which key / alias>
python: 3.11.x
git: configured
deploy-path: /home/<user>/projects/
notes: <anything unusual — open ports, firewall rules, etc.>
```

If you have multiple VMs, list each with a short label (e.g. `vm-do-nyc` for a DigitalOcean NYC droplet).

---

## Source control

```
github-user: <your GitHub username>
bitbucket-user: <your Bitbucket username>
default-remote: github   # or bitbucket
ssh-key-alias: <e.g. id_ed25519_personal>
repo-naming: <slug>      # one repo per project, named by slug
```

---

## Secrets handling

- Secrets live in `.env` at project root. Never committed.
- `.env.example` is committed with all keys, no values.
- On VM: `.env` is placed manually after fresh clone. Not synced via git.
- No secrets manager unless a project explicitly requires one.

---

## Deploy pattern (Tier 1)

Default deploy to VM:

```bash
# On VM
cd ~/projects/<slug>
git pull
# if dependencies changed:
pip install -r requirements.txt --break-system-packages
# restart if running as a service:
sudo systemctl restart <slug>
```

Projects that run as a service get a systemd unit file. Claude Code generates it if the spec says "run as a service."

Template unit file location: `/etc/systemd/system/<slug>.service`

---

## Tier 2 (cloud) — when used

Fill in only if/when you have standing cloud infra:

```
provider: <AWS / GCP / DO / etc.>
region: <region>
access: <how you authenticate — profile name, key alias, etc.>
notes: <any standing resources — S3 buckets, VPCs, etc.>
```

---

## Networking / ports

- Local projects: no port allocation needed.
- VM projects that expose HTTP: use port 8000+ range. Document the port in `run.md`.
- No reverse proxy unless the project needs external HTTPS. If it does: nginx, simplest config.

---

## Notes / one-offs

Add anything that doesn't fit above — unusual dependencies, standing integrations, machines that are offline, etc.
