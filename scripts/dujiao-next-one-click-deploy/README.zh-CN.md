# Dujiao-Next One Click Deploy

语言 / Language： [English](./README.md) | **简体中文** | [繁體中文](./README.zh-TW.md)

> 维护者：Dujiao-Next  

## 1. 项目简介

`dujiao-next-one-click-deploy` 是一个面向新手用户的部署脚本。
它提供菜单式交互，支持两种部署方式：

- Docker Compose 部署（`api + user + admin`）
- 二进制部署（`api + user + admin`）

并提供「检查更新」功能，帮助你快速判断当前版本是否需要升级。
同时支持 ACME 自动申请 HTTPS 证书。

## 2. 功能列表

- 菜单化入口：
  - `1. 开始部署`
  - `2. 检查更新`
  - `3. 配置 HTTPS (ACME)`
- 部署方式可选：
  - Docker Compose（支持 SQLite + Redis / PostgreSQL + Redis）
  - 二进制（支持 Linux x86_64 / arm64）
- 自动生成部署配置（`.env`、`config.yml`、compose 文件）
- 自动下载三端 Release 包（二进制模式）
- 可选创建 `systemd` 服务（`dujiao-next-api.service`）
- 生成 Nginx 配置模板（User / Admin）
- 自动申请与续期 HTTPS 证书（Docker: Caddy ACME / Binary: acme.sh）

## 3. 环境要求

### 3.1 通用

- `bash`
- `curl`
- `openssl`

### 3.2 Docker 模式

- `docker`（包含 `docker compose`）

### 3.3 二进制模式

- Linux x86_64 / arm64
- `tar`
- `unzip`

## 4. 使用方式

### 4.1 直接运行（无需克隆仓库）

```bash
curl -fsSL https://raw.githubusercontent.com/dujiao-next/community-projects/main/scripts/dujiao-next-one-click-deploy/deploy.sh | bash
```

### 4.2 下载单文件后运行

```bash
curl -fsSL https://raw.githubusercontent.com/dujiao-next/community-projects/main/scripts/dujiao-next-one-click-deploy/deploy.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh
```

## 5. 菜单说明

### 5.1 开始部署

- 先选择部署方式：
  - Docker Compose
  - 二进制
- 根据提示填写目录、版本、端口、默认管理员信息等参数。

### 5.2 检查更新

- 脚本会读取本地记录（`~/.dujiao-next-one-click/state.env`）
- 对比 `api/user/admin` 的当前版本和线上最新版本
- 输出更新建议

### 5.3 配置 HTTPS (ACME)

- 需要先完成一次部署（Docker 或二进制）
- 需要提前把 User/Admin 域名解析到服务器公网 IP
- Docker 模式会启用 Caddy 自动签发和续期证书
- 二进制模式会使用 acme.sh 签发证书，并生成 Nginx HTTPS 模板

验证命令示例：

```bash
curl -I https://你的-user-域名
curl -I https://你的-admin-域名
openssl s_client -connect 你的-user-域名:443 -servername 你的-user-域名 </dev/null | openssl x509 -noout -dates
```

## 6. 目录结构

```text
dujiao-next-one-click-deploy/
  deploy.sh
  README.md
  README.zh-CN.md
  README.zh-TW.md
  LICENSE
```

## 7. FAQ

### Q1: 二进制模式提示平台不支持怎么办？

当前版本支持 Linux x86_64 和 arm64。其他平台请先使用 Docker Compose 模式。

### Q2: 检查更新显示没有本地记录怎么办？

先用本脚本执行一次部署，脚本会自动生成状态文件。

### Q3: 二进制模式会自动配置 Nginx 吗？

默认会生成模板；可按提示选择是否自动写入 `/etc/nginx/conf.d` 并重载。

### Q4: HTTPS 配置提示域名解析失败怎么办？

先确认 A/AAAA 记录已生效，再重试「3. 配置 HTTPS (ACME)」。

## 8. 许可证

MIT，详见 `LICENSE`。
