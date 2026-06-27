# ansible-role-semaphoreui

Ansible role to install and configure [SemaphoreUI](https://semaphoreui.com/) on Debian/Ubuntu and RHEL/Rocky/Alma Linux systems.

Installs Semaphore via the official `.deb` or `.rpm` package from GitHub releases, configures a systemd service, sets up the selected database backend, and optionally builds and runs Caddy as an HTTPS reverse proxy via xcaddy.

---

## Requirements

- Ansible >= 2.14
- `community.mysql` collection (required when `semaphore_db_dialect: mysql`)
- `community.postgresql` collection (required when `semaphore_db_dialect: postgres`)
- `community.general` collection (required when `semaphore_install_xcaddy: true`)

---

## Supported Platforms

| Distribution | Versions |
|---|---|
| Debian | Bullseye, Bookworm |
| Ubuntu | Focal, Jammy, Noble |
| RHEL / Rocky / Alma | 8, 9 |

---

## Role Variables

### Core

| Variable | Default | Description |
|---|---|---|
| `semaphore_version` | `2.18.12` | SemaphoreUI release version to install |
| `semaphore_web_host` | `0.0.0.0` | Address SemaphoreUI binds to |
| `semaphore_port` | `3000` | Port SemaphoreUI listens on |
| `semaphore_release_base_url` | GitHub releases URL | Override for air-gapped environments |

### Paths

| Variable | Default | Description |
|---|---|---|
| `semaphore_bin_dir` | `/usr/bin` | Directory containing the semaphore binary |
| `semaphore_config_dir` | `/etc/semaphore` | Configuration directory |
| `semaphore_data_dir` | `/var/lib/semaphore` | Persistent data directory |
| `semaphore_tmp_dir` | `/tmp/semaphore` | Temporary working directory |

### Service User

| Variable | Default | Description |
|---|---|---|
| `semaphore_user` | `semaphore` | System user that runs the service |
| `semaphore_group` | `semaphore` | System group for the service user |
| `semaphore_user_home` | `/home/semaphore` | Home directory for the service user |

### Admin Account

Created on first run only. Subsequent runs are idempotent.

| Variable | Default | Description |
|---|---|---|
| `semaphore_admin_user` | `admin` | Admin login name |
| `semaphore_admin_password` | `changeme` | Admin password |
| `semaphore_admin_email` | `admin@localhost` | Admin email address |
| `semaphore_admin_name` | `Admin` | Admin display name |

### Database

| Variable | Default | Description |
|---|---|---|
| `semaphore_db_dialect` | `sqlite` | Database backend: `sqlite`, `mysql`, or `postgres` |

**SQLite** (default):

| Variable | Default | Description |
|---|---|---|
| `semaphore_sqlite_db_path` | `{{ semaphore_data_dir }}/database.sqlite` | Path to the SQLite database file |

**MySQL / MariaDB** (`semaphore_db_dialect: mysql`):

| Variable | Default | Description |
|---|---|---|
| `semaphore_mysql_host` | `127.0.0.1:3306` | MySQL host:port |
| `semaphore_mysql_user` | `semaphore` | MySQL user |
| `semaphore_mysql_password` | `changeme_mysql` | MySQL user password |
| `semaphore_mysql_db` | `semaphore` | MySQL database name |
| `semaphore_mysql_root_password` | `""` | Root password used to create the DB/user (local installs) |
| `semaphore_mysql_client_host` | `127.0.0.1` | Host the semaphore user connects from |

**PostgreSQL** (`semaphore_db_dialect: postgres`):

| Variable | Default | Description |
|---|---|---|
| `semaphore_postgres_host` | `127.0.0.1:5432` | PostgreSQL host:port |
| `semaphore_postgres_user` | `semaphore` | PostgreSQL role |
| `semaphore_postgres_password` | `changeme_postgres` | PostgreSQL role password |
| `semaphore_postgres_db` | `semaphore` | PostgreSQL database name |

### Caddy / xcaddy (optional)

| Variable | Default | Description |
|---|---|---|
| `semaphore_install_xcaddy` | `true` | Install xcaddy (requires Go toolchain download) |
| `semaphore_install_only_xcaddy` | `false` | Install xcaddy only; skip building Caddy |
| `semaphore_caddy_enable_https` | `true` | Build Caddy and run it as an HTTPS reverse proxy |
| `semaphore_caddy_domain` | `""` | Public hostname for ACME certificates. Leave empty for a self-signed internal cert |
| `semaphore_caddy_cloudflare_api_token` | `""` | Cloudflare API token for DNS-01 challenge. When set, Caddy uses the Cloudflare DNS plugin instead of HTTP-01 |
| `semaphore_caddy_dns_resolvers` | `["1.1.1.1", "1.0.0.1"]` | DNS resolvers used by Caddy to verify propagation during the Cloudflare challenge |
| `semaphore_caddy_upstream` | `127.0.0.1:{{ semaphore_port }}` | Upstream address Caddy proxies to |
| `semaphore_caddy_config_dir` | `/etc/caddy` | Caddy configuration directory |
| `semaphore_caddy_data_dir` | `/var/lib/caddy` | Caddy data/state directory |
| `semaphore_go_version` | `1.24.5` | Go version used to build xcaddy |
| `semaphore_caddy_xcaddy_plugins` | `[github.com/caddy-dns/cloudflare@latest]` | xcaddy plugins to compile into the Caddy binary |

---

## Example Playbooks

### Minimal — SQLite, no Caddy

```yaml
- hosts: semaphore
  roles:
    - role: jershbytes.semaphoreui
      vars:
        semaphore_install_xcaddy: false
        semaphore_admin_password: "s3cr3t"
```

### MariaDB backend with Caddy HTTPS + Cloudflare DNS challenge

```yaml
- hosts: semaphore
  roles:
    - role: jershbytes.semaphoreui
      vars:
        semaphore_db_dialect: mysql
        semaphore_mysql_root_password: "rootpassword"
        semaphore_mysql_password: "semaphorepassword"
        semaphore_caddy_domain: "semaphore.example.com"
        semaphore_caddy_cloudflare_api_token: "your-cloudflare-api-token"
        semaphore_admin_password: "s3cr3t"
```

### PostgreSQL backend, no Caddy

```yaml
- hosts: semaphore
  roles:
    - role: jershbytes.semaphoreui
      vars:
        semaphore_db_dialect: postgres
        semaphore_postgres_password: "semaphorepassword"
        semaphore_install_xcaddy: false
        semaphore_admin_password: "s3cr3t"
```

---

## License

MIT

## Author

[jershbytes](https://github.com/jershbytes)
