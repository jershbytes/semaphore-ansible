# justfile — SemaphoreUI Ansible automation task runner
# Install 'just': https://github.com/casey/just
#
# Usage:
#   just            → list all available recipes
#   just install    → bootstrap Python venv + Galaxy collections
#   just deploy     → run full playbook against all hosts

set dotenv-load := false

# Virtual env python / ansible binaries (managed by uv)
venv_python := ".venv/bin/python"
venv_ansible := ".venv/bin/ansible"
venv_playbook := ".venv/bin/ansible-playbook"
venv_galaxy  := ".venv/bin/ansible-galaxy"
venv_lint    := ".venv/bin/ansible-lint"
venv_vault   := ".venv/bin/ansible-vault"

inventory := "inventory/hosts.yml"

# ── Bootstrap ─────────────────────────────────────────────────────────────────

# Install Python deps with uv and Ansible Galaxy collections
install:
    @echo ">>> Creating/updating Python venv with uv..."
    uv sync
    @echo ">>> Installing Ansible Galaxy collections..."
    {{venv_galaxy}} collection install -r requirements.yml --upgrade -p .ansible/collections
    @echo ">>> Done. Run 'just deploy' to install SemaphoreUI."

# ── Deployment ────────────────────────────────────────────────────────────────

# Deploy SemaphoreUI to all hosts
deploy *args:
    {{venv_playbook}} -i {{inventory}} site.yml {{args}}

# Deploy only to Proxmox VMs
proxmox *args:
    {{venv_playbook}} -i {{inventory}} site.yml --limit proxmox_vms {{args}}

# Deploy only to Raspberry Pi hosts
pi *args:
    {{venv_playbook}} -i {{inventory}} site.yml --limit raspberrypi {{args}}

# Dry-run (check + diff) against all hosts
check *args:
    {{venv_playbook}} -i {{inventory}} site.yml --check --diff {{args}}

# Dry-run only against Proxmox VMs
check-proxmox *args:
    {{venv_playbook}} -i {{inventory}} site.yml --limit proxmox_vms --check --diff {{args}}

# Dry-run only against Raspberry Pi
check-pi *args:
    {{venv_playbook}} -i {{inventory}} site.yml --limit raspberrypi --check --diff {{args}}

# ── Inventory helpers ─────────────────────────────────────────────────────────

# Ping all hosts to verify connectivity
ping:
    {{venv_ansible}} -i {{inventory}} all -m ping

# Show gathered facts for all hosts
facts *hosts="all":
    {{venv_ansible}} -i {{inventory}} {{hosts}} -m ansible.builtin.setup

# List all hosts in the inventory
hosts:
    {{venv_ansible}} -i {{inventory}} all --list-hosts

# ── Tags ──────────────────────────────────────────────────────────────────────

# List all available tags in the playbook
tags:
    {{venv_playbook}} -i {{inventory}} site.yml --list-tags

# Run only tasks matching a specific tag  (e.g. just run-tag install)
run-tag tag *args:
    {{venv_playbook}} -i {{inventory}} site.yml --tags {{tag}} {{args}}

# ── Vault ─────────────────────────────────────────────────────────────────────

# Create a new encrypted vault file
vault-create file="inventory/group_vars/vault.yml":
    {{venv_vault}} create {{file}}

# Edit an existing vault file
vault-edit file="inventory/group_vars/vault.yml":
    {{venv_vault}} edit {{file}}

# Encrypt an existing plaintext file in-place
vault-encrypt file:
    {{venv_vault}} encrypt {{file}}

# Decrypt a vault file in-place (use with caution)
vault-decrypt file:
    {{venv_vault}} decrypt {{file}}

# ── Linting ───────────────────────────────────────────────────────────────────

# Lint all playbooks and roles with ansible-lint
lint:
    ANSIBLE_COLLECTIONS_PATH=.ansible/collections uv run ansible-lint -q site.yml

# Lint using yamllint only
yamllint:
    .venv/bin/yamllint -d relaxed .

# ── Upgrade ───────────────────────────────────────────────────────────────────

# Upgrade SemaphoreUI to a specific version on all hosts
upgrade version *args:
    {{venv_playbook}} -i {{inventory}} site.yml -e semaphore_version={{version}} {{args}}

# Upgrade only on Proxmox VMs
upgrade-proxmox version *args:
    {{venv_playbook}} -i {{inventory}} site.yml --limit proxmox_vms -e semaphore_version={{version}} {{args}}

# Upgrade only on Raspberry Pi
upgrade-pi version *args:
    {{venv_playbook}} -i {{inventory}} site.yml --limit raspberrypi -e semaphore_version={{version}} {{args}}

# ── Utility ───────────────────────────────────────────────────────────────────

# Show the uv-managed Python and Ansible versions in use
versions:
    @echo "uv:      $(uv --version)"
    @echo "python:  $({{venv_python}} --version)"
    @echo "ansible: $({{venv_playbook}} --version | head -1)"

# Remove the virtual environment and cached files
clean:
    rm -rf .venv
    find . -name "*.retry" -delete
    @echo "Cleaned up .venv and retry files."
