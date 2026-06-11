# semaphore-ansible

Ansible role to install and configure **SemaphoreUI v2.18.12** on:

- **Proxmox VMs** (Debian/Ubuntu, x86_64 / amd64)
- **Raspberry Pi** (Raspberry Pi OS / Debian, ARM64 or ARMv7)

SemaphoreUI is a modern open-source web UI for running Ansible playbooks, Terraform, and other DevOps tools.

---

## Project Structure

```
semaphore-ansible/
├── ansible.cfg                        # Project-level Ansible config
├── requirements.yml                   # Galaxy collection dependencies
├── site.yml                           # Main playbook entry point
├── inventory/
│   ├── hosts.yml                      # Host definitions
│   └── group_vars/
│       ├── all.yml                    # Vars common to all hosts
│       ├── proxmox_vms.yml            # Proxmox VM overrides
│       └── raspberrypi.yml            # Raspberry Pi overrides
└── roles/
    └── semaphoreui/
        ├── defaults/main.yml          # Role defaults (override freely)
        ├── vars/main.yml              # Internal computed variables
        ├── tasks/
        │   ├── main.yml               # Task orchestration
        │   ├── dependencies.yml       # OS package dependencies
        │   ├── user.yml               # Service user & directories
        │   ├── install.yml            # Download & install binary
        │   ├── python.yml             # Python/Ansible pip setup
        │   └── configure.yml          # Config, systemd, admin user
        ├── templates/
        │   ├── config.json.j2         # SemaphoreUI config file
        │   └── semaphore.service.j2   # systemd service unit
        ├── handlers/main.yml          # Service restart/reload handlers
        └── meta/main.yml              # Role metadata
```

---

## Quick Start

### 1. Install Ansible and required Galaxy collections

```bash
pip install ansible
ansible-galaxy collection install -r requirements.yml
```

### 2. Configure your inventory

Edit `inventory/hosts.yml` and set the correct IP addresses and SSH users for your hosts:

```yaml
proxmox_vms:
  hosts:
    semaphore-vm:
      ansible_host: 192.168.1.100
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_rsa

raspberrypi:
  hosts:
    semaphore-pi:
      ansible_host: 192.168.1.101
      ansible_user: pi
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 3. Run the playbook

**All hosts:**
```bash
ansible-playbook site.yml
```

**Only Proxmox VMs:**
```bash
ansible-playbook site.yml --limit proxmox_vms
```

**Only Raspberry Pi:**
```bash
ansible-playbook site.yml --limit raspberrypi
```

**Dry-run (check mode):**
```bash
ansible-playbook site.yml --check --diff
```

---

## Configuration

All role configuration lives in `roles/semaphoreui/defaults/main.yml`. Override any variable via inventory `group_vars`, host `host_vars`, or by passing `-e` on the command line.

### Key Variables

| Variable | Default | Description |
|---|---|---|
| `semaphore_version` | `2.18.12` | SemaphoreUI release to install |
| `semaphore_port` | `3000` | Port the web UI listens on |
| `semaphore_web_host` | `0.0.0.0` | Bind interface |
| `semaphore_db_dialect` | `bolt` | Database backend: `bolt`, `mysql`, `postgres` |
| `semaphore_admin_user` | `admin` | Initial admin username |
| `semaphore_admin_password` | `changeme` | Initial admin password (**change this!**) |
| `semaphore_admin_email` | `admin@localhost` | Initial admin email |
| `semaphore_install_ansible_pip` | `true` | Install Ansible via pip for service user |
| `semaphore_use_venv` | `false` | Use a Python virtualenv instead of user-context pip |
| `semaphore_configure_ufw` | `false` | Open the port via ufw |

### Changing the Admin Password

**Option A** — override via inventory group_vars (recommended for non-sensitive defaults):

```yaml
# inventory/group_vars/all.yml
semaphore_admin_password: "MyStr0ngPassw0rd!"
```

**Option B** — use Ansible Vault for secrets:

```bash
ansible-vault create inventory/group_vars/vault.yml
```

```yaml
# inventory/group_vars/vault.yml
vault_semaphore_admin_password: "MyStr0ngPassw0rd!"
vault_semaphore_cookie_hash: "random-32-char-string"
vault_semaphore_cookie_encryption: "random-32-char-string"
vault_semaphore_access_key_encryption: "random-32-char-string"
```

```yaml
# inventory/group_vars/all.yml
semaphore_admin_password: "{{ vault_semaphore_admin_password }}"
```

Run with vault:

```bash
ansible-playbook site.yml --ask-vault-pass
```

### Using MySQL / MariaDB

```yaml
# inventory/group_vars/all.yml
semaphore_db_dialect: mysql
semaphore_mysql_host: "127.0.0.1:3306"
semaphore_mysql_user: semaphore
semaphore_mysql_password: "{{ vault_semaphore_mysql_password }}"
semaphore_mysql_db: semaphore
```

### Using PostgreSQL

```yaml
semaphore_db_dialect: postgres
semaphore_postgres_host: "127.0.0.1:5432"
semaphore_postgres_user: semaphore
semaphore_postgres_password: "{{ vault_semaphore_postgres_password }}"
semaphore_postgres_db: semaphore
```

### Python Virtual Environment

```yaml
semaphore_use_venv: true
semaphore_venv_path: /home/semaphore/venv
```

---

## Architecture Support

The role automatically detects the target CPU architecture and downloads the correct SemaphoreUI binary:

| `ansible_architecture` | SemaphoreUI arch | Target platform |
|---|---|---|
| `x86_64` | `amd64` | Proxmox VM / standard x86 |
| `aarch64` | `arm64` | Raspberry Pi 4/5 (64-bit OS), modern ARM |
| `armv7l` | `arm` | Raspberry Pi 3/2 (32-bit OS) |
| `armv6l` | `arm` | Raspberry Pi Zero, Zero W |

---

## Service Management

After installation, manage the service with:

```bash
# Status
sudo systemctl status semaphore

# Logs
sudo journalctl -u semaphore -f

# Restart
sudo systemctl restart semaphore

# Stop
sudo systemctl stop semaphore
```

---

## Upgrading SemaphoreUI

Change the version variable and re-run the playbook:

```bash
ansible-playbook site.yml -e semaphore_version=2.19.0
```

---

## Requirements

- **Controller:** Ansible >= 2.14, Python 3.8+
- **Target hosts:** Debian 11+, Ubuntu 20.04+, or Raspberry Pi OS (Bullseye/Bookworm)
- **SSH access** with sudo privileges on target hosts
