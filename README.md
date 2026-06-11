<h1 align="center">
  semaphore-ansible
</h1>

Ansible automation to install and configure **SemaphoreUI v2.18.12** on:

- **Proxmox VMs** — Debian/Ubuntu, x86_64
- **Raspberry Pi** — Raspberry Pi OS / Debian, ARM64 or ARMv7

SemaphoreUI is an open-source web UI for running Ansible playbooks, Terraform, and other DevOps tools without touching the terminal.

---

## Requirements

**On your controller machine (the machine you run Ansible from):**

- [uv](https://docs.astral.sh/uv/getting-started/installation/) — fast Python package manager
- [just](https://github.com/casey/just#installation) — command runner (`brew install just` / `cargo install just` / distro package)

**On target hosts:**

- Debian 11+, Ubuntu 20.04+, or Raspberry Pi OS (Bullseye/Bookworm)
- SSH access with sudo privileges

---

## Quick Start

### 1. Clone and bootstrap

```bash
git clone https://github.com/jershbytes/semaphore-ansible.git semaphore-ansible
cd semaphore-ansible

# Creates .venv, installs Ansible + all dependencies, installs Galaxy collections
just install
```

That's it for setup. `just install` handles everything — no manual `pip install` needed.

### 2. Point it at your hosts

Edit `inventory/hosts.yml` with the IP addresses and SSH users for your machines:

```yaml
proxmox_vms:
  hosts:
    semaphore-vm:
      ansible_host: 192.168.1.100   # your VM's IP
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_rsa

raspberrypi:
  hosts:
    semaphore-pi:
      ansible_host: 192.168.1.101   # your Pi's IP
      ansible_user: pi
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 3. Deploy

```bash
just deploy          # all hosts
just proxmox         # Proxmox VMs only
just pi              # Raspberry Pi only
just check           # dry-run first (no changes made)
```

Once complete, SemaphoreUI is available at `http://<host-ip>:3000`.

---

## just recipes

Run `just` with no arguments to see all available commands.

| Recipe | What it does |
|---|---|
| `just install` | Bootstrap venv + install Galaxy collections |
| `just deploy` | Full install/update on all hosts |
| `just proxmox` | Deploy to Proxmox VMs only |
| `just pi` | Deploy to Raspberry Pi only |
| `just check` | Dry-run with diff (no changes applied) |
| `just ping` | Test SSH connectivity to all hosts |
| `just upgrade 2.19.0` | Upgrade Semaphore to a specific version |
| `just lint` | Lint playbooks and roles with ansible-lint |
| `just vault-create` | Create an encrypted secrets file |
| `just vault-edit` | Edit an existing secrets file |
| `just versions` | Show Python / Ansible versions in use |
| `just clean` | Remove `.venv` and temp files |

Pass extra Ansible flags to any recipe by appending them:

```bash
just deploy --ask-become-pass        # prompt for sudo password
just deploy -e semaphore_port=8080   # override a variable inline
```

---

## Project Structure

```
semaphore-ansible/
├── justfile                           # Task runner (start here)
├── pyproject.toml                     # Python deps managed by uv
├── ansible.cfg                        # Ansible configuration
├── requirements.yml                   # Ansible Galaxy collections
├── site.yml                           # Main playbook
├── inventory/
│   ├── hosts.yml                      # Your hosts (edit this)
│   └── group_vars/
│       ├── all.yml                    # Shared variables
│       ├── proxmox_vms.yml            # Proxmox-specific overrides
│       └── raspberrypi.yml            # Pi-specific overrides
└── roles/
    └── semaphoreui/
        ├── defaults/main.yml          # All role settings (override freely)
        ├── tasks/
        │   ├── dependencies.yml       # OS packages
        │   ├── database.yml           # DB install (SQLite/MariaDB/Postgres)
        │   ├── user.yml               # semaphore service user + dirs
        │   ├── install.yml            # Download & install binary
        │   ├── python.yml             # Ansible + pip setup on target
        │   └── configure.yml          # config.json, systemd, admin user
        └── templates/
            ├── config.json.j2         # SemaphoreUI config file
            └── semaphore.service.j2   # systemd service unit
```

---

## Configuration

All settings live in `roles/semaphoreui/defaults/main.yml`. Override them in `inventory/group_vars/all.yml` or pass `-e var=value` on the command line.

### Common variables

| Variable | Default | Description |
|---|---|---|
| `semaphore_version` | `2.18.12` | Version to install |
| `semaphore_port` | `3000` | Web UI port |
| `semaphore_db_dialect` | `sqlite` | Database: `sqlite`, `mysql`, `postgres` |
| `semaphore_admin_user` | `admin` | First admin login |
| `semaphore_admin_password` | `changeme` | First admin password — **change this** |
| `semaphore_admin_email` | `admin@localhost` | Admin email |
| `semaphore_use_venv` | `false` | Run Ansible in a Python virtualenv on the target |
| `semaphore_configure_ufw` | `false` | Open the port in ufw |

---

## Database Options

Set `semaphore_db_dialect` to one of the three options. The role installs and configures the database automatically — no manual setup required.

### SQLite (default)

Zero configuration. Best for single-host installs and getting started quickly.

```yaml
# inventory/group_vars/all.yml
semaphore_db_dialect: sqlite
```

### MariaDB / MySQL

The role installs MariaDB, creates the database, and creates the user.

```yaml
# inventory/group_vars/all.yml
semaphore_db_dialect: mysql
semaphore_mysql_root_password: "{{ vault_mysql_root_password }}"
semaphore_mysql_password: "{{ vault_semaphore_mysql_password }}"
```

### PostgreSQL

The role installs PostgreSQL, creates the database, and creates the role.

```yaml
# inventory/group_vars/all.yml
semaphore_db_dialect: postgres
semaphore_postgres_password: "{{ vault_semaphore_postgres_password }}"
```

---

## Keeping Secrets Safe with Ansible Vault

Never commit passwords in plain text. Use Ansible Vault instead:

```bash
# Create an encrypted secrets file
just vault-create
```

Add your secrets to the file:

```yaml
# inventory/group_vars/vault.yml  (encrypted)
vault_semaphore_admin_password: "MyStr0ngPassw0rd!"
vault_mysql_root_password: "RootPassw0rd!"
vault_semaphore_mysql_password: "AppPassw0rd!"
```

Reference them in `inventory/group_vars/all.yml`:

```yaml
semaphore_admin_password: "{{ vault_semaphore_admin_password }}"
semaphore_mysql_root_password: "{{ vault_mysql_root_password }}"
semaphore_mysql_password: "{{ vault_semaphore_mysql_password }}"
```

Deploy with vault decryption:

```bash
just deploy --ask-vault-pass
```

---

## Architecture Support

The role auto-detects the CPU and fetches the right binary — no manual selection needed.

| Architecture | Target |
|---|---|
| `x86_64` | Proxmox VMs, standard servers |
| `aarch64` | Raspberry Pi 4 / 5 (64-bit OS) |
| `armv7l` | Raspberry Pi 2 / 3 (32-bit OS) |
| `armv6l` | Raspberry Pi Zero / Zero W |

---

## Upgrading SemaphoreUI

```bash
just upgrade 2.19.0            # all hosts
just upgrade-proxmox 2.19.0    # Proxmox VMs only
just upgrade-pi 2.19.0         # Raspberry Pi only
```

---

## Managing the Service on Target Hosts

```bash
sudo systemctl status semaphore    # check status
sudo journalctl -u semaphore -f    # follow logs
sudo systemctl restart semaphore   # restart
```
