#!/usr/bin/env bash
set -euo pipefail

DUJIAO_API_REPO="dujiao-next/dujiao-next"
DUJIAO_USER_REPO="dujiao-next/user"
DUJIAO_ADMIN_REPO="dujiao-next/admin"

STATE_DIR="${HOME}/.dujiao-next-one-click"
STATE_FILE="${STATE_DIR}/state.env"

if [[ -t 1 ]]; then
  ANSI_RESET=$'\033[0m'
  ANSI_BOLD=$'\033[1m'
  ANSI_DIM=$'\033[2m'
  ANSI_BRIGHT_MAG=$'\033[95m'
  ANSI_CYAN=$'\033[36m'
  ANSI_BLUE=$'\033[34m'
  ANSI_GREEN=$'\033[32m'
else
  ANSI_RESET=''
  ANSI_BOLD=''
  ANSI_DIM=''
  ANSI_BRIGHT_MAG=''
  ANSI_CYAN=''
  ANSI_BLUE=''
  ANSI_GREEN=''
fi

print_line() {
  printf '%s\n' "------------------------------------------------------------"
}

print_startup_banner() {
  local current_year
  current_year="$(date +%Y)"
  printf '%b\n' "${ANSI_BRIGHT_MAG}╔══════════════════════════════════════════════════════════════════════╗${ANSI_RESET}"
  printf '%b\n' "${ANSI_BRIGHT_MAG}║                   🚀 Dujiao-Next 一键部署工具启动中                 ║${ANSI_RESET}"
  printf '%b\n' "${ANSI_BRIGHT_MAG}╚══════════════════════════════════════════════════════════════════════╝${ANSI_RESET}"
  printf '%b\n' "${ANSI_CYAN}██████╗ ██╗   ██╗     ██╗ █████╗  ██████╗      ███╗   ██╗███████╗██╗  ██╗████████╗${ANSI_RESET}"
  printf '%b\n' "${ANSI_CYAN}██╔══██╗██║   ██║     ██║██╔══██╗██╔═══██╗     ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝${ANSI_RESET}"
  printf '%b\n' "${ANSI_CYAN}██║  ██║██║   ██║     ██║███████║██║   ██║     ██╔██╗ ██║█████╗   ╚███╔╝    ██║   ${ANSI_RESET}"
  printf '%b\n' "${ANSI_CYAN}██║  ██║██║   ██║██   ██║██╔══██║██║   ██║     ██║╚██╗██║██╔══╝   ██╔██╗    ██║   ${ANSI_RESET}"
  printf '%b\n' "${ANSI_CYAN}██████╔╝╚██████╔╝╚█████╔╝██║  ██║╚██████╔╝     ██║ ╚████║███████╗██╔╝ ██╗   ██║   ${ANSI_RESET}"
  printf '%b\n' "${ANSI_CYAN}╚═════╝  ╚═════╝  ╚════╝ ╚═╝  ╚═╝ ╚═════╝      ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝   ${ANSI_RESET}"
  printf '%b\n' "${ANSI_GREEN}${ANSI_BOLD}Open Source Repositories${ANSI_RESET}"
  printf '%b\n' "${ANSI_BLUE}• Root:    https://github.com/dujiao-next${ANSI_RESET}"
  printf '%b\n' "${ANSI_BLUE}• API:     https://github.com/dujiao-next/dujiao-next${ANSI_RESET}"
  printf '%b\n' "${ANSI_BLUE}• User:    https://github.com/dujiao-next/user${ANSI_RESET}"
  printf '%b\n' "${ANSI_BLUE}• Admin:   https://github.com/dujiao-next/admin${ANSI_RESET}"
  printf '%b\n' "${ANSI_BLUE}• Official:https://github.com/dujiao-next/document${ANSI_RESET}"
  printf '%b\n' "${ANSI_DIM}Copyright (c) ${current_year} Dujiao-Next Community${ANSI_RESET}"
  printf '%b\n' "${ANSI_DIM}--------------------------------------------------------------${ANSI_RESET}"
}

info() {
  printf '[INFO] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
}

error() {
  printf '[ERROR] %s\n' "$1" >&2
}

success() {
  printf '[OK] %s\n' "$1"
}

trim() {
  local input="${1:-}"
  input="${input#"${input%%[![:space:]]*}"}"
  input="${input%"${input##*[![:space:]]}"}"
  printf '%s' "${input}"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_command() {
  if ! command_exists "$1"; then
    error "未找到命令: $1"
    return 1
  fi
}

prompt_with_default() {
  local prompt="$1"
  local default_value="${2:-}"
  local value=""
  if [[ -n "${default_value}" ]]; then
    read -r -p "${prompt} [${default_value}]: " value
    value="$(trim "${value}")"
    if [[ -z "${value}" ]]; then
      value="${default_value}"
    fi
  else
    read -r -p "${prompt}: " value
    value="$(trim "${value}")"
  fi
  printf '%s' "${value}"
}

ask_yes_no() {
  local prompt="$1"
  local default_answer="${2:-y}"
  local answer=""
  local hint="[Y/n]"
  if [[ "${default_answer}" == "n" ]]; then
    hint="[y/N]"
  fi
  while true; do
    read -r -p "${prompt} ${hint}: " answer
    answer="$(trim "${answer}")"
    if [[ -z "${answer}" ]]; then
      answer="${default_answer}"
    fi
    answer="$(printf '%s' "${answer}" | tr '[:upper:]' '[:lower:]')"
    case "${answer}" in
      y|yes)
        return 0
        ;;
      n|no)
        return 1
        ;;
      *)
        warn "请输入 y 或 n"
        ;;
    esac
  done
}

random_string() {
  local length="${1:-32}"
  if command_exists openssl; then
    local raw
    raw="$(openssl rand -hex 64)"
    printf '%s' "${raw}" | cut -c1-"${length}"
    return 0
  fi
  local fallback
  fallback="$(date +%s%N)$$$(uname -n)"
  while [[ "${#fallback}" -lt "${length}" ]]; do
    fallback="${fallback}$(date +%s)"
  done
  printf '%s' "${fallback}" | cut -c1-"${length}"
}

ensure_state_dir() {
  mkdir -p "${STATE_DIR}"
}

save_deploy_state() {
  local mode="$1"
  local install_dir="$2"
  local api_tag="$3"
  local user_tag="$4"
  local admin_tag="$5"
  local db_mode="$6"
  write_state_file \
    "${mode}" \
    "${install_dir}" \
    "${api_tag}" \
    "${user_tag}" \
    "${admin_tag}" \
    "${db_mode}" \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "false" \
    "" \
    "" \
    "" \
    "" \
    ""
}

write_state_file() {
  local mode="$1"
  local install_dir="$2"
  local api_tag="$3"
  local user_tag="$4"
  local admin_tag="$5"
  local db_mode="$6"
  local deployed_at="$7"
  local https_enabled="$8"
  local https_mode="$9"
  local user_domain="${10}"
  local admin_domain="${11}"
  local cert_provider="${12}"
  local https_updated_at="${13}"

  ensure_state_dir
  {
    printf 'MODE=%q\n' "${mode}"
    printf 'INSTALL_DIR=%q\n' "${install_dir}"
    printf 'API_TAG=%q\n' "${api_tag}"
    printf 'USER_TAG=%q\n' "${user_tag}"
    printf 'ADMIN_TAG=%q\n' "${admin_tag}"
    printf 'DB_MODE=%q\n' "${db_mode}"
    printf 'DEPLOYED_AT=%q\n' "${deployed_at}"
    printf 'HTTPS_ENABLED=%q\n' "${https_enabled}"
    printf 'HTTPS_MODE=%q\n' "${https_mode}"
    printf 'USER_DOMAIN=%q\n' "${user_domain}"
    printf 'ADMIN_DOMAIN=%q\n' "${admin_domain}"
    printf 'CERT_PROVIDER=%q\n' "${cert_provider}"
    printf 'HTTPS_UPDATED_AT=%q\n' "${https_updated_at}"
  } > "${STATE_FILE}"
}

save_https_state() {
  local https_mode="$1"
  local user_domain="$2"
  local admin_domain="$3"
  local cert_provider="$4"

  if ! load_deploy_state; then
    error "未发现部署记录，请先执行部署。"
    return 1
  fi

  write_state_file \
    "${MODE:-}" \
    "${INSTALL_DIR:-}" \
    "${API_TAG:-}" \
    "${USER_TAG:-}" \
    "${ADMIN_TAG:-}" \
    "${DB_MODE:-}" \
    "${DEPLOYED_AT:-}" \
    "true" \
    "${https_mode}" \
    "${user_domain}" \
    "${admin_domain}" \
    "${cert_provider}" \
    "$(date '+%Y-%m-%d %H:%M:%S')"
}

load_deploy_state() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    return 1
  fi
  # shellcheck disable=SC1090
  source "${STATE_FILE}"
  return 0
}

fetch_latest_release_tag() {
  local repo="$1"
  local response tag
  response="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null || true)"
  if [[ -z "${response}" ]]; then
    printf ''
    return 0
  fi
  tag="$(printf '%s\n' "${response}" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  printf '%s' "${tag}"
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return $?
  fi
  if command_exists sudo; then
    sudo "$@"
    return $?
  fi
  return 1
}

backup_file() {
  local file_path="$1"
  if [[ -f "${file_path}" ]]; then
    cp -f "${file_path}" "${file_path}.bak"
  fi
}

restore_file_if_needed() {
  local file_path="$1"
  if [[ -f "${file_path}.bak" ]]; then
    cp -f "${file_path}.bak" "${file_path}"
  fi
}

validate_domain() {
  local domain="$1"
  if [[ -z "${domain}" ]]; then
    return 1
  fi
  if [[ "${domain}" == *"example.com"* ]]; then
    return 1
  fi
  [[ "${domain}" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[A-Za-z]{2,63}$ ]]
}

resolve_domain_ip() {
  local domain="$1"
  local ip=""
  if command_exists getent; then
    ip="$(getent ahosts "${domain}" 2>/dev/null | awk '{print $1}' | head -n1 || true)"
  fi
  if [[ -z "${ip}" ]] && command_exists dig; then
    ip="$(dig +short A "${domain}" | head -n1 || true)"
    if [[ -z "${ip}" ]]; then
      ip="$(dig +short AAAA "${domain}" | head -n1 || true)"
    fi
  fi
  if [[ -z "${ip}" ]] && command_exists nslookup; then
    ip="$(nslookup "${domain}" 2>/dev/null | awk '/^Address: /{print $2}' | tail -n1 || true)"
  fi
  printf '%s' "${ip}"
}

ensure_domain_resolved() {
  local domain="$1"
  if ! validate_domain "${domain}"; then
    error "域名格式无效或仍为示例域名: ${domain}"
    return 1
  fi
  local resolved_ip
  resolved_ip="$(resolve_domain_ip "${domain}")"
  if [[ -z "${resolved_ip}" ]]; then
    error "无法解析域名 ${domain}，请先完成 DNS 解析。"
    return 1
  fi
  info "域名解析正常: ${domain} -> ${resolved_ip}"
}

is_port_in_use() {
  local port="$1"
  if command_exists lsof; then
    if lsof -iTCP:"${port}" -sTCP:LISTEN -P -n >/dev/null 2>&1; then
      return 0
    fi
  elif command_exists ss; then
    if ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$"; then
      return 0
    fi
  elif command_exists netstat; then
    if netstat -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$"; then
      return 0
    fi
  fi
  return 1
}

ensure_port_available() {
  local port="$1"
  if is_port_in_use "${port}"; then
    error "端口 ${port} 已被占用，请先释放后重试。"
    return 1
  fi
}

precheck_https_common() {
  local user_domain="$1"
  local admin_domain="$2"
  ensure_command curl
  ensure_command openssl
  ensure_domain_resolved "${user_domain}"
  ensure_domain_resolved "${admin_domain}"
}

select_docker_database_mode() {
  local choice=""
  while true; do
    print_line
    echo "请选择数据库方案"
    print_line
    echo "1. SQLite + Redis（轻量）"
    echo "2. PostgreSQL + Redis（生产）"
    print_line
    read -r -p "请输入选项 [1-2]: " choice
    choice="$(trim "${choice}")"
    case "${choice}" in
      1)
        printf 'sqlite'
        return 0
        ;;
      2)
        printf 'postgres'
        return 0
        ;;
      *)
        warn "无效选项: ${choice}"
        ;;
    esac
  done
}

write_docker_env_file() {
  local env_file="$1"
  local tag="$2"
  local tz="$3"
  local api_port="$4"
  local user_port="$5"
  local admin_port="$6"
  local redis_port="$7"
  local postgres_port="$8"
  local redis_password="$9"
  local postgres_db="${10}"
  local postgres_user="${11}"
  local postgres_password="${12}"
  local admin_username="${13}"
  local admin_password="${14}"

  cat > "${env_file}" <<ENVEOF
TAG=${tag}
TZ=${tz}
API_PORT=${api_port}
USER_PORT=${user_port}
ADMIN_PORT=${admin_port}
REDIS_PORT=${redis_port}
POSTGRES_PORT=${postgres_port}
REDIS_PASSWORD=${redis_password}
POSTGRES_DB=${postgres_db}
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
DJ_DEFAULT_ADMIN_USERNAME=${admin_username}
DJ_DEFAULT_ADMIN_PASSWORD=${admin_password}
ENVEOF
}

write_docker_config_file() {
  local config_file="$1"
  local db_mode="$2"
  local redis_password="$3"
  local postgres_db="$4"
  local postgres_user="$5"
  local postgres_password="$6"
  local jwt_secret user_jwt_secret

  jwt_secret="$(random_string 40)"
  user_jwt_secret="$(random_string 40)"

  local dsn
  if [[ "${db_mode}" == "postgres" ]]; then
    dsn="host=postgres user=${postgres_user} password=${postgres_password} dbname=${postgres_db} port=5432 sslmode=disable TimeZone=Asia/Shanghai"
  else
    dsn="/app/db/dujiao.db"
  fi

  cat > "${config_file}" <<CFGEOF
server:
  host: 0.0.0.0
  port: 8080
  mode: release

log:
  dir: /app/logs

database:
  driver: ${db_mode}
  dsn: "${dsn}"

jwt:
  secret: ${jwt_secret}
  expire_hours: 24

user_jwt:
  secret: ${user_jwt_secret}
  expire_hours: 24
  remember_me_expire_hours: 168

redis:
  enabled: true
  host: redis
  port: 6379
  password: "${redis_password}"
  db: 0
  prefix: "dj"

queue:
  enabled: true
  host: redis
  port: 6379
  password: "${redis_password}"
  db: 1
  concurrency: 10
  queues:
    default: 10
    critical: 5

email:
  enabled: false
CFGEOF
}

write_compose_sqlite_file() {
  local compose_file="$1"
  cat > "${compose_file}" <<'SQLITEEOF'
services:
  redis:
    image: redis:7-alpine
    container_name: dujiaonext-redis
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes", "--requirepass", "${REDIS_PASSWORD}"]
    ports:
      - "127.0.0.1:${REDIS_PORT}:6379"
    volumes:
      - ./data/redis:/data
    healthcheck:
      test: ["CMD-SHELL", "redis-cli -a \"$${REDIS_PASSWORD}\" ping | grep PONG"]
      interval: 10s
      timeout: 3s
      retries: 10
    networks:
      - dujiao-net

  api:
    image: dujiaonext/api:${TAG}
    container_name: dujiaonext-api
    restart: unless-stopped
    environment:
      TZ: ${TZ}
      DJ_DEFAULT_ADMIN_USERNAME: ${DJ_DEFAULT_ADMIN_USERNAME}
      DJ_DEFAULT_ADMIN_PASSWORD: ${DJ_DEFAULT_ADMIN_PASSWORD}
    ports:
      - "${API_PORT}:8080"
    volumes:
      - ./config/config.yml:/app/config.yml:ro
      - ./data/db:/app/db
      - ./data/uploads:/app/uploads
      - ./data/logs:/app/logs
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 10
    networks:
      - dujiao-net

  user:
    image: dujiaonext/user:${TAG}
    container_name: dujiaonext-user
    restart: unless-stopped
    environment:
      TZ: ${TZ}
    ports:
      - "${USER_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

  admin:
    image: dujiaonext/admin:${TAG}
    container_name: dujiaonext-admin
    restart: unless-stopped
    environment:
      TZ: ${TZ}
    ports:
      - "${ADMIN_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

networks:
  dujiao-net:
    driver: bridge
SQLITEEOF
}

write_compose_postgres_file() {
  local compose_file="$1"
  cat > "${compose_file}" <<'POSTGRESEOF'
services:
  redis:
    image: redis:7-alpine
    container_name: dujiaonext-redis
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes", "--requirepass", "${REDIS_PASSWORD}"]
    ports:
      - "127.0.0.1:${REDIS_PORT}:6379"
    volumes:
      - ./data/redis:/data
    healthcheck:
      test: ["CMD-SHELL", "redis-cli -a \"$${REDIS_PASSWORD}\" ping | grep PONG"]
      interval: 10s
      timeout: 3s
      retries: 10
    networks:
      - dujiao-net

  postgres:
    image: postgres:16-alpine
    container_name: dujiaonext-postgres
    restart: unless-stopped
    environment:
      TZ: ${TZ}
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:${POSTGRES_PORT}:5432"
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 10
    networks:
      - dujiao-net

  api:
    image: dujiaonext/api:${TAG}
    container_name: dujiaonext-api
    restart: unless-stopped
    environment:
      TZ: ${TZ}
      DJ_DEFAULT_ADMIN_USERNAME: ${DJ_DEFAULT_ADMIN_USERNAME}
      DJ_DEFAULT_ADMIN_PASSWORD: ${DJ_DEFAULT_ADMIN_PASSWORD}
    ports:
      - "${API_PORT}:8080"
    volumes:
      - ./config/config.yml:/app/config.yml:ro
      - ./data/uploads:/app/uploads
      - ./data/logs:/app/logs
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 10
    networks:
      - dujiao-net

  user:
    image: dujiaonext/user:${TAG}
    container_name: dujiaonext-user
    restart: unless-stopped
    environment:
      TZ: ${TZ}
    ports:
      - "${USER_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

  admin:
    image: dujiaonext/admin:${TAG}
    container_name: dujiaonext-admin
    restart: unless-stopped
    environment:
      TZ: ${TZ}
    ports:
      - "${ADMIN_PORT}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - dujiao-net

networks:
  dujiao-net:
    driver: bridge
POSTGRESEOF
}

deploy_with_docker() {
  ensure_command docker
  if ! docker info >/dev/null 2>&1; then
    error "无法连接 Docker daemon，请先启动 Docker。"
    return 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    error "未检测到 docker compose，请先安装 Docker Compose 插件。"
    return 1
  fi

  local db_mode latest_tag default_tag tag
  db_mode="$(select_docker_database_mode)"
  latest_tag="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  default_tag="${latest_tag:-latest}"
  tag="$(prompt_with_default "请输入镜像版本 TAG" "${default_tag}")"
  tag="$(trim "${tag}")"
  if [[ -z "${tag}" ]]; then
    tag="${default_tag}"
  fi

  local deploy_dir tz api_port user_port admin_port redis_port postgres_port
  local redis_password postgres_db postgres_user postgres_password
  local admin_username admin_password

  deploy_dir="$(prompt_with_default "请输入部署目录" "${HOME}/dujiao-next-docker")"
  tz="$(prompt_with_default "请输入时区" "Asia/Shanghai")"
  api_port="$(prompt_with_default "请输入 API 端口" "8080")"
  user_port="$(prompt_with_default "请输入 User 端口" "8081")"
  admin_port="$(prompt_with_default "请输入 Admin 端口" "8082")"
  redis_port="$(prompt_with_default "请输入 Redis 端口" "6379")"
  redis_password="$(prompt_with_default "请输入 Redis 密码" "dujiao_redis_123456")"
  if [[ "${db_mode}" == "postgres" ]]; then
    postgres_port="$(prompt_with_default "请输入 PostgreSQL 端口" "5432")"
    postgres_db="$(prompt_with_default "请输入 PostgreSQL 数据库名" "dujiao_next")"
    postgres_user="$(prompt_with_default "请输入 PostgreSQL 用户名" "dujiao")"
    postgres_password="$(prompt_with_default "请输入 PostgreSQL 密码" "dujiao_postgres_123456")"
  else
    postgres_port="5432"
    postgres_db="dujiao_next"
    postgres_user="dujiao"
    postgres_password="dujiao_postgres_123456"
  fi
  admin_username="$(prompt_with_default "请输入默认管理员用户名" "admin")"
  admin_password="$(prompt_with_default "请输入默认管理员密码" "admin123")"

  mkdir -p "${deploy_dir}/config" \
    "${deploy_dir}/data/db" \
    "${deploy_dir}/data/uploads" \
    "${deploy_dir}/data/logs" \
    "${deploy_dir}/data/redis"
  if [[ "${db_mode}" == "postgres" ]]; then
    mkdir -p "${deploy_dir}/data/postgres"
  fi

  local env_file config_file compose_file
  env_file="${deploy_dir}/.env"
  config_file="${deploy_dir}/config/config.yml"
  if [[ "${db_mode}" == "postgres" ]]; then
    compose_file="${deploy_dir}/docker-compose.postgres.yml"
  else
    compose_file="${deploy_dir}/docker-compose.sqlite.yml"
  fi

  write_docker_env_file \
    "${env_file}" \
    "${tag}" \
    "${tz}" \
    "${api_port}" \
    "${user_port}" \
    "${admin_port}" \
    "${redis_port}" \
    "${postgres_port}" \
    "${redis_password}" \
    "${postgres_db}" \
    "${postgres_user}" \
    "${postgres_password}" \
    "${admin_username}" \
    "${admin_password}"

  write_docker_config_file \
    "${config_file}" \
    "${db_mode}" \
    "${redis_password}" \
    "${postgres_db}" \
    "${postgres_user}" \
    "${postgres_password}"

  if [[ "${db_mode}" == "postgres" ]]; then
    write_compose_postgres_file "${compose_file}"
  else
    write_compose_sqlite_file "${compose_file}"
  fi

  info "开始拉取镜像..."
  docker compose --env-file "${env_file}" -f "${compose_file}" pull
  info "开始启动服务..."
  docker compose --env-file "${env_file}" -f "${compose_file}" up -d

  save_deploy_state "docker" "${deploy_dir}" "${tag}" "${tag}" "${tag}" "${db_mode}"

  success "Docker Compose 部署完成。"
  print_line
  echo "部署目录: ${deploy_dir}"
  echo "使用方案: ${db_mode}"
  echo "API 健康检查: http://127.0.0.1:${api_port}/health"
  echo "User 首页: http://127.0.0.1:${user_port}"
  echo "Admin 首页: http://127.0.0.1:${admin_port}"
  echo "常用命令: docker compose --env-file ${env_file} -f ${compose_file} ps"
  print_line
}

detect_binary_arch() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  if [[ "${os}" != "Linux" ]]; then
    error "二进制部署当前仅支持 Linux，检测到: ${os}"
    return 1
  fi
  case "${arch}" in
    x86_64|amd64)
      printf 'x86_64'
      return 0
      ;;
    aarch64|arm64)
      printf 'arm64'
      return 0
      ;;
    *)
      error "二进制部署当前仅支持 Linux x86_64 / arm64，检测到: ${arch}"
      return 1
      ;;
  esac
}

download_asset() {
  local url="$1"
  local output="$2"
  info "下载: ${url}"
  if ! curl -fL --retry 2 --connect-timeout 10 --max-time 300 "${url}" -o "${output}"; then
    error "下载失败: ${url}"
    return 1
  fi
}

extract_api_package() {
  local package_file="$1"
  local install_dir="$2"
  local tmp_dir api_binary
  tmp_dir="$(mktemp -d)"
  tar -xzf "${package_file}" -C "${tmp_dir}"
  api_binary="$(find "${tmp_dir}" -type f -name "dujiao-next" | head -n1)"
  if [[ -z "${api_binary}" ]]; then
    rm -rf "${tmp_dir}"
    error "API 包内未找到 dujiao-next 可执行文件。"
    return 1
  fi
  mkdir -p "${install_dir}/api"
  cp -f "${api_binary}" "${install_dir}/api/dujiao-next"
  chmod +x "${install_dir}/api/dujiao-next"
  rm -rf "${tmp_dir}"
}

extract_frontend_package() {
  local package_file="$1"
  local target_dir="$2"
  local tmp_dir dist_dir
  tmp_dir="$(mktemp -d)"
  unzip -oq "${package_file}" -d "${tmp_dir}"
  dist_dir="$(find "${tmp_dir}" -type d -name dist | head -n1)"
  if [[ -z "${dist_dir}" ]]; then
    rm -rf "${tmp_dir}"
    error "包内未找到 dist 目录: ${package_file}"
    return 1
  fi
  rm -rf "${target_dir}"
  mkdir -p "${target_dir}"
  cp -R "${dist_dir}/." "${target_dir}/"
  rm -rf "${tmp_dir}"
}

write_binary_config_file() {
  local config_file="$1"
  local install_dir="$2"
  local api_port="$3"
  local jwt_secret user_jwt_secret
  jwt_secret="$(random_string 40)"
  user_jwt_secret="$(random_string 40)"
  cat > "${config_file}" <<CFGEOF
server:
  host: 0.0.0.0
  port: ${api_port}
  mode: release

log:
  dir: "${install_dir}/logs"

database:
  driver: sqlite
  dsn: "${install_dir}/db/dujiao.db"

jwt:
  secret: ${jwt_secret}
  expire_hours: 24

user_jwt:
  secret: ${user_jwt_secret}
  expire_hours: 24
  remember_me_expire_hours: 168

redis:
  enabled: false
  host: 127.0.0.1
  port: 6379
  password: ""
  db: 0
  prefix: "dj"

queue:
  enabled: false
  host: 127.0.0.1
  port: 6379
  password: ""
  db: 1
  concurrency: 10
  queues:
    default: 10
    critical: 5

email:
  enabled: false
CFGEOF
}

write_binary_run_script() {
  local run_script="$1"
  local install_dir="$2"
  local admin_username="$3"
  local admin_password="$4"
  cat > "${run_script}" <<RUNEOF
#!/usr/bin/env bash
set -euo pipefail
cd "${install_dir}"
export DJ_DEFAULT_ADMIN_USERNAME="${admin_username}"
export DJ_DEFAULT_ADMIN_PASSWORD="${admin_password}"
exec "${install_dir}/api/dujiao-next" -mode all
RUNEOF
  chmod +x "${run_script}"
}

write_nginx_template_files() {
  local user_file="$1"
  local admin_file="$2"
  local install_dir="$3"
  local user_domain="$4"
  local admin_domain="$5"
  local api_port="$6"

  cat > "${user_file}" <<NGUSEREOF
server {
    listen 80;
    server_name ${user_domain};

    root ${install_dir}/user/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:${api_port}/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /uploads/ {
        proxy_pass http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGUSEREOF

  cat > "${admin_file}" <<NGADMINEOF
server {
    listen 80;
    server_name ${admin_domain};

    root ${install_dir}/admin/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:${api_port}/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /uploads/ {
        proxy_pass http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGADMINEOF
}

setup_systemd_service() {
  local install_dir="$1"
  local service_name="$2"
  local tz="$3"
  local admin_username="$4"
  local admin_password="$5"
  local service_file="/etc/systemd/system/${service_name}"
  local temp_service

  if ! command_exists systemctl; then
    warn "系统未检测到 systemctl，跳过 systemd 服务安装。"
    return 1
  fi
  if [[ "$(id -u)" -ne 0 ]] && ! command_exists sudo; then
    warn "当前非 root 且未安装 sudo，跳过 systemd 服务安装。"
    return 1
  fi

  temp_service="$(mktemp)"
  cat > "${temp_service}" <<SVCEOF
[Unit]
Description=Dujiao-Next API Service
After=network.target

[Service]
Type=simple
WorkingDirectory=${install_dir}
Environment=TZ=${tz}
Environment=DJ_DEFAULT_ADMIN_USERNAME=${admin_username}
Environment=DJ_DEFAULT_ADMIN_PASSWORD=${admin_password}
ExecStart=${install_dir}/api/dujiao-next -mode all
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SVCEOF

  run_as_root install -m 644 "${temp_service}" "${service_file}"
  run_as_root systemctl daemon-reload
  run_as_root systemctl enable --now "${service_name}"
  rm -f "${temp_service}"
  return 0
}

deploy_with_binary() {
  ensure_command tar
  ensure_command unzip
  local binary_arch
  binary_arch="$(detect_binary_arch)"

  local latest_tag default_tag tag_input tag install_dir
  latest_tag="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  default_tag="${latest_tag:-v0.0.1-beta}"
  tag_input="$(prompt_with_default "请输入版本 TAG（输入 latest 使用最新版本）" "${default_tag}")"
  tag_input="$(trim "${tag_input}")"
  if [[ "${tag_input}" == "latest" ]]; then
    tag="${default_tag}"
  else
    tag="${tag_input}"
  fi
  if [[ -z "${tag}" ]]; then
    error "版本 TAG 不能为空。"
    return 1
  fi

  local tz api_port user_port admin_port admin_username admin_password
  install_dir="$(prompt_with_default "请输入部署目录" "${HOME}/dujiao-next-bin")"
  tz="$(prompt_with_default "请输入时区" "Asia/Shanghai")"
  api_port="$(prompt_with_default "请输入 API 端口" "8080")"
  user_port="$(prompt_with_default "请输入 User 静态站点端口（供参考）" "8081")"
  admin_port="$(prompt_with_default "请输入 Admin 静态站点端口（供参考）" "8082")"
  admin_username="$(prompt_with_default "请输入默认管理员用户名" "admin")"
  admin_password="$(prompt_with_default "请输入默认管理员密码" "admin123")"

  mkdir -p "${install_dir}/packages" \
    "${install_dir}/api" \
    "${install_dir}/user" \
    "${install_dir}/admin" \
    "${install_dir}/db" \
    "${install_dir}/uploads" \
    "${install_dir}/logs" \
    "${install_dir}/nginx"

  local api_package user_package admin_package
  api_package="${install_dir}/packages/dujiao-next_${tag}_Linux_${binary_arch}.tar.gz"
  user_package="${install_dir}/packages/dujiao-next-user-${tag}.zip"
  admin_package="${install_dir}/packages/dujiao-next-admin-${tag}.zip"

  download_asset \
    "https://github.com/${DUJIAO_API_REPO}/releases/download/${tag}/dujiao-next_${tag}_Linux_${binary_arch}.tar.gz" \
    "${api_package}"
  download_asset \
    "https://github.com/${DUJIAO_USER_REPO}/releases/download/${tag}/dujiao-next-user-${tag}.zip" \
    "${user_package}"
  download_asset \
    "https://github.com/${DUJIAO_ADMIN_REPO}/releases/download/${tag}/dujiao-next-admin-${tag}.zip" \
    "${admin_package}"

  extract_api_package "${api_package}" "${install_dir}"
  extract_frontend_package "${user_package}" "${install_dir}/user/dist"
  extract_frontend_package "${admin_package}" "${install_dir}/admin/dist"

  write_binary_config_file "${install_dir}/config.yml" "${install_dir}" "${api_port}"
  write_binary_run_script "${install_dir}/run-api.sh" "${install_dir}" "${admin_username}" "${admin_password}"

  local user_domain admin_domain
  user_domain="$(prompt_with_default "请输入 User 域名（用于 Nginx 模板）" "user.example.com")"
  admin_domain="$(prompt_with_default "请输入 Admin 域名（用于 Nginx 模板）" "admin.example.com")"
  write_nginx_template_files \
    "${install_dir}/nginx/user.conf" \
    "${install_dir}/nginx/admin.conf" \
    "${install_dir}" \
    "${user_domain}" \
    "${admin_domain}" \
    "${api_port}"

  if ask_yes_no "是否创建并启动 systemd 服务 dujiao-next-api.service" "y"; then
    if setup_systemd_service "${install_dir}" "dujiao-next-api.service" "${tz}" "${admin_username}" "${admin_password}"; then
      success "systemd 服务已启动: dujiao-next-api.service"
    else
      warn "systemd 服务安装失败，请使用 ${install_dir}/run-api.sh 手动启动。"
    fi
  else
    info "你可手动运行: ${install_dir}/run-api.sh"
  fi

  save_deploy_state "binary" "${install_dir}" "${tag}" "${tag}" "${tag}" "sqlite"

  success "二进制部署完成。"
  print_line
  echo "部署目录: ${install_dir}"
  echo "目标架构: Linux ${binary_arch}"
  echo "API 配置: ${install_dir}/config.yml"
  echo "User 静态目录: ${install_dir}/user/dist"
  echo "Admin 静态目录: ${install_dir}/admin/dist"
  echo "Nginx 模板: ${install_dir}/nginx/user.conf 和 ${install_dir}/nginx/admin.conf"
  echo "API 健康检查: http://127.0.0.1:${api_port}/health"
  echo "建议将 User 站点映射到端口: ${user_port}"
  echo "建议将 Admin 站点映射到端口: ${admin_port}"
  print_line
}

docker_compose_file_from_db_mode() {
  local install_dir="$1"
  local db_mode="$2"
  if [[ "${db_mode}" == "postgres" ]]; then
    printf '%s/docker-compose.postgres.yml' "${install_dir}"
  else
    printf '%s/docker-compose.sqlite.yml' "${install_dir}"
  fi
}

write_docker_https_caddyfile() {
  local file_path="$1"
  local user_domain="$2"
  local admin_domain="$3"
  local acme_email="$4"
  cat > "${file_path}" <<EOF
{
    email ${acme_email}
}

${user_domain} {
    encode gzip
    @api path /api/* /uploads/*
    handle @api {
        reverse_proxy api:8080
    }
    handle {
        reverse_proxy user:80
    }
}

${admin_domain} {
    encode gzip
    @api path /api/* /uploads/*
    handle @api {
        reverse_proxy api:8080
    }
    handle {
        reverse_proxy admin:80
    }
}
EOF
}

write_docker_https_compose_file() {
  local file_path="$1"
  cat > "${file_path}" <<'EOF'
services:
  caddy:
    image: caddy:2-alpine
    container_name: dujiaonext-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data/caddy/data:/data
      - ./data/caddy/config:/config
    depends_on:
      api:
        condition: service_healthy
      user:
        condition: service_started
      admin:
        condition: service_started
    networks:
      - dujiao-net
EOF
}

is_docker_caddy_running() {
  docker ps --format '{{.Names}}' | grep -qx 'dujiaonext-caddy'
}

enable_https_for_docker() {
  ensure_command docker
  if ! docker compose version >/dev/null 2>&1; then
    error "未检测到 docker compose，请先安装 Docker Compose 插件。"
    return 1
  fi

  local install_dir db_mode env_file base_compose
  install_dir="${INSTALL_DIR:-}"
  db_mode="${DB_MODE:-sqlite}"
  if [[ -z "${install_dir}" ]]; then
    error "部署目录为空，请先完成 Docker 部署。"
    return 1
  fi

  env_file="${install_dir}/.env"
  base_compose="$(docker_compose_file_from_db_mode "${install_dir}" "${db_mode}")"
  if [[ ! -f "${env_file}" || ! -f "${base_compose}" ]]; then
    error "未找到 Docker 部署文件，请确认目录: ${install_dir}"
    return 1
  fi

  local user_domain admin_domain acme_email
  user_domain="$(prompt_with_default "请输入 User 域名（用于 HTTPS）" "${USER_DOMAIN:-user.example.com}")"
  admin_domain="$(prompt_with_default "请输入 Admin 域名（用于 HTTPS）" "${ADMIN_DOMAIN:-admin.example.com}")"
  if [[ "${user_domain}" == "${admin_domain}" ]]; then
    error "User 域名与 Admin 域名不能相同。"
    return 1
  fi
  acme_email="$(prompt_with_default "请输入 ACME 邮箱" "admin@${user_domain}")"

  precheck_https_common "${user_domain}" "${admin_domain}"
  if ! is_docker_caddy_running; then
    ensure_port_available 80
    ensure_port_available 443
  fi

  local caddy_dir caddy_data_dir caddy_config_dir caddy_file https_compose_file
  caddy_dir="${install_dir}/caddy"
  caddy_data_dir="${install_dir}/data/caddy/data"
  caddy_config_dir="${install_dir}/data/caddy/config"
  caddy_file="${caddy_dir}/Caddyfile"
  https_compose_file="${install_dir}/docker-compose.https.yml"

  mkdir -p "${caddy_dir}" "${caddy_data_dir}" "${caddy_config_dir}"
  backup_file "${caddy_file}"
  backup_file "${https_compose_file}"

  write_docker_https_caddyfile "${caddy_file}" "${user_domain}" "${admin_domain}" "${acme_email}"
  write_docker_https_compose_file "${https_compose_file}"

  info "开始启动 Caddy HTTPS 代理（ACME HTTP-01）..."
  if ! docker compose --env-file "${env_file}" -f "${base_compose}" -f "${https_compose_file}" up -d caddy; then
    restore_file_if_needed "${caddy_file}"
    restore_file_if_needed "${https_compose_file}"
    error "HTTPS 代理启动失败，已尝试回滚配置文件。"
    return 1
  fi

  save_https_state "docker-caddy" "${user_domain}" "${admin_domain}" "acme-http01"

  success "Docker HTTPS 已启用（ACME 自动申请证书）。"
  print_line
  echo "User HTTPS: https://${user_domain}"
  echo "Admin HTTPS: https://${admin_domain}"
  echo "验证命令: curl -I https://${user_domain}"
  echo "验证命令: curl -I https://${admin_domain}"
  print_line
}

extract_binary_api_port() {
  local config_file="$1"
  local api_port=""
  if [[ -f "${config_file}" ]]; then
    api_port="$(awk '
      $1=="server:" {in_server=1; next}
      in_server && $1=="port:" {print $2; exit}
      in_server && /^[^[:space:]]/ {in_server=0}
    ' "${config_file}" || true)"
  fi
  if [[ -z "${api_port}" ]]; then
    api_port="8080"
  fi
  printf '%s' "${api_port}"
}

install_or_prepare_acme_sh() {
  local acme_email="$1"
  local acme_bin="${HOME}/.acme.sh/acme.sh"
  if [[ -x "${acme_bin}" ]]; then
    return 0
  fi
  info "正在安装 acme.sh..."
  if ! curl -fsSL https://get.acme.sh | sh -s email="${acme_email}"; then
    error "acme.sh 安装失败。"
    return 1
  fi
  if [[ ! -x "${acme_bin}" ]]; then
    error "未找到 acme.sh 可执行文件: ${acme_bin}"
    return 1
  fi
}

write_binary_nginx_reload_hook() {
  local hook_file="$1"
  cat > "${hook_file}" <<'EOF'
#!/usr/bin/env bash
set -e
if command -v sudo >/dev/null 2>&1; then
  sudo systemctl reload nginx >/dev/null 2>&1 || sudo nginx -s reload >/dev/null 2>&1 || true
else
  systemctl reload nginx >/dev/null 2>&1 || nginx -s reload >/dev/null 2>&1 || true
fi
EOF
  chmod +x "${hook_file}"
}

issue_cert_with_acme_http01() {
  local domain="$1"
  local webroot="$2"
  local cert_dir="$3"
  local reload_cmd="$4"
  local acme_bin="${HOME}/.acme.sh/acme.sh"

  if [[ ! -d "${webroot}" ]]; then
    error "Webroot 不存在，无法执行 HTTP-01: ${webroot}"
    return 1
  fi

  mkdir -p "${webroot}/.well-known/acme-challenge" "${cert_dir}"

  info "开始签发证书: ${domain}"
  if ! "${acme_bin}" --issue --server letsencrypt -d "${domain}" -w "${webroot}" --keylength ec-256; then
    error "证书签发失败: ${domain}"
    return 1
  fi

  if ! "${acme_bin}" --install-cert -d "${domain}" --ecc \
      --key-file "${cert_dir}/privkey.pem" \
      --fullchain-file "${cert_dir}/fullchain.pem" \
      --reloadcmd "${reload_cmd}"; then
    error "证书安装失败: ${domain}"
    return 1
  fi
}

write_nginx_https_template_files() {
  local user_file="$1"
  local admin_file="$2"
  local install_dir="$3"
  local user_domain="$4"
  local admin_domain="$5"
  local api_port="$6"
  local user_cert_dir="$7"
  local admin_cert_dir="$8"

  cat > "${user_file}" <<EOF
server {
    listen 80;
    server_name ${user_domain};

    location /.well-known/acme-challenge/ {
        root ${install_dir}/user/dist;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${user_domain};

    ssl_certificate ${user_cert_dir}/fullchain.pem;
    ssl_certificate_key ${user_cert_dir}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    root ${install_dir}/user/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:${api_port}/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /uploads/ {
        proxy_pass http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

  cat > "${admin_file}" <<EOF
server {
    listen 80;
    server_name ${admin_domain};

    location /.well-known/acme-challenge/ {
        root ${install_dir}/admin/dist;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${admin_domain};

    ssl_certificate ${admin_cert_dir}/fullchain.pem;
    ssl_certificate_key ${admin_cert_dir}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    root ${install_dir}/admin/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:${api_port}/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /uploads/ {
        proxy_pass http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
}

install_binary_https_nginx_configs() {
  local install_dir="$1"
  local user_file="${install_dir}/nginx/user-https.conf"
  local admin_file="${install_dir}/nginx/admin-https.conf"

  if ! ask_yes_no "是否尝试自动安装 HTTPS Nginx 配置并重载（写入 /etc/nginx/conf.d）" "n"; then
    info "已跳过自动写入。请手动接入模板后重载 Nginx。"
    return 0
  fi

  if [[ ! -d "/etc/nginx/conf.d" ]]; then
    warn "未找到 /etc/nginx/conf.d，无法自动写入。"
    return 1
  fi

  run_as_root install -m 644 "${user_file}" "/etc/nginx/conf.d/dujiao-next-user-https.conf"
  run_as_root install -m 644 "${admin_file}" "/etc/nginx/conf.d/dujiao-next-admin-https.conf"

  if ! run_as_root nginx -t; then
    error "Nginx 配置检测失败，请检查模板后手动修复。"
    return 1
  fi

  if run_as_root systemctl reload nginx; then
    success "Nginx 已通过 systemctl reload 生效。"
    return 0
  fi
  if run_as_root nginx -s reload; then
    success "Nginx 已通过 nginx -s reload 生效。"
    return 0
  fi

  warn "Nginx 自动重载失败，请手动执行 reload。"
  return 1
}

enable_https_for_binary() {
  local install_dir
  install_dir="${INSTALL_DIR:-}"
  if [[ -z "${install_dir}" ]]; then
    error "部署目录为空，请先完成二进制部署。"
    return 1
  fi
  if [[ ! -f "${install_dir}/config.yml" ]]; then
    error "未找到 API 配置文件: ${install_dir}/config.yml"
    return 1
  fi

  ensure_command nginx

  local user_domain admin_domain acme_email
  user_domain="$(prompt_with_default "请输入 User 域名（用于 HTTPS）" "${USER_DOMAIN:-user.example.com}")"
  admin_domain="$(prompt_with_default "请输入 Admin 域名（用于 HTTPS）" "${ADMIN_DOMAIN:-admin.example.com}")"
  if [[ "${user_domain}" == "${admin_domain}" ]]; then
    error "User 域名与 Admin 域名不能相同。"
    return 1
  fi
  acme_email="$(prompt_with_default "请输入 ACME 邮箱" "admin@${user_domain}")"

  precheck_https_common "${user_domain}" "${admin_domain}"
  if ! is_port_in_use 80; then
    warn "未检测到本机 80 端口监听，HTTP-01 验证可能失败。请确认 Nginx 已加载域名配置。"
  fi

  local acme_hook_file
  acme_hook_file="${install_dir}/nginx/reload-nginx.sh"
  write_binary_nginx_reload_hook "${acme_hook_file}"
  install_or_prepare_acme_sh "${acme_email}"

  local api_port user_cert_dir admin_cert_dir
  api_port="$(extract_binary_api_port "${install_dir}/config.yml")"
  user_cert_dir="${install_dir}/certs/${user_domain}"
  admin_cert_dir="${install_dir}/certs/${admin_domain}"

  write_nginx_https_template_files \
    "${install_dir}/nginx/user-https.conf" \
    "${install_dir}/nginx/admin-https.conf" \
    "${install_dir}" \
    "${user_domain}" \
    "${admin_domain}" \
    "${api_port}" \
    "${user_cert_dir}" \
    "${admin_cert_dir}"

  issue_cert_with_acme_http01 "${user_domain}" "${install_dir}/user/dist" "${user_cert_dir}" "${acme_hook_file}"
  issue_cert_with_acme_http01 "${admin_domain}" "${install_dir}/admin/dist" "${admin_cert_dir}" "${acme_hook_file}"

  install_binary_https_nginx_configs "${install_dir}" || true
  save_https_state "binary-nginx-acme.sh" "${user_domain}" "${admin_domain}" "acme-http01"

  success "二进制 HTTPS 已完成证书申请。"
  print_line
  echo "User HTTPS: https://${user_domain}"
  echo "Admin HTTPS: https://${admin_domain}"
  echo "证书目录: ${install_dir}/certs"
  echo "Nginx HTTPS 模板: ${install_dir}/nginx/user-https.conf 和 ${install_dir}/nginx/admin-https.conf"
  echo "验证命令: openssl s_client -connect ${user_domain}:443 -servername ${user_domain} </dev/null | openssl x509 -noout -dates"
  print_line
}

configure_https() {
  if ! load_deploy_state; then
    error "未发现部署记录，请先选择「1. 开始部署」。"
    return 1
  fi

  local mode
  mode="${MODE:-}"
  case "${mode}" in
    docker)
      enable_https_for_docker
      ;;
    binary)
      enable_https_for_binary
      ;;
    *)
      error "未知部署模式: ${mode}"
      return 1
      ;;
  esac
}

show_https_status() {
  local https_enabled https_mode user_domain admin_domain cert_provider https_updated_at
  https_enabled="${HTTPS_ENABLED:-false}"
  https_mode="${HTTPS_MODE:-}"
  user_domain="${USER_DOMAIN:-}"
  admin_domain="${ADMIN_DOMAIN:-}"
  cert_provider="${CERT_PROVIDER:-}"
  https_updated_at="${HTTPS_UPDATED_AT:-}"

  if [[ "${https_enabled}" == "true" ]]; then
    echo "HTTPS 状态: 已启用"
    echo "HTTPS 方式: ${https_mode}"
    echo "User 域名: ${user_domain:-N/A}"
    echo "Admin 域名: ${admin_domain:-N/A}"
    echo "证书提供方: ${cert_provider:-N/A}"
    echo "最近更新时间: ${https_updated_at:-N/A}"
  else
    echo "HTTPS 状态: 未启用"
  fi
}

print_component_update() {
  local name="$1"
  local current="$2"
  local latest="$3"
  local status
  if [[ -z "${latest}" ]]; then
    status="无法获取最新版本"
  elif [[ -z "${current}" ]]; then
    status="未记录本地版本"
  elif [[ "${current}" == "${latest}" ]]; then
    status="已是最新"
  else
    status="可更新"
  fi
  printf '%-8s 当前: %-20s 最新: %-20s 状态: %s\n' "${name}" "${current:-N/A}" "${latest:-N/A}" "${status}"
}

check_updates() {
  print_line
  info "正在检查最新版本..."
  local latest_api latest_user latest_admin
  latest_api="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  latest_user="$(fetch_latest_release_tag "${DUJIAO_USER_REPO}")"
  latest_admin="$(fetch_latest_release_tag "${DUJIAO_ADMIN_REPO}")"

  if [[ -z "${latest_api}${latest_user}${latest_admin}" ]]; then
    error "未能从 GitHub 获取最新版本，请检查网络后重试。"
    return 1
  fi

  local mode install_dir api_tag user_tag admin_tag db_mode deployed_at
  if load_deploy_state; then
    mode="${MODE:-}"
    install_dir="${INSTALL_DIR:-}"
    api_tag="${API_TAG:-}"
    user_tag="${USER_TAG:-}"
    admin_tag="${ADMIN_TAG:-}"
    db_mode="${DB_MODE:-}"
    deployed_at="${DEPLOYED_AT:-}"

    print_line
    echo "检测到本地部署记录"
    echo "部署模式: ${mode}"
    echo "部署目录: ${install_dir}"
    echo "数据库方案: ${db_mode}"
    echo "部署时间: ${deployed_at}"
    print_line
    print_component_update "API" "${api_tag}" "${latest_api}"
    print_component_update "User" "${user_tag}" "${latest_user}"
    print_component_update "Admin" "${admin_tag}" "${latest_admin}"
    print_line
    show_https_status
    print_line
    if [[ "${mode}" == "docker" ]]; then
      echo "更新建议（Docker 模式）:"
      echo "1) 进入部署目录: cd ${install_dir}"
      echo "2) 修改 .env 中 TAG 为目标版本"
      echo "3) 执行 docker compose pull && docker compose up -d"
      if [[ "${HTTPS_ENABLED:-false}" == "true" ]]; then
        echo "4) 如已启用 HTTPS，同时执行: docker compose -f $(docker_compose_file_from_db_mode "${install_dir}" "${db_mode}") -f ${install_dir}/docker-compose.https.yml up -d caddy"
      fi
    elif [[ "${mode}" == "binary" ]]; then
      echo "更新建议（二进制模式）:"
      echo "重新运行脚本，选择「1. 开始部署 -> 2. 二进制部署」，输入目标版本即可覆盖更新。"
    fi
  else
    warn "未发现本地部署记录（${STATE_FILE}），仅展示线上最新版本。"
    print_line
    print_component_update "API" "" "${latest_api}"
    print_component_update "User" "" "${latest_user}"
    print_component_update "Admin" "" "${latest_admin}"
  fi
  print_line
}

show_main_menu() {
  print_line
  echo "Dujiao-Next 一键部署脚本"
  print_line
  echo "1. 开始部署"
  echo "2. 检查更新"
  echo "3. 配置 HTTPS (ACME)"
  echo "0. 退出"
  print_line
}

show_deploy_menu() {
  print_line
  echo "请选择部署方式"
  print_line
  echo "1. Docker Compose 部署"
  echo "2. 二进制部署"
  echo "0. 返回上级菜单"
  print_line
}

handle_deploy_menu() {
  while true; do
    show_deploy_menu
    read -r -p "请输入选项 [0-2]: " deploy_choice
    deploy_choice="$(trim "${deploy_choice}")"
    case "${deploy_choice}" in
      1)
        deploy_with_docker
        return 0
        ;;
      2)
        deploy_with_binary
        return 0
        ;;
      0)
        return 0
        ;;
      *)
        warn "无效选项: ${deploy_choice}"
        ;;
    esac
  done
}

main() {
  print_startup_banner
  ensure_command curl
  while true; do
    show_main_menu
    read -r -p "请输入选项 [0-3]: " choice
    choice="$(trim "${choice}")"
    case "${choice}" in
      1)
        handle_deploy_menu
        ;;
      2)
        check_updates
        ;;
      3)
        configure_https
        ;;
      0)
        echo "已退出。"
        exit 0
        ;;
      *)
        warn "无效选项: ${choice}"
        ;;
    esac
  done
}

main "$@"
