# LangGe Dujiao-Next Install Script

Language: **English** | [简体中文](./README.zh-CN.md)

> Maintainer: LangGe  
> Telegram: [@luoyanglang](https://t.me/luoyanglang)

## Overview

`langge-dujiao-next-install` is a community-maintained one-click deploy and ops script for Dujiao-Next.

It supports:

- Docker Compose deployment
- Binary deployment
- HTTPS setup
- Version check
- Basic daily operations
- Optional system hardening

This project is published as an independent community script and does not replace the official community deployment script.

## Use Cases

This script is a good fit for:

- new users who want to deploy `api + user + admin` quickly
- operators who want one unified entry for deploy, update, HTTPS, ops, and basic hardening
- users switching between Docker, binary, and panel-based external environments
- teams that want a more standardized deployment workflow with fewer manual steps

Less suitable for:

- heavily customized production orchestration
- teams already using mature IaC / CI/CD pipelines
- servers where SSH, firewall, and hardening changes must be handled manually

## Features

- Menu-driven workflow for deploy, update, HTTPS, ops, and hardening
- Covers `api + user + admin` in one script
- Supports Docker Compose, binary, and external-environment deployment modes
- Includes version checks, service operations, backups, cleanup, and uninstall
- Uses safer state loading logic and avoids direct `curl | sh` for `acme.sh`

## Menu Structure

### Top-Level Menu

The script includes 6 top-level entries:

1. Start Deployment
2. One-Click Update
3. Configure HTTPS
4. Daily Operations
5. Check Versions
6. System Hardening

### 1. Start Deployment

Second-level deployment modes:

1. Docker deployment
2. Binary deployment
3. External environment deployment

#### 1.1 Docker deployment

Capabilities include:

- Auto install / check Docker and Docker Compose
- Docker mirror setup
- Redis kernel parameter fixes
- Database mode selection:
  - SQLite + Redis
  - PostgreSQL + Redis
- Version tag selection
- Custom deploy directory, timezone, API/User/Admin ports
- Redis port and password setup
- PostgreSQL port / db / user / password setup
- Default admin username and password setup
- Domain collection for User / Admin / API
- Optional HTTPS and ACME email configuration
- Auto-generated `.env`, `config.yml`, and compose files
- Image pull and service startup
- API health checks
- Optional Nginx reverse proxy and HTTPS setup
- Local deployment state persistence

#### 1.2 Binary deployment

Capabilities include:

- Linux architecture detection (`x86_64` / `arm64`)
- Auto install required tools and Redis / Nginx
- Download API / User / Admin release packages
- Extract and install API binary and frontend assets
- Generate API config, JWT, Redis, and queue settings
- Configure default admin account
- Write and enable a systemd service
- Generate Nginx site config
- Optional HTTPS integration
- Save local deployment state

#### 1.3 External environment deployment

For environments that already have 1Panel, Baota, PostgreSQL, Redis, or custom infra.

Capabilities include:

- Detect and choose existing Docker networks
- Custom version tag, deploy directory, and ports
- External PostgreSQL connection setup
- External Redis connection setup
- Default admin account setup
- Auto-generate `config.yml` and `docker-compose.yml`
- Pull and start containers
- Save local deployment state
- Output reverse proxy instructions for panel-based setups

### 2. One-Click Update

Capabilities include:

- Read existing deployment state
- Compare current version with latest release
- Allow manual target version input
- Update by deployment mode:
  - Docker: change tag in `.env`, pull and restart
  - Binary: download and replace API / User / Admin packages
  - External: update image tags in `docker-compose.yml` and restart
- Write updated deployment state

### 3. Configure HTTPS

Mode-specific HTTPS flow:

- Docker: Caddy auto issuance and renewal
- Binary: `acme.sh` + Nginx
- External: guidance only, handled in panel

Capabilities include:

- Domain resolution checks
- Certificate issuance
- Caddy / Nginx config generation
- Renewal task setup
- HTTPS state persistence

### 4. Daily Operations

Second-level menu:

1. View service status
2. View logs
3. Restart services
4. Backup database
5. Clean Docker resources
6. Uninstall system

Capabilities include:

- Status checks for Docker / systemd services
- API health checks
- Log viewing for API / User / Admin / all
- Restart API / User / Admin / Nginx / all
- SQLite / PostgreSQL backup
- Upload directory backup
- Docker cleanup
- Full uninstall with install dir, state file, and Nginx cleanup

### 5. Check Versions

Capabilities include:

- Read saved deployment metadata
- Fetch latest releases from upstream repos
- Compare local API / User / Admin versions with latest versions
- Show deploy mode, install dir, db mode, HTTPS state, and domain info

### 6. System Hardening

Capabilities include:

- SSH / panel / custom port setup
- Lynis install and checks
- Package upgrade and unattended upgrades
- SSH baseline hardening
- `sshd_config` validation and rollback
- `rsyslog` setup
- Kernel hardening via `sysctl`
- File permission tightening
- Fail2ban install and SSH jail
- UFW firewall setup
- Docker + UFW rule coordination
- UFW rollback on failure
- Disable risky protocols and USB storage
- Password policy and login restrictions

## Safety Notes

Compared with simpler remote-execution scripts, this project includes extra safeguards:

- Deployment state is not loaded via direct `source state.env`
- `acme.sh` is downloaded to a local temporary file before execution
- Shell files are forced to use `LF` via `.gitattributes`

## Risk Notes

Please be aware of the following:

- the script modifies deploy directories, config files, Nginx, systemd, and Docker resources
- HTTPS setup writes Caddy or Nginx config and requests certificates
- system hardening modifies:
  - SSH config
  - UFW firewall
  - Fail2ban
  - password policies
  - kernel hardening settings
- binary deployment writes a systemd unit
- default admin credentials are for bootstrap only and must be changed immediately

Recommended:

- test on a staging server first
- take snapshots or backups before running in production
- run the hardening menu only on a controllable or rollback-friendly server
- confirm security-group and firewall rules before changing SSH ports

## Requirements

- It is recommended to run the script as `root`
- If you are not using `root`, switch to `root` first or make sure the current user has full `sudo` privileges
- Linux
- `bash`
- `curl`
- `openssl`

For Docker mode:

- `docker`
- `docker compose`

For binary mode:

- `tar`
- `unzip`

## Quick Start

Before running the script, make sure the current shell has `root` privileges, for example:

```bash
sudo -i
```

or:

```bash
su - root
```

Recommended:

```bash
curl -fsSL https://raw.githubusercontent.com/dujiao-next/community-projects/main/scripts/langge-dujiao-next-install/dujiao-next-install.sh -o dujiao-next-install.sh
bash dujiao-next-install.sh
```

Mirror download:

```bash
curl -fsSL https://down.dujiao-next.cc/dujiao-next-install.sh -o dujiao-next-install.sh
bash dujiao-next-install.sh
```

Or run from local repository:

```bash
bash dujiao-next-install.sh
```

## Screenshots

### Main Menu
![Main Menu](./assets/screenshots/main-menu.png)

### Deployment Submenu
![Deployment Submenu](./assets/screenshots/deploy-menu.png)

### Docker Deployment Flow
![Docker Deployment Flow](./assets/screenshots/docker-deploy.png)

### Binary Deployment Flow
![Binary Deployment Flow](./assets/screenshots/binary-deploy.png)

### Daily Operations Menu
![Daily Operations Menu](./assets/screenshots/ops-menu.png)

### Version Check
![Version Check](./assets/screenshots/update-check.png)

### Version Check Details
![Version Check Details](./assets/screenshots/update-check1.png)

### System Hardening
![System Hardening](./assets/screenshots/security-hardening.png)

## Project Layout

```text
langge-dujiao-next-install/
  dujiao-next-install.sh
  assets/screenshots/
  README.md
  README.zh-CN.md
  LICENSE
  .gitattributes
```

## Compatibility

- Designed for Dujiao-Next community deployments
- Recommended to test on a fresh Debian / Ubuntu server before production use

## License

MIT. See [LICENSE](./LICENSE).
