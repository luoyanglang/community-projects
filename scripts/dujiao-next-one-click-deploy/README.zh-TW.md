# Dujiao-Next One Click Deploy

語言 / Language： [English](./README.md) | [简体中文](./README.zh-CN.md) | **繁體中文**

> 維護者：Dujiao-Next  

## 1. 專案簡介

`dujiao-next-one-click-deploy` 是給新手使用者的部署腳本。
提供選單式互動，支援兩種部署方式：

- Docker Compose 部署（`api + user + admin`）
- 二進位部署（`api + user + admin`）

同時提供「檢查更新」功能，方便快速確認是否需要升級。
並支援 ACME 自動申請 HTTPS 憑證。

## 2. 功能列表

- 選單化入口：
  - `1. 開始部署`
  - `2. 檢查更新`
  - `3. 配置 HTTPS (ACME)`
- 可選部署模式：
  - Docker Compose（支援 SQLite + Redis / PostgreSQL + Redis）
  - 二進位（支援 Linux x86_64 / arm64）
- 自動生成部署設定（`.env`、`config.yml`、compose 檔）
- 自動下載三端 Release 包（二進位模式）
- 可選建立 `systemd` 服務（`dujiao-next-api.service`）
- 生成 Nginx 設定範本（User / Admin）
- 自動申請與續期 HTTPS 憑證（Docker: Caddy ACME / Binary: acme.sh）

## 3. 環境需求

### 3.1 通用

- `bash`
- `curl`
- `openssl`

### 3.2 Docker 模式

- `docker`（包含 `docker compose`）

### 3.3 二進位模式

- Linux x86_64 / arm64
- `tar`
- `unzip`

## 4. 使用方式

### 4.1 直接執行（無需 clone 倉庫）

```bash
curl -fsSL https://raw.githubusercontent.com/dujiao-next/community-projects/main/scripts/dujiao-next-one-click-deploy/deploy.sh | bash
```

### 4.2 下載單檔後執行

```bash
curl -fsSL https://raw.githubusercontent.com/dujiao-next/community-projects/main/scripts/dujiao-next-one-click-deploy/deploy.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh
```

## 5. 選單說明

### 5.1 開始部署

- 先選擇部署方式：
  - Docker Compose
  - 二進位
- 依提示輸入部署目錄、版本、埠號、預設管理員資訊等參數。

### 5.2 檢查更新

- 腳本會讀取本地紀錄（`~/.dujiao-next-one-click/state.env`）
- 比對 `api/user/admin` 的目前版本與線上最新版本
- 輸出更新建議

### 5.3 配置 HTTPS (ACME)

- 需先完成一次部署（Docker 或二進位）
- 需先將 User/Admin 網域解析到伺服器公網 IP
- Docker 模式會啟用 Caddy 自動簽發與續期憑證
- 二進位模式會使用 acme.sh 簽發憑證，並生成 Nginx HTTPS 範本

驗證命令範例：

```bash
curl -I https://你的-user-網域
curl -I https://你的-admin-網域
openssl s_client -connect 你的-user-網域:443 -servername 你的-user-網域 </dev/null | openssl x509 -noout -dates
```

## 6. 目錄結構

```text
dujiao-next-one-click-deploy/
  deploy.sh
  README.md
  README.zh-CN.md
  README.zh-TW.md
  LICENSE
```

## 7. FAQ

### Q1: 二進位模式顯示平台不支援怎麼辦？

目前版本支援 Linux x86_64 與 arm64。其他平台建議先使用 Docker Compose 模式。

### Q2: 檢查更新顯示沒有本地紀錄怎麼辦？

先使用本腳本部署一次，腳本會自動建立狀態檔。

### Q3: 二進位模式會自動修改 Nginx 嗎？

預設會先產生範本；可依提示選擇是否自動寫入 `/etc/nginx/conf.d` 並重載。

### Q4: HTTPS 配置提示網域解析失敗怎麼辦？

先確認 A/AAAA 記錄已生效，再重試「3. 配置 HTTPS (ACME)」。

## 8. 授權

MIT，詳見 `LICENSE`。
