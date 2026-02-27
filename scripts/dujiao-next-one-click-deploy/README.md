# Dujiao-Next One Click Deploy

Language: **English** | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md)

> Maintainer: Dujiao-Next  

## 1. Overview

`dujiao-next-one-click-deploy` is a menu-driven deployment script for beginners.
It supports two deployment modes for `api + user + admin`:

- Docker Compose deployment
- Binary deployment

It also includes an update check menu to compare local and latest release versions.
HTTPS certificates can be requested automatically via ACME.

## 2. Features

- Menu entry:
  - `1. Start Deployment`
  - `2. Check Updates`
  - `3. Configure HTTPS (ACME)`
- Deployment options:
  - Docker Compose (`SQLite + Redis` or `PostgreSQL + Redis`)
  - Binary mode (`Linux x86_64 / arm64`)
- Auto-generated deployment files (`.env`, `config.yml`, compose files)
- Auto-download release packages in binary mode
- Optional `systemd` setup (`dujiao-next-api.service`)
- Generated Nginx templates for User/Admin
- Auto HTTPS issuance/renewal (Docker: Caddy ACME / Binary: acme.sh)

## 3. Requirements

### 3.1 Common

- `bash`
- `curl`
- `openssl`

### 3.2 Docker mode

- `docker` with `docker compose`

### 3.3 Binary mode

- Linux x86_64 / arm64
- `tar`
- `unzip`

## 4. Quick Start

### 4.1 Run Directly (No Clone)

```bash
curl -fsSL https://raw.githubusercontent.com/dujiao-next/community-projects/main/scripts/dujiao-next-one-click-deploy/deploy.sh | bash
```

### 4.2 Download Single File And Run

```bash
curl -fsSL https://raw.githubusercontent.com/dujiao-next/community-projects/main/scripts/dujiao-next-one-click-deploy/deploy.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh
```

## 5. Menu

### 5.1 Start Deployment

Choose one:

- Docker Compose deployment
- Binary deployment

Then follow prompts for install directory, version tag, ports, and admin defaults.

### 5.2 Check Updates

The script reads local deployment state from:

- `~/.dujiao-next-one-click/state.env`

Then compares local `api/user/admin` versions with latest releases.

### 5.3 Configure HTTPS (ACME)

- You should complete one deployment first (Docker or Binary)
- Make sure User/Admin domains already resolve to your server public IP
- Docker mode enables Caddy for automatic ACME issuance and renewal
- Binary mode uses acme.sh and generates Nginx HTTPS templates

Validation examples:

```bash
curl -I https://your-user-domain
curl -I https://your-admin-domain
openssl s_client -connect your-user-domain:443 -servername your-user-domain </dev/null | openssl x509 -noout -dates
```

## 6. Project Layout

```text
dujiao-next-one-click-deploy/
  deploy.sh
  README.md
  README.zh-CN.md
  README.zh-TW.md
  LICENSE
```

## 7. FAQ

### Q1: Binary mode says platform not supported

Current binary mode supports Linux x86_64 and arm64. Use Docker mode for other platforms.

### Q2: Check Updates says no local deployment state

Run one deployment first. The script will create a state file automatically.

### Q3: Does binary mode modify Nginx automatically?

By default it generates templates. You can choose to auto-write into `/etc/nginx/conf.d` and reload.

### Q4: Why does HTTPS setup say domain resolve failed?

Your DNS A/AAAA record may not be ready yet. Wait for propagation, then run `3. Configure HTTPS (ACME)` again.

## 8. License

MIT. See `LICENSE`.
