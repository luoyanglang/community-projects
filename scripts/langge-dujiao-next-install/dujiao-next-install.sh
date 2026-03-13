#!/usr/bin/env bash
# ==================================================
# Dujiao-Next - One-Click Deploy & Ops Script
# Author  : LangGe  Telegram: @luoyanglang
# Based on: dujiao-next/community-projects (MIT)
# License : MIT
# ==================================================
set -euo pipefail

# ── Repos ──────────────────────────────────────────
DUJIAO_API_REPO="dujiao-next/dujiao-next"
DUJIAO_USER_REPO="dujiao-next/user"
DUJIAO_ADMIN_REPO="dujiao-next/admin"

# ── State ──────────────────────────────────────────
STATE_DIR="${HOME}/.dujiao-next-one-click"
STATE_FILE="${STATE_DIR}/state.env"

# ── Author ─────────────────────────────────────────
AUTHOR_TG="https://t.me/luoyanglang"
AUTHOR_DONATE="TMW6EFjwrqrEU827oLZgiig9fkuVi3nfCA"

# ── Colors ─────────────────────────────────────────
if [[ -t 1 ]]; then
  R=$'\033[0;31m' G=$'\033[0;32m' Y=$'\033[1;33m'
  B=$'\033[0;34m' C=$'\033[0;36m' M=$'\033[0;35m'
  BOLD=$'\033[1m' DIM=$'\033[2m' BM=$'\033[95m' NC=$'\033[0m'
else
  R='' G='' Y='' B='' C='' M='' BOLD='' DIM='' BM='' NC=''
fi

# ── Print helpers ──────────────────────────────────
info()    { printf "${B}[INFO]${NC} %s\n" "$1"; }
warn()    { printf "${Y}[WARN]${NC} %s\n" "$1"; }
error()   { printf "${R}[ERROR]${NC} %s\n" "$1" >&2; }
success() { printf "${G}[OK]${NC} %s\n" "$1"; }
print_line() { printf '%s\n' "────────────────────────────────────────────────────"; }

# ── Author info ────────────────────────────────────
print_author() {
  echo ""
  print_line
  echo "  ${C}☕ 如果本脚本对你有帮助，欢迎请作者喝杯咖啡：${NC}"
  echo "     USDT (TRC20): ${Y}${AUTHOR_DONATE}${NC}"
  echo ""
  echo "  ${C}📬 遇到问题？联系作者获取支持：${NC}"
  echo "     Telegram: ${Y}${AUTHOR_TG}${NC}"
  print_line
  echo ""
}

print_fail_author() {
  echo ""
  print_line
  echo "  ${R}❌ 安装遇到问题，需要帮助？${NC}"
  echo "     Telegram: ${Y}${AUTHOR_TG}${NC}"
  print_line
  echo ""
}

# ── Banner ─────────────────────────────────────────
print_banner() {
  local year; year="$(date +%Y)"
  clear
  printf '%b\n' "${BM}╔══════════════════════════════════════════════════════════╗${NC}"
  printf '%b\n' "${BM}║           🦄 Dujiao-Next 一键部署 & 运维脚本             ║${NC}"
  printf '%b\n' "${BM}║         Author: LangGe  Telegram: @luoyanglang           ║${NC}"
  printf '%b\n' "${BM}╚══════════════════════════════════════════════════════════╝${NC}"
  printf '%b\n' "${C}██████╗ ██╗   ██╗     ██╗██╗ █████╗  ██████╗      ███╗   ██╗███████╗██╗  ██╗████████╗${NC}"
  printf '%b\n' "${C}██╔══██╗██║   ██║     ██║██║██╔══██╗██╔═══██╗     ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝${NC}"
  printf '%b\n' "${C}██║  ██║██║   ██║     ██║██║███████║██║   ██║     ██╔██╗ ██║█████╗   ╚███╔╝    ██║   ${NC}"
  printf '%b\n' "${C}██║  ██║██║   ██║██   ██║██║██╔══██║██║   ██║     ██║╚██╗██║██╔══╝   ██╔██╗    ██║   ${NC}"
  printf '%b\n' "${C}██████╔╝╚██████╔╝╚█████╔╝██║██║  ██║╚██████╔╝     ██║ ╚████║███████╗██╔╝ ██╗   ██║   ${NC}"
  printf '%b\n' "${C}╚═════╝  ╚═════╝  ╚════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝   ${NC}"
  printf '%b\n' "${G}${BOLD}开源仓库地址${NC}"
  printf '%b\n' "${B}• Root:    https://github.com/dujiao-next${NC}"
  printf '%b\n' "${B}• API:     https://github.com/dujiao-next/dujiao-next${NC}"
  printf '%b\n' "${B}• User:    https://github.com/dujiao-next/user${NC}"
  printf '%b\n' "${B}• Admin:   https://github.com/dujiao-next/admin${NC}"
  printf '%b\n' "${B}• Migrate: https://github.com/luoyanglang/dujiao-migrate${NC}"
  printf '%b\n' "${DIM}版权所有 (c) ${year} LangGe  |  基于 dujiao-next community-projects (MIT)${NC}"
}

# ══════════════════════════════════════════════════
# 工具函数
# ══════════════════════════════════════════════════
trim() {
  local v="${1:-}"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"; printf '%s' "${v}"
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_command() {
  if ! command_exists "$1"; then
    error "未找到命令: $1，请先安装后重试"
    print_fail_author; return 1
  fi
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then "$@"; return $?; fi
  if command_exists sudo; then sudo "$@"; return $?; fi
  return 1
}

prompt_with_default() {
  local prompt="$1" default="${2:-}" value=""
  if [[ -n "${default}" ]]; then
    printf '%s [%s]: ' "${prompt}" "${default}" >&2
    read -r value
    value="$(trim "${value}")"
    [[ -z "${value}" ]] && value="${default}"
  else
    printf '%s: ' "${prompt}" >&2
    read -r value
    value="$(trim "${value}")"
  fi
  printf '%s' "${value}"
}

ask_yes_no() {
  local prompt="$1" default="${2:-y}" answer="" hint="[Y/n]"
  [[ "${default}" == "n" ]] && hint="[y/N]"
  while true; do
    printf '%s %s: ' "${prompt}" "${hint}" >&2
    read -r answer
    answer="$(trim "${answer}")"
    [[ -z "${answer}" ]] && answer="${default}"
    answer="$(printf '%s' "${answer}" | tr '[:upper:]' '[:lower:]')"
    case "${answer}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *)     warn "请输入 y 或 n" ;;
    esac
  done
}

random_string() {
  local length="${1:-32}"
  if command_exists openssl; then
    printf '%s' "$(openssl rand -hex 64)" | cut -c1-"${length}"
    return 0
  fi
  local fb="${1}$(date +%s%N)$$"; while [[ "${#fb}" -lt "${length}" ]]; do fb="${fb}$(date +%s)"; done
  printf '%s' "${fb}" | cut -c1-"${length}"
}

backup_file() {
  local f="$1"; [[ -f "${f}" ]] && cp -f "${f}" "${f}.bak"
}

restore_file_if_needed() {
  local f="$1"; [[ -f "${f}.bak" ]] && cp -f "${f}.bak" "${f}"
}

validate_port_number() {
  local port="$1"
  [[ "${port}" =~ ^[0-9]+$ ]] || return 1
  (( port >= 1 && port <= 65535 ))
}

set_config_kv() {
  local file="$1" key="$2" value="$3"
  if grep -Eq "^[#[:space:]]*${key}[[:space:]]+" "${file}"; then
    sed -i -E "s|^[#[:space:]]*${key}[[:space:]].*|${key} ${value}|" "${file}"
  else
    printf '%s %s\n' "${key}" "${value}" >> "${file}"
  fi
}

find_sshd_bin() {
  local candidate
  for candidate in /usr/sbin/sshd /usr/local/sbin/sshd; do
    [[ -x "${candidate}" ]] && { printf '%s' "${candidate}"; return 0; }
  done
  command -v sshd 2>/dev/null || true
}

test_sshd_config() {
  local sshd_bin
  sshd_bin="$(find_sshd_bin)"
  [[ -n "${sshd_bin}" ]] || return 1
  "${sshd_bin}" -t -f "${1}"
}

restart_ssh_service() {
  systemctl restart ssh 2>/dev/null || \
    systemctl restart sshd 2>/dev/null || \
    service ssh restart 2>/dev/null || \
    service sshd restart 2>/dev/null
}

write_ufw_after_rules() {
  local target="$1"
  local marker_begin="# BEGIN UFW AND DOCKER"
  local marker_end="# END UFW AND DOCKER"
  local block
  block="$(cat <<'EOF'
# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16
-A DOCKER-USER -j ufw-user-forward
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12
-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
EOF
)"

  if [[ -f "${target}" ]] && grep -Fq "${marker_begin}" "${target}"; then
    awk -v begin="${marker_begin}" -v end="${marker_end}" -v block="${block}" '
      BEGIN { replaced=0; skipping=0 }
      $0 == begin {
        if (!replaced) {
          print block
          replaced=1
        }
        skipping=1
        next
      }
      $0 == end {
        skipping=0
        next
      }
      !skipping { print }
      END {
        if (!replaced) {
          if (NR > 0) print ""
          print block
        }
      }
    ' "${target}" > "${target}.tmp" && mv -f "${target}.tmp" "${target}"
  else
    {
      [[ -f "${target}" ]] && cat "${target}"
      [[ -f "${target}" ]] && printf '\n'
      printf '%s\n' "${block}"
    } > "${target}"
  fi
}

validate_domain() {
  local d="$1"
  [[ -z "${d}" ]] && return 1
  [[ "${d}" == *"example.com"* ]] && return 1
  [[ "${d}" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[A-Za-z]{2,63}$ ]]
}

resolve_domain_ip() {
  local domain="$1" ip=""
  if command_exists getent; then ip="$(getent ahosts "${domain}" 2>/dev/null | awk '{print $1}' | head -n1 || true)"; fi
  if [[ -z "${ip}" ]] && command_exists dig; then ip="$(dig +short A "${domain}" | head -n1 || true)"; fi
  if [[ -z "${ip}" ]] && command_exists nslookup; then ip="$(nslookup "${domain}" 2>/dev/null | awk '/^Address: /{print $2}' | tail -n1 || true)"; fi
  printf '%s' "${ip}"
}

ensure_domain_resolved() {
  local domain="$1"
  if ! validate_domain "${domain}"; then error "域名格式无效: ${domain}"; return 1; fi
  local ip; ip="$(resolve_domain_ip "${domain}")"
  if [[ -z "${ip}" ]]; then error "无法解析域名 ${domain}，请先完成 DNS 解析"; return 1; fi
  info "域名解析正常: ${domain} -> ${ip}"
}

is_port_in_use() {
  local port="$1"
  if command_exists ss; then ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$" && return 0; fi
  if command_exists netstat; then netstat -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${port}$" && return 0; fi
  return 1
}

fetch_latest_release_tag() {
  local repo="$1" response tag
  response="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null || true)"
  [[ -z "${response}" ]] && printf '' && return 0
  tag="$(printf '%s\n' "${response}" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  printf '%s' "${tag}"
}

# ══════════════════════════════════════════════════
# 状态管理
# ══════════════════════════════════════════════════
STATE_ALLOWED_KEYS=(
  MODE INSTALL_DIR API_TAG USER_TAG ADMIN_TAG DB_MODE DEPLOYED_AT
  HTTPS_ENABLED HTTPS_MODE USER_DOMAIN ADMIN_DOMAIN CERT_PROVIDER
  HTTPS_UPDATED_AT API_PORT POSTGRES_HOST POSTGRES_PORT
  POSTGRES_DB_NAME POSTGRES_DB_USER API_DOMAIN
)

ensure_state_dir() {
  mkdir -p "${STATE_DIR}"
  chmod 700 "${STATE_DIR}" 2>/dev/null || true
}

encode_state_value() {
  printf '%s' "${1}" | base64 | tr -d '\n'
}

decode_state_value() {
  printf '%s' "${1}" | base64 -d 2>/dev/null
}

parse_legacy_state_value() {
  local raw="$1"
  [[ "${raw}" == "''" ]] && { printf ''; return 0; }
  if [[ "${raw}" =~ ^\'(.*)\'$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  if [[ "${raw}" == *'$('* || "${raw}" == *'`'* || "${raw}" == *';'* ]]; then
    return 1
  fi
  raw="${raw//\\ / }"
  raw="${raw//\\\\/\\}"
  printf '%s' "${raw}"
}

clear_state_vars() {
  local key
  for key in "${STATE_ALLOWED_KEYS[@]}"; do
    unset "${key}"
  done
}

write_state_file() {
  local values=(
    "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}" "${9}" "${10}"
    "${11}" "${12}" "${13}" "${14}" "${15}" "${16}" "${17}" "${18}" "${19}"
  )
  local i
  ensure_state_dir
  {
    printf 'STATE_ENCODING=base64\n'
    for i in "${!STATE_ALLOWED_KEYS[@]}"; do
      printf '%s=%s\n' "${STATE_ALLOWED_KEYS[$i]}" "$(encode_state_value "${values[$i]}")"
    done
  } > "${STATE_FILE}"
  chmod 600 "${STATE_FILE}" 2>/dev/null || true
}

save_deploy_state() {
  write_state_file "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" \
    "$(date '+%Y-%m-%d %H:%M:%S')" "false" "" "" "" "" "" \
    "" "" "" "" "" ""
}

save_https_state() {
  if ! load_deploy_state; then error "未找到部署记录"; return 1; fi
  write_state_file "${MODE:-}" "${INSTALL_DIR:-}" "${API_TAG:-}" "${USER_TAG:-}" \
    "${ADMIN_TAG:-}" "${DB_MODE:-}" "${DEPLOYED_AT:-}" "true" \
    "${1}" "${2}" "${3}" "${4}" "$(date '+%Y-%m-%d %H:%M:%S')" \
    "${API_PORT:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT:-}" \
    "${POSTGRES_DB_NAME:-}" "${POSTGRES_DB_USER:-}" "${5:-${API_DOMAIN:-}}"
}

load_deploy_state() {
  [[ ! -f "${STATE_FILE}" ]] && return 1
  clear_state_vars

  local is_base64="false"
  local line key value decoded legacy_rewrite="false"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ "${line}" != *=* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    if [[ "${key}" == "STATE_ENCODING" ]]; then
      [[ "${value}" == "base64" ]] && is_base64="true"
      continue
    fi
    [[ " ${STATE_ALLOWED_KEYS[*]} " == *" ${key} "* ]] || continue
    if [[ "${is_base64}" == "true" ]]; then
      decoded="$(decode_state_value "${value}")" || return 1
    else
      decoded="$(parse_legacy_state_value "${value}")" || return 1
      legacy_rewrite="true"
    fi
    printf -v "${key}" '%s' "${decoded}"
  done < "${STATE_FILE}"

  if [[ "${legacy_rewrite}" == "true" ]]; then
    write_state_file \
      "${MODE:-}" "${INSTALL_DIR:-}" "${API_TAG:-}" "${USER_TAG:-}" "${ADMIN_TAG:-}" \
      "${DB_MODE:-}" "${DEPLOYED_AT:-}" "${HTTPS_ENABLED:-}" "${HTTPS_MODE:-}" \
      "${USER_DOMAIN:-}" "${ADMIN_DOMAIN:-}" "${CERT_PROVIDER:-}" "${HTTPS_UPDATED_AT:-}" \
      "${API_PORT:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT:-}" "${POSTGRES_DB_NAME:-}" \
      "${POSTGRES_DB_USER:-}" "${API_DOMAIN:-}"
  fi
  return 0
}

get_saved_api_port() {
  if [[ -n "${API_PORT:-}" ]]; then
    printf '%s' "${API_PORT}"
    return 0
  fi

  local install_dir="${INSTALL_DIR:-}"
  if [[ -n "${install_dir}" && -f "${install_dir}/.env" ]]; then
    grep '^API_PORT=' "${install_dir}/.env" 2>/dev/null | cut -d= -f2 | head -n1
    return 0
  fi

  if [[ -n "${install_dir}" && -f "${install_dir}/config.yml" ]]; then
    awk '
      /^server:/ { in_server=1; next }
      /^[^[:space:]]/ { if (in_server) exit }
      in_server && $1 == "port:" { print $2; exit }
    ' "${install_dir}/config.yml"
    return 0
  fi

  printf '8080'
}

# ══════════════════════════════════════════════════
# 写入 Docker .env 文件  【FIX: 原脚本缺失此函数】
# ══════════════════════════════════════════════════
write_docker_env_file() {
  local env_file="$1"  tag="$2"       tz="$3"
  local api_port="$4"  user_port="$5" admin_port="$6"
  local redis_port="$7" postgres_port="$8" redis_password="$9"
  local postgres_db="${10}" postgres_user="${11}" postgres_password="${12}"
  local admin_username="${13}" admin_password="${14}"

  cat > "${env_file}" << ENVEOF
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

# ══════════════════════════════════════════════════
# 自动安装 Docker
# ══════════════════════════════════════════════════
auto_install_docker() {
  if command_exists docker && docker compose version >/dev/null 2>&1; then
    systemctl start docker 2>/dev/null || true
    return 0
  fi

  warn "未检测到 Docker，正在自动安装..."
  local installed=false

  # ── 辅助：清理所有残留的 docker apt 源和 key ──────
  _cleanup_docker_apt() {
    rm -f /etc/apt/sources.list.d/docker.list \
          /usr/share/keyrings/docker-archive-keyring.gpg \
          /usr/share/keyrings/docker.gpg \
          /tmp/docker.gpg 2>/dev/null || true
    # 同时清除官方脚本可能写入的其他位置
    rm -f /etc/apt/keyrings/docker.gpg \
          /etc/apt/keyrings/docker.asc 2>/dev/null || true
    apt-get clean -qq 2>/dev/null || true
  }

  # ── 辅助：用指定 gpg_url + apt_url 安装 docker ───
  _try_install_from_mirror() {
    local gpg_url="$1" apt_url="$2" label="$3"
    info "尝试 ${label} 镜像..."
    _cleanup_docker_apt

    # 必须先 update 一次清除错误缓存，忽略报错
    apt-get update -qq 2>/dev/null || true

    # 下载 GPG key 到临时文件，再 dearmor，避免管道中断导致写入不完整
    if ! curl -fsSL --connect-timeout 10 "${gpg_url}" -o /tmp/docker.gpg 2>/dev/null; then
      warn "${label}: GPG key 下载失败，跳过"
      return 1
    fi

    mkdir -p /usr/share/keyrings
    gpg --batch --yes --dearmor < /tmp/docker.gpg \
      > /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null
    chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg
    rm -f /tmp/docker.gpg

    # 验证 key 是否有效（能列出 key 说明 dearmor 成功）
    if ! gpg --no-default-keyring \
             --keyring /usr/share/keyrings/docker-archive-keyring.gpg \
             --list-keys >/dev/null 2>&1; then
      warn "${label}: GPG key 无效，跳过"
      return 1
    fi

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
${apt_url} $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    if apt-get update -qq 2>&1 | grep -q "NO_PUBKEY\|not signed"; then
      warn "${label}: apt update 签名验证仍失败，跳过"
      return 1
    fi

    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  }

  # ── Step 1: 先尝试官方脚本（会自行处理 GPG） ───────
  # 但官方脚本若之前已写入损坏源，需先清理
  _cleanup_docker_apt
  if curl -fsSL --connect-timeout 8 https://get.docker.com -o /tmp/get-docker.sh 2>/dev/null; then
    if bash /tmp/get-docker.sh 2>&1; then installed=true; fi
  fi

  # ── Step 2: 官方失败，依次尝试国内镜像 ─────────────
  if [[ "${installed}" == false ]] && command_exists apt-get; then
    apt-get install -y -qq apt-transport-https ca-certificates gnupg lsb-release curl 2>/dev/null || true

    local mirrors=(
      "https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg|https://mirrors.aliyun.com/docker-ce/linux/ubuntu|阿里云"
      "https://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu/gpg|https://mirrors.cloud.tencent.com/docker-ce/linux/ubuntu|腾讯云"
      "https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg|https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu|中科大"
    )
    for entry in "${mirrors[@]}"; do
      local gpg_url apt_url label
      gpg_url="${entry%%|*}"
      apt_url="${entry#*|}"
      apt_url="${apt_url%%|*}"
      label="${entry##*|}"
      if _try_install_from_mirror "${gpg_url}" "${apt_url}" "${label}"; then
        installed=true; break
      fi
    done
  elif [[ "${installed}" == false ]] && command_exists yum; then
    yum install -y -q yum-utils
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin && installed=true
  fi

  if ! command_exists docker; then
    error "Docker 自动安装失败，请手动执行："
    error "  curl -fsSL https://get.docker.com | bash"
    print_fail_author; exit 1
  fi

  systemctl start docker
  systemctl enable docker 2>/dev/null || true
  success "Docker 安装完成"
}

# ══════════════════════════════════════════════════
# Docker 镜像加速
# ══════════════════════════════════════════════════
setup_docker_mirror() {
  info "检测 Docker Hub 连通性..."
  if curl -s --connect-timeout 5 https://registry-1.docker.io/v2/ > /dev/null 2>&1; then
    success "Docker Hub 连通正常，无需配置镜像加速"
    return 0
  fi
  warn "Docker Hub 不可达，配置国内镜像加速..."
  local mirrors=("https://docker.1ms.run" "https://docker.xuanyuan.me" "https://docker.m.daocloud.io" "https://hub.rat.dev")
  local available=""
  for m in "${mirrors[@]}"; do
    if curl -s --connect-timeout 3 "${m}/v2/" > /dev/null 2>&1; then
      available="${m}"; success "可用镜像源: ${m}"; break
    fi
  done
  [[ -z "${available}" ]] && available="https://docker.1ms.run"
  mkdir -p /etc/docker
  [[ -f /etc/docker/daemon.json ]] && cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
  cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["${available}", "https://docker.1ms.run", "https://docker.m.daocloud.io"],
  "log-driver": "json-file",
  "log-opts": {"max-size": "100m", "max-file": "3"}
}
EOF
  systemctl daemon-reload 2>/dev/null || true
  systemctl restart docker 2>/dev/null || service docker restart 2>/dev/null || true
  success "Docker 镜像加速配置完成"
}

fix_redis_kernel_params() {
  if [[ "$(sysctl -n vm.overcommit_memory 2>/dev/null)" != "1" ]]; then
    info "设置 vm.overcommit_memory=1（Redis 推荐）..."
    sysctl -w vm.overcommit_memory=1 >/dev/null 2>&1 || true
    grep -q "vm.overcommit_memory" /etc/sysctl.conf       || echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
  fi
  if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
  fi
}

# ══════════════════════════════════════════════════
# Docker 部署
# ══════════════════════════════════════════════════
select_docker_database_mode() {
  local choice=""
  while true; do
    print_line
    echo "  请选择数据库方案："
    print_line
    echo "  1) SQLite + Redis     （轻量级，适合低流量场景）"
    echo "  2) PostgreSQL + Redis （稳定可靠，推荐生产环境）"
    print_line
    printf '  请输入选项 [1-2] (默认 1): ' >&2
    read -r choice
    choice="$(trim "${choice:-1}")"
    case "${choice}" in
      1) _DB_MODE="sqlite";   return 0 ;;
      2) _DB_MODE="postgres"; return 0 ;;
      *) warn "无效选项: ${choice}，请输入 1 或 2" ;;
    esac
  done
}

write_docker_config_file() {
  local config_file="$1" db_mode="$2" redis_password="$3"
  local postgres_db="$4" postgres_user="$5" postgres_password="$6"
  local jwt_secret; jwt_secret="$(random_string 40)"
  local user_jwt_secret; user_jwt_secret="$(random_string 40)"
  local dsn
  if [[ "${db_mode}" == "postgres" ]]; then
    dsn="host=postgres user=${postgres_user} password=${postgres_password} dbname=${postgres_db} port=5432 sslmode=disable TimeZone=Asia/Shanghai"
  else
    dsn="/app/db/dujiao.db"
  fi
  cat > "${config_file}" << CFGEOF
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
  cat > "${1}" << 'SQLITEEOF'
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
      test: ["CMD-SHELL", "redis-cli -a \"$${REDIS_PASSWORD}\" ping 2>/dev/null && exit 0 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 30
      start_period: 5s
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
  cat > "${1}" << 'POSTGRESEOF'
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
      test: ["CMD-SHELL", "redis-cli -a \"$${REDIS_PASSWORD}\" ping 2>/dev/null && exit 0 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 30
      start_period: 5s
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

# ══════════════════════════════════════════════════
# Nginx 安装 & 配置 & SSL
# ══════════════════════════════════════════════════
auto_install_nginx() {
  if command_exists nginx; then
    info "Nginx 已安装: $(nginx -v 2>&1)"
    systemctl start nginx 2>/dev/null || service nginx start 2>/dev/null || true
    return 0
  fi
  info "安装 Nginx..."
  if command_exists apt-get; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx
  elif command_exists yum; then
    yum install -y -q nginx
  else
    error "不支持的包管理器，请手动安装 Nginx"; print_fail_author; return 1
  fi
  systemctl enable nginx 2>/dev/null || true
  systemctl start nginx 2>/dev/null || true
  success "Nginx 安装完成"
}

write_nginx_binary_site() {
  local conf_file="$1" server_name="$2" dist_dir="$3"
  local api_port="$4" ssl="$5" cert_dir="$6"

  if [[ "${ssl}" == "true" ]]; then
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${server_name};
    ssl_certificate     ${cert_dir}/fullchain.pem;
    ssl_certificate_key ${cert_dir}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;
    client_max_body_size 100m;
    root ${dist_dir};
    index index.html;
    location /api/ {
        proxy_pass         http://127.0.0.1:${api_port}/api/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120s;
    }
    location /uploads/ {
        proxy_pass         http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
    }
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGEOF
  else
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    client_max_body_size 100m;
    root ${dist_dir};
    index index.html;
    location /api/ {
        proxy_pass         http://127.0.0.1:${api_port}/api/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }
    location /uploads/ {
        proxy_pass         http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
    }
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGEOF
  fi
}

setup_nginx_binary_sites() {
  local user_domain="$1" admin_domain="$2" api_domain="$3"
  local install_dir="$4" api_port="$5" ssl="$6" cert_base="$7"

  local nginx_dir
  if [[ -d /etc/nginx/sites-enabled ]]; then
    nginx_dir="/etc/nginx/sites-available"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  else
    nginx_dir="/etc/nginx/conf.d"
    mkdir -p /etc/nginx/conf.d
  fi

  write_nginx_binary_site "${nginx_dir}/dujiao-user.conf" \
    "${user_domain}" "${install_dir}/user/dist" \
    "${api_port}" "${ssl}" "${cert_base}/${user_domain}"

  write_nginx_binary_site "${nginx_dir}/dujiao-admin.conf" \
    "${admin_domain}" "${install_dir}/admin/dist" \
    "${api_port}" "${ssl}" "${cert_base}/${admin_domain}"

  write_nginx_api_site "${nginx_dir}/dujiao-api.conf" \
    "${api_domain}" "${api_port}" "${ssl}" "${cert_base}/${api_domain}"

  if [[ -d /etc/nginx/sites-enabled ]]; then
    ln -sf "${nginx_dir}/dujiao-user.conf"  /etc/nginx/sites-enabled/dujiao-user.conf
    ln -sf "${nginx_dir}/dujiao-admin.conf" /etc/nginx/sites-enabled/dujiao-admin.conf
    ln -sf "${nginx_dir}/dujiao-api.conf"   /etc/nginx/sites-enabled/dujiao-api.conf
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
  fi

  reload_nginx
}

write_nginx_api_site() {
  local conf_file="$1" server_name="$2" api_port="$3"
  local ssl="$4" cert_dir="$5"

  if [[ "${ssl}" == "true" ]]; then
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${server_name};
    ssl_certificate     ${cert_dir}/fullchain.pem;
    ssl_certificate_key ${cert_dir}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;
    client_max_body_size 100m;
    location / {
        proxy_pass         http://127.0.0.1:${api_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120s;
    }
}
NGEOF
  else
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    client_max_body_size 100m;
    location / {
        proxy_pass         http://127.0.0.1:${api_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }
}
NGEOF
  fi
}

write_nginx_site() {
  local conf_file="$1"
  local server_name="$2"
  local proxy_port="$3"
  local api_port="$4"
  local ssl="$5"
  local cert_dir="$6"

  if [[ "${ssl}" == "true" ]]; then
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${server_name};

    ssl_certificate     ${cert_dir}/fullchain.pem;
    ssl_certificate_key ${cert_dir}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;

    client_max_body_size 100m;

    location /api/ {
        proxy_pass         http://127.0.0.1:${api_port}/api/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120s;
    }
    location /uploads/ {
        proxy_pass         http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
    }
    location / {
        proxy_pass         http://127.0.0.1:${proxy_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
    }
}
NGEOF
  else
    cat > "${conf_file}" << NGEOF
server {
    listen 80;
    server_name ${server_name};

    client_max_body_size 100m;

    location /api/ {
        proxy_pass         http://127.0.0.1:${api_port}/api/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }
    location /uploads/ {
        proxy_pass         http://127.0.0.1:${api_port}/uploads/;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
    }
    location / {
        proxy_pass         http://127.0.0.1:${proxy_port};
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
    }
}
NGEOF
  fi
}

reload_nginx() {
  if nginx -t >/dev/null 2>&1; then
    systemctl reload nginx 2>/dev/null || nginx -s reload 2>/dev/null || true
    success "Nginx 配置重载成功"
  else
    error "Nginx 配置检查失败:"
    nginx -t
    return 1
  fi
}

setup_nginx_sites() {
  local user_domain="$1" admin_domain="$2" api_domain="$3"
  local user_port="$4"   admin_port="$5"   api_port="$6"
  local ssl="$7"         cert_base="$8"

  local nginx_dir
  if [[ -d /etc/nginx/sites-enabled ]]; then
    nginx_dir="/etc/nginx/sites-available"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  else
    nginx_dir="/etc/nginx/conf.d"
    mkdir -p /etc/nginx/conf.d
  fi

  local user_cert="${cert_base}/${user_domain}"
  local admin_cert="${cert_base}/${admin_domain}"
  local api_cert="${cert_base}/${api_domain}"

  write_nginx_site     "${nginx_dir}/dujiao-user.conf"  "${user_domain}"  "${user_port}"  "${api_port}" "${ssl}" "${user_cert}"
  write_nginx_site     "${nginx_dir}/dujiao-admin.conf" "${admin_domain}" "${admin_port}" "${api_port}" "${ssl}" "${admin_cert}"
  write_nginx_api_site "${nginx_dir}/dujiao-api.conf"   "${api_domain}"   "${api_port}"   "${ssl}"      "${api_cert}"

  if [[ -d /etc/nginx/sites-enabled ]]; then
    ln -sf "${nginx_dir}/dujiao-user.conf"  /etc/nginx/sites-enabled/dujiao-user.conf
    ln -sf "${nginx_dir}/dujiao-admin.conf" /etc/nginx/sites-enabled/dujiao-admin.conf
    ln -sf "${nginx_dir}/dujiao-api.conf"   /etc/nginx/sites-enabled/dujiao-api.conf
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
  fi

  reload_nginx
}

setup_ssl_with_nginx() {
  local user_domain="$1" admin_domain="$2" api_domain="$3"
  local user_port="$4"   admin_port="$5"   api_port="$6"
  local deploy_dir="$7"  acme_email="$8"
  local cert_base="${deploy_dir}/certs"
  local acme_bin="${HOME}/.acme.sh/acme.sh"

  info "临时停止 Nginx 以使用 standalone 模式申请证书..."
  systemctl stop nginx 2>/dev/null || service nginx stop 2>/dev/null || true
  sleep 1

  local failed=false
  for domain in "${user_domain}" "${admin_domain}" "${api_domain}"; do
    info "申请证书: ${domain}"
    mkdir -p "${cert_base}/${domain}"
    local _issue_out
    _issue_out="$("${acme_bin}" --issue --server letsencrypt \
        -d "${domain}" --standalone --keylength ec-256 \
        --accountemail "${acme_email}" 2>&1)" || true
    # acme.sh 在证书未到期时会跳过并返回非零退出码，需单独判断
    if echo "${_issue_out}" | grep -qE "Skipping|Domains not changed|already issued"; then
      warn "证书有效期内无需重新申请，继续安装已有证书: ${domain}"
    elif ! echo "${_issue_out}" | grep -qE "Cert success|Your cert is in"; then
      # 既没有成功标志，也没有跳过标志，才是真正失败
      if ! "${acme_bin}" --list 2>/dev/null | grep -q "${domain}"; then
        error "域名 ${domain} 证书申请失败"
        echo "${_issue_out}" >&2
        failed=true; break
      fi
      warn "证书已存在，继续安装: ${domain}"
    fi
    "${acme_bin}" --install-cert -d "${domain}" --ecc \
      --key-file       "${cert_base}/${domain}/privkey.pem" \
      --fullchain-file "${cert_base}/${domain}/fullchain.pem" \
      --reloadcmd "true" || {
        error "证书安装失败: ${domain}"; failed=true; break
      }
    success "证书已就绪: ${domain}"
  done

  info "清理临时配置文件..."
  local nginx_dir
  if [[ -d /etc/nginx/sites-enabled ]]; then
    nginx_dir="/etc/nginx/sites-available"
    rm -f /etc/nginx/sites-available/*.conf.tmp
    rm -f /etc/nginx/sites-enabled/*.conf.tmp
  else
    nginx_dir="/etc/nginx/conf.d"
    rm -f /etc/nginx/conf.d/*.conf.tmp
  fi

  if [[ "${failed}" == "true" ]]; then
    systemctl start nginx 2>/dev/null || true
    print_fail_author; return 1
  fi

  info "写入 Nginx SSL 配置..."
  setup_nginx_sites "${user_domain}" "${admin_domain}" "${api_domain}" \
    "${user_port}" "${admin_port}" "${api_port}" "true" "${cert_base}" || {
    error "Nginx 配置写入失败"
    nginx -t 2>&1 || true
    print_fail_author; return 1
  }

  info "启动 Nginx..."
  systemctl start nginx 2>/dev/null || service nginx start 2>/dev/null || true
  sleep 1
  if systemctl is-active --quiet nginx 2>/dev/null || pgrep -x nginx >/dev/null 2>&1; then
    success "Nginx 已启动"
  else
    error "Nginx 启动失败，请检查: nginx -t && systemctl start nginx"
    print_fail_author; return 1
  fi

  local cron_job="0 3 * * * systemctl stop nginx 2>/dev/null; ${acme_bin} --cron --home ${HOME}/.acme.sh > /dev/null 2>&1; systemctl start nginx 2>/dev/null"
  { crontab -l 2>/dev/null | grep -v "acme.sh --cron"; echo "${cron_job}"; } | crontab - 2>/dev/null || true
  success "SSL 自动续期 cron 已设置（每天凌晨3点检查）"
  return 0
}

collect_domain_config() {
  echo "" >&2
  print_line >&2
  printf '%b\n' "  ${BOLD}🌐 域名配置${NC}" >&2
  print_line >&2
  echo "  请为三端分别绑定独立域名，并确保 DNS 已解析到本服务器" >&2
  echo "" >&2

  local user_domain admin_domain api_domain
  while true; do
    user_domain="$(prompt_with_default "用户端域名 (如 dujiao.yourdomain.com)" "")"
    validate_domain "${user_domain}" && break
    warn "域名格式不正确，请重新输入"
  done
  while true; do
    admin_domain="$(prompt_with_default "管理端域名 (如 admin.yourdomain.com)" "")"
    validate_domain "${admin_domain}" && [[ "${admin_domain}" != "${user_domain}" ]] && break
    warn "域名格式不正确或与用户端相同，请重新输入"
  done
  while true; do
    api_domain="$(prompt_with_default "API 域名     (如 api.yourdomain.com)" "")"
    validate_domain "${api_domain}" && [[ "${api_domain}" != "${user_domain}" ]] && [[ "${api_domain}" != "${admin_domain}" ]] && break
    warn "域名格式不正确或与已填写域名重复，请重新输入"
  done

  _USER_DOMAIN="${user_domain}"
  _ADMIN_DOMAIN="${admin_domain}"
  _API_DOMAIN="${api_domain}"

  echo "" >&2
  if ask_yes_no "是否自动申请 SSL 证书（Let's Encrypt，需域名已解析）" "y"; then
    _SSL_ENABLED="true"
    local default_email="admin@${user_domain}"
    _ACME_EMAIL="$(prompt_with_default "ACME 邮箱" "${default_email}")"
  else
    _SSL_ENABLED="false"
    _ACME_EMAIL=""
  fi
}

deploy_with_docker() {
  print_line
  echo "  ${BOLD}🐳 Docker Compose 部署${NC}"
  print_line

  auto_install_docker

  if ! docker info >/dev/null 2>&1; then
    error "无法连接 Docker daemon，请先启动 Docker"
    print_fail_author; return 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    error "未检测到 docker compose，请先安装 Docker Compose 插件"
    print_fail_author; return 1
  fi

  setup_docker_mirror
  fix_redis_kernel_params

  local db_mode
  _DB_MODE=""
  select_docker_database_mode
  db_mode="${_DB_MODE}"
  local latest_tag; latest_tag="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  local default_tag="${latest_tag:-latest}"
  local tag; tag="$(prompt_with_default "请输入镜像版本 TAG" "${default_tag}")"
  [[ -z "${tag}" ]] && tag="${default_tag}"

  local deploy_dir tz api_port user_port admin_port
  local redis_port postgres_port redis_password
  local postgres_db postgres_user postgres_password
  local admin_username admin_password

  deploy_dir="$(prompt_with_default "Install directory" "${HOME}/dujiao-next")"
  tz="$(prompt_with_default "时区" "Asia/Shanghai")"
  api_port="$(prompt_with_default "API 端口" "8080")"
  user_port="$(prompt_with_default "User 端口" "8081")"
  admin_port="$(prompt_with_default "Admin 端口" "8082")"
  redis_port="$(prompt_with_default "Redis 端口" "6379")"
  redis_password="$(prompt_with_default "Redis 密码" "$(random_string 16)")"

  if [[ "${db_mode}" == "postgres" ]]; then
    postgres_port="$(prompt_with_default "PostgreSQL 端口" "5432")"
    postgres_db="$(prompt_with_default "数据库名" "dujiao_next")"
    postgres_user="$(prompt_with_default "数据库用户名" "dujiao")"
    postgres_password="$(prompt_with_default "数据库密码" "$(random_string 16)")"
  else
    postgres_port="5432"; postgres_db="dujiao_next"
    postgres_user="dujiao"; postgres_password="$(random_string 16)"
  fi

  admin_username="$(prompt_with_default "管理员用户名" "admin")"
  admin_password="$(prompt_with_default "管理员密码" "Admin@123456")"

  local user_domain="" admin_domain="" api_domain="" ssl_enabled="" acme_email=""
  _USER_DOMAIN="" _ADMIN_DOMAIN="" _API_DOMAIN="" _SSL_ENABLED="" _ACME_EMAIL=""
  collect_domain_config
  user_domain="${_USER_DOMAIN}"
  admin_domain="${_ADMIN_DOMAIN}"
  api_domain="${_API_DOMAIN}"
  ssl_enabled="${_SSL_ENABLED}"
  acme_email="${_ACME_EMAIL}"

  mkdir -p "${deploy_dir}/config" "${deploy_dir}/data/db" \
    "${deploy_dir}/data/uploads" "${deploy_dir}/data/logs" \
    "${deploy_dir}/data/redis" "${deploy_dir}/acme-webroot"
  [[ "${db_mode}" == "postgres" ]] && mkdir -p "${deploy_dir}/data/postgres"

  local env_file="${deploy_dir}/.env"
  local config_file="${deploy_dir}/config/config.yml"
  local compose_file
  if [[ "${db_mode}" == "postgres" ]]; then
    compose_file="${deploy_dir}/docker-compose.postgres.yml"
  else
    compose_file="${deploy_dir}/docker-compose.sqlite.yml"
  fi

  write_docker_env_file "${env_file}" "${tag}" "${tz}" \
    "${api_port}" "${user_port}" "${admin_port}" \
    "${redis_port}" "${postgres_port}" "${redis_password}" \
    "${postgres_db}" "${postgres_user}" "${postgres_password}" \
    "${admin_username}" "${admin_password}"

  write_docker_config_file "${config_file}" "${db_mode}" \
    "${redis_password}" "${postgres_db}" "${postgres_user}" "${postgres_password}"

  if [[ "${db_mode}" == "postgres" ]]; then
    write_compose_postgres_file "${compose_file}"
  else
    write_compose_sqlite_file "${compose_file}"
  fi

  local retry=0
  while ! docker info >/dev/null 2>&1; do
    retry=$((retry+1))
    [[ ${retry} -gt 10 ]] && { error "Docker daemon 未就绪，请稍后重试"; print_fail_author; return 1; }
    info "等待 Docker daemon 启动... (${retry}/10)"
    sleep 3
  done

  info "拉取镜像中..."
  docker compose --env-file "${env_file}" -f "${compose_file}" pull || {
    error "镜像拉取失败，请检查网络连接"
    print_fail_author; return 1
  }

  info "启动服务中..."
  docker compose --env-file "${env_file}" -f "${compose_file}" up -d || {
    error "服务启动失败，查看详细日志："
    docker compose --env-file "${env_file}" -f "${compose_file}" logs --tail 30 || true
    print_fail_author; return 1
  }

  info "等待 API 就绪..."
  local health_retry=0
  while ! curl -sf "http://127.0.0.1:${api_port}/health" >/dev/null 2>&1; do
    health_retry=$((health_retry+1))
    [[ ${health_retry} -gt 20 ]] && { warn "API 健康检查超时，请稍后手动确认服务状态"; break; }
    printf '.' >&2; sleep 3
  done
  echo "" >&2
  [[ ${health_retry} -le 20 ]] && success "API 服务已就绪"

  auto_install_nginx
  if [[ -n "${user_domain}" && -n "${admin_domain}" ]]; then
    if [[ "${ssl_enabled}" == "true" ]]; then
      info "安装 acme.sh..."
      install_or_prepare_acme_sh "${acme_email}"
      info "申请 SSL 证书并配置 Nginx HTTPS..."
      setup_ssl_with_nginx \
        "${user_domain}" "${admin_domain}" "${api_domain}" \
        "${user_port}" "${admin_port}" "${api_port}" \
        "${deploy_dir}" "${acme_email}" || {
        error "SSL 证书配置失败，请检查日志"
        print_fail_author; return 1
      }
    else
      info "配置 Nginx HTTP 反向代理..."
      setup_nginx_sites \
        "${user_domain}" "${admin_domain}" "${api_domain}" \
        "${user_port}" "${admin_port}" "${api_port}" \
        "false" "${deploy_dir}/certs"
    fi
  fi

  save_deploy_state "docker" "${deploy_dir}" "${tag}" "${tag}" "${tag}" "${db_mode}"
  if [[ -n "${user_domain}" ]]; then
    local https_mode cert_provider
    if [[ "${ssl_enabled}" == "true" ]]; then
      https_mode="docker-nginx-ssl"; cert_provider="acme-http01"
    else
      https_mode="docker-nginx-http"; cert_provider="none"
    fi
    write_state_file "docker" "${deploy_dir}" "${tag}" "${tag}" "${tag}" \
      "${db_mode}" "$(date '+%Y-%m-%d %H:%M:%S')" \
      "${ssl_enabled}" "${https_mode}" \
      "${user_domain}" "${admin_domain}" \
      "${cert_provider}" "$(date '+%Y-%m-%d %H:%M:%S')" \
      "${api_port}" "postgres" "5432" "${postgres_db:-}" "${postgres_user:-}" "${api_domain:-}"
  fi

  local db_label="SQLite + Redis"
  [[ "${db_mode}" == "postgres" ]] && db_label="PostgreSQL + Redis"
  local proto="http"
  [[ "${ssl_enabled}" == "true" ]] && proto="https"

  echo ""
  print_line
  echo "  ${G}${BOLD}🎉 Docker 部署完成！${NC}"
  print_line
  echo "  部署目录  : ${deploy_dir}"
  echo "  数据库    : ${db_label}"
  echo "  管理员    : ${admin_username} / ${admin_password}"
  echo ""
  if [[ -n "${user_domain}" ]]; then
    echo "  User  : ${proto}://${user_domain}"
    echo "  Admin : ${proto}://${admin_domain}"
    echo "  API   : ${proto}://${api_domain}"
  fi
  echo "  API 健康检查 : http://127.0.0.1:${api_port}/health"
  echo ""
  echo "  ${Y}⚠️  请立即登录管理端修改默认密码！${NC}"
  [[ "${ssl_enabled}" == "true" ]] && echo "  ${G}✅ SSL 证书已申请，自动续期每天凌晨3点执行${NC}"
  print_author
}

# ══════════════════════════════════════════════════
# 二进制部署
# ══════════════════════════════════════════════════
detect_binary_arch() {
  local os arch; os="$(uname -s)"; arch="$(uname -m)"
  [[ "${os}" != "Linux" ]] && { error "二进制部署仅支持 Linux"; return 1; }
  case "${arch}" in
    x86_64|amd64)  printf 'x86_64'; return 0 ;;
    aarch64|arm64) printf 'arm64';  return 0 ;;
    *) error "不支持的架构: ${arch}"; return 1 ;;
  esac
}

download_asset() {
  info "下载: ${1}"
  if ! curl -fL --retry 2 --connect-timeout 10 --max-time 300 "${1}" -o "${2}"; then
    error "下载失败: ${1}"; return 1
  fi
}

extract_api_package() {
  local pkg="$1" dir="$2" tmp; tmp="$(mktemp -d)"
  tar -xzf "${pkg}" -C "${tmp}"
  local bin; bin="$(find "${tmp}" -type f -name "dujiao-next" | head -n1)"
  [[ -z "${bin}" ]] && { rm -rf "${tmp}"; error "包内未找到 dujiao-next 可执行文件"; return 1; }
  mkdir -p "${dir}/api"
  cp -f "${bin}" "${dir}/api/dujiao-next"
  chmod +x "${dir}/api/dujiao-next"
  rm -rf "${tmp}"
}

extract_frontend_package() {
  local pkg="$1" target="$2" tmp; tmp="$(mktemp -d)"
  unzip -oq "${pkg}" -d "${tmp}"
  local dist; dist="$(find "${tmp}" -type d -name dist | head -n1)"
  [[ -z "${dist}" ]] && { rm -rf "${tmp}"; error "包内未找到 dist 目录"; return 1; }
  rm -rf "${target}"; mkdir -p "${target}"
  cp -R "${dist}/." "${target}/"
  rm -rf "${tmp}"
}

write_binary_config_file() {
  local config_file="$1" install_dir="$2" api_port="$3"
  local admin_user="$4" admin_pass="$5" redis_pass="$6"
  local jwt; jwt="$(random_string 40)"
  local ujwt; ujwt="$(random_string 40)"
  cat > "${config_file}" << CFGEOF
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
  secret: ${jwt}
  expire_hours: 24

user_jwt:
  secret: ${ujwt}
  expire_hours: 24
  remember_me_expire_hours: 168

bootstrap:
  default_admin_username: "${admin_user}"
  default_admin_password: "${admin_pass}"

redis:
  enabled: true
  host: 127.0.0.1
  port: 6379
  password: "${redis_pass}"
  db: 0
  prefix: "dj"

queue:
  enabled: true
  host: 127.0.0.1
  port: 6379
  password: "${redis_pass}"
  db: 1
  concurrency: 10
  queues:
    default: 10
    critical: 5

email:
  enabled: false
CFGEOF
}

setup_systemd_service() {
  local install_dir="$1" service_name="$2" tz="$3" uname="$4" upass="$5"
  local service_file="/etc/systemd/system/${service_name}"
  ! command_exists systemctl && { warn "未找到 systemctl，跳过服务配置"; return 1; }
  local tmp; tmp="$(mktemp)"
  cat > "${tmp}" << SVCEOF
[Unit]
Description=Dujiao-Next API Service
After=network.target

[Service]
Type=simple
WorkingDirectory=${install_dir}
Environment=TZ=${tz}
Environment=DJ_DEFAULT_ADMIN_USERNAME=${uname}
Environment=DJ_DEFAULT_ADMIN_PASSWORD=${upass}
ExecStart=${install_dir}/api/dujiao-next -mode all
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SVCEOF
  run_as_root install -m 644 "${tmp}" "${service_file}"
  run_as_root systemctl daemon-reload
  run_as_root systemctl enable --now "${service_name}"
  rm -f "${tmp}"
}

deploy_with_binary() {
  print_line
  echo "  ${BOLD}⚙️  二进制部署${NC}"
  print_line

  for cmd in tar unzip curl; do
    if ! command_exists "${cmd}"; then
      info "安装 ${cmd}..."
      if command_exists apt-get; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${cmd}"
      elif command_exists yum; then
        yum install -y -q "${cmd}"
      else
        error "无法自动安装 ${cmd}，请手动安装后重试"
        print_fail_author; return 1
      fi
    fi
  done

  if ! command_exists redis-server; then
    info "安装 Redis..."
    if command_exists apt-get; then
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq redis-server
    elif command_exists yum; then
      yum install -y -q redis
    else
      error "无法自动安装 Redis，请手动安装后重试"
      print_fail_author; return 1
    fi
  fi
  systemctl enable redis-server 2>/dev/null || systemctl enable redis 2>/dev/null || true
  systemctl start redis-server 2>/dev/null || systemctl start redis 2>/dev/null || true
  sleep 1
  if redis-cli ping 2>/dev/null | grep -q PONG; then
    success "Redis 已就绪"
  else
    error "Redis 启动失败，请手动检查"
    print_fail_author; return 1
  fi

  local arch; arch="$(detect_binary_arch)"
  local latest_tag; latest_tag="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  local default_tag="${latest_tag:-v0.0.1-beta}"
  local tag; tag="$(prompt_with_default "请输入版本 TAG" "${default_tag}")"
  [[ -z "${tag}" || "${tag}" == "latest" ]] && tag="${default_tag}"

  local install_dir tz api_port user_port admin_port admin_username admin_password
  install_dir="$(prompt_with_default "部署目录" "${HOME}/dujiao-next-bin")"
  tz="$(prompt_with_default "时区" "Asia/Shanghai")"
  api_port="$(prompt_with_default "API 端口" "8080")"
  user_port="$(prompt_with_default "User 端口" "8081")"
  admin_port="$(prompt_with_default "Admin 端口" "8082")"
  admin_username="$(prompt_with_default "管理员用户名" "admin")"
  admin_password="$(prompt_with_default "管理员密码" "Admin@123456")"

  mkdir -p "${install_dir}/packages" "${install_dir}/api" \
    "${install_dir}/user/dist" "${install_dir}/admin/dist" \
    "${install_dir}/db" "${install_dir}/uploads" \
    "${install_dir}/logs" "${install_dir}/acme-webroot" \
    "${install_dir}/certs"

  # 确保 Nginx（www-data）能进入安装目录路径中的每一级
  # 逐级对父目录添加 o+x（进入权限），不影响文件读写安全性
  # 无论用户把程序装在哪个目录下都能正确处理
  local _fix_dir="${install_dir}"
  while [[ "${_fix_dir}" != "/" && "${_fix_dir}" != "." ]]; do
    chmod o+x "${_fix_dir}" 2>/dev/null || true
    _fix_dir="$(dirname "${_fix_dir}")"
  done

  local api_pkg="${install_dir}/packages/api-${tag}.tar.gz"
  local user_pkg="${install_dir}/packages/user-${tag}.zip"
  local admin_pkg="${install_dir}/packages/admin-${tag}.zip"

  download_asset "https://github.com/${DUJIAO_API_REPO}/releases/download/${tag}/dujiao-next_${tag}_Linux_${arch}.tar.gz" "${api_pkg}"
  download_asset "https://github.com/${DUJIAO_USER_REPO}/releases/download/${tag}/dujiao-next-user-${tag}.zip" "${user_pkg}"
  download_asset "https://github.com/${DUJIAO_ADMIN_REPO}/releases/download/${tag}/dujiao-next-admin-${tag}.zip" "${admin_pkg}"

  extract_api_package "${api_pkg}" "${install_dir}"
  extract_frontend_package "${user_pkg}" "${install_dir}/user/dist"
  extract_frontend_package "${admin_pkg}" "${install_dir}/admin/dist"

  chmod -R o+rX "${install_dir}/user/dist"
  chmod -R o+rX "${install_dir}/admin/dist"

  write_binary_config_file "${install_dir}/config.yml" "${install_dir}" "${api_port}" "${admin_username}" "${admin_password}" ""

  if ask_yes_no "是否创建并启动 systemd 服务" "y"; then
    if setup_systemd_service "${install_dir}" "dujiao-next-api.service" "${tz}" "${admin_username}" "${admin_password}"; then
      success "systemd 服务已启动（后台运行，稍后可通过 systemctl status dujiao-next-api 查看状态）"
    else
      warn "请手动运行: cd ${install_dir} && ./api/dujiao-next -mode all"
    fi
  fi

  local user_domain="" admin_domain="" api_domain="" ssl_enabled="" acme_email=""
  _USER_DOMAIN="" _ADMIN_DOMAIN="" _API_DOMAIN="" _SSL_ENABLED="" _ACME_EMAIL=""
  collect_domain_config
  user_domain="${_USER_DOMAIN}"
  admin_domain="${_ADMIN_DOMAIN}"
  api_domain="${_API_DOMAIN}"
  ssl_enabled="${_SSL_ENABLED}"
  acme_email="${_ACME_EMAIL}"

  auto_install_nginx
  if [[ -n "${user_domain}" && -n "${admin_domain}" && -n "${api_domain}" ]]; then
    if [[ "${ssl_enabled}" == "true" ]]; then
      info "安装 acme.sh..."
      install_or_prepare_acme_sh "${acme_email}"
      info "申请 SSL 证书并配置 Nginx HTTPS..."
      setup_ssl_with_nginx \
        "${user_domain}" "${admin_domain}" "${api_domain}" \
        "${user_port}" "${admin_port}" "${api_port}" \
        "${install_dir}" "${acme_email}" || {
        error "SSL 证书配置失败，请检查日志"
        print_fail_author; return 1
      }
      setup_nginx_binary_sites \
        "${user_domain}" "${admin_domain}" "${api_domain}" \
        "${install_dir}" "${api_port}" "true" "${install_dir}/certs"
    else
      info "配置 Nginx HTTP 静态文件模式..."
      setup_nginx_binary_sites \
        "${user_domain}" "${admin_domain}" "${api_domain}" \
        "${install_dir}" "${api_port}" "false" "${install_dir}/certs"
    fi
  fi

  save_deploy_state "binary" "${install_dir}" "${tag}" "${tag}" "${tag}" "sqlite"
  local https_mode="binary-nginx-http"
  local cert_provider="none"
  local proto="http"
  if [[ -n "${user_domain}" ]]; then
    if [[ "${ssl_enabled}" == "true" ]]; then
      https_mode="binary-nginx-ssl"; cert_provider="acme-http01"; proto="https"
    fi
    write_state_file "binary" "${install_dir}" "${tag}" "${tag}" "${tag}" \
      "sqlite" "$(date '+%Y-%m-%d %H:%M:%S')" \
      "${ssl_enabled}" "${https_mode}" \
      "${user_domain}" "${admin_domain}" \
      "${cert_provider}" "$(date '+%Y-%m-%d %H:%M:%S')" \
      "${api_port}" "" "" "" "" "${api_domain:-}"
  fi

  echo ""
  print_line
  echo "  ${G}${BOLD}🎉 二进制部署完成！${NC}"
  print_line
  echo "  部署目录  : ${install_dir}"
  echo "  架构      : Linux ${arch}"
  echo "  管理员    : ${admin_username} / ${admin_password}"
  echo ""
  if [[ -n "${user_domain}" ]]; then
    echo "  User  : ${proto}://${user_domain}"
    echo "  Admin : ${proto}://${admin_domain}"
    echo "  API   : ${proto}://${api_domain}"
  fi
  echo "  API 健康检查 : http://127.0.0.1:${api_port}/health"
  echo ""
  echo "  ${Y}⚠️  请立即登录管理端修改默认密码！${NC}"
  [[ "${ssl_enabled}" == "true" ]] && echo "  ${G}✅ SSL 证书已申请，自动续期每天凌晨3点执行${NC}"
  print_author
}

# ══════════════════════════════════════════════════
# 外部环境部署
# ══════════════════════════════════════════════════
deploy_external() {
  print_line
  echo "  ${BOLD}🔌 外部环境安装（已有面板/数据库）${NC}"
  print_line
  echo ""
  echo "  ${Y}请确认已在面板（1Panel/宝塔等）完成以下操作：${NC}"
  echo "  ✅ 安装 OpenResty 或 Nginx（用于配置反向代理）"
  echo "  ✅ 安装 PostgreSQL 并创建数据库和用户"
  echo "  ✅ 安装 Redis"
  echo ""
  if ! ask_yes_no "已完成以上操作，继续安装" "y"; then
    info "请先完成数据库准备工作，再重新运行脚本"; return 0
  fi

  auto_install_docker

  if ! docker info >/dev/null 2>&1; then
    error "无法连接 Docker daemon，请先通过面板安装 Docker"
    print_fail_author; return 1
  fi

  setup_docker_mirror

  info "检测可用的 Docker 网络..."
  local networks; networks="$(docker network ls --format '{{.Name}}' 2>/dev/null | grep -iv "bridge\|host\|none" || true)"
  local panel_network=""
  if [[ -n "${networks}" ]]; then
    echo ""
    echo "  检测到以下 Docker 网络："
    local i=1
    while IFS= read -r net; do
      echo "  ${i}) ${net}"; i=$((i+1))
    done <<< "${networks}"
    echo "  ${i}) 手动输入"
    echo ""
    printf '%s' "  请选择网络 [默认1]: " >&2
    read -r net_choice
    net_choice="$(trim "${net_choice}")"
    net_choice="${net_choice:-1}"
    local count; count="$(echo "${networks}" | wc -l)"
    if [[ "${net_choice}" -le "${count}" ]]; then
      panel_network="$(echo "${networks}" | sed -n "${net_choice}p")"
    else
      panel_network="$(prompt_with_default "Docker 网络名称" "1panel-network")"
    fi
  else
    panel_network="$(prompt_with_default "请输入 Docker 网络名称" "1panel-network")"
  fi
  success "已选择网络: ${panel_network}"

  local latest_tag; latest_tag="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  local tag; tag="$(prompt_with_default "镜像版本 TAG" "${latest_tag:-latest}")"
  local install_dir; install_dir="$(prompt_with_default "部署目录" "/opt/dujiao-next")"
  local api_port; api_port="$(prompt_with_default "API 端口" "8080")"
  local user_port; user_port="$(prompt_with_default "User 端口" "3001")"
  local admin_port; admin_port="$(prompt_with_default "Admin 端口" "3000")"

  echo ""
  print_line
  echo "  ${BOLD}🗄️  PostgreSQL 配置${NC}"
  print_line
  echo ""
  info "当前运行中的容器（仅供参考）："
  docker ps --format "  {{.Names}}\t{{.Image}}" 2>/dev/null | grep -i "postgres\|pg" || echo "  未找到 PostgreSQL 容器"
  echo ""
  local pg_host pg_port pg_db pg_user pg_password
  pg_host="$(prompt_with_default "PostgreSQL 容器名或IP" "1panel-postgresql")"
  pg_port="$(prompt_with_default "PostgreSQL 端口" "5432")"
  pg_db="$(prompt_with_default "数据库名" "dujiao")"
  pg_user="$(prompt_with_default "数据库用户名" "dujiao")"
  printf "  数据库密码 (无密码直接回车): " >&2
  read -r -s pg_password
  echo "" >&2

  echo ""
  print_line
  echo "  ${BOLD}📦 Redis 配置${NC}"
  print_line
  echo ""
  info "当前运行中的容器（仅供参考）："
  docker ps --format "  {{.Names}}\t{{.Image}}" 2>/dev/null | grep -i "redis" || echo "  未找到 Redis 容器"
  echo ""
  local redis_host redis_port redis_password
  redis_host="$(prompt_with_default "Redis 容器名或IP" "1panel-redis")"
  redis_port="$(prompt_with_default "Redis 端口" "6379")"
  printf "  Redis 密码 (无密码直接回车): " >&2
  read -r -s redis_password
  echo "" >&2

  local admin_username admin_password
  admin_username="$(prompt_with_default "管理员用户名" "admin")"
  admin_password="$(prompt_with_default "管理员密码" "Admin@123456")"

  mkdir -p "${install_dir}/uploads" "${install_dir}/logs"

  local jwt; jwt="$(random_string 40)"
  local ujwt; ujwt="$(random_string 40)"

  cat > "${install_dir}/config.yml" << CFGEOF
server:
  host: 0.0.0.0
  port: 8080
  mode: release

log:
  dir: /app/logs

database:
  driver: postgres
  dsn: "host=${pg_host} port=${pg_port} user=${pg_user} password=${pg_password} dbname=${pg_db} sslmode=disable TimeZone=Asia/Shanghai"

jwt:
  secret: ${jwt}
  expire_hours: 24

user_jwt:
  secret: ${ujwt}
  expire_hours: 24
  remember_me_expire_hours: 168

redis:
  enabled: true
  host: ${redis_host}
  port: ${redis_port}
  password: "${redis_password}"
  db: 0
  prefix: "dj"

queue:
  enabled: true
  host: ${redis_host}
  port: ${redis_port}
  password: "${redis_password}"
  db: 1
  concurrency: 10
  queues:
    default: 10
    critical: 5

bootstrap:
  default_admin_username: "${admin_username}"
  default_admin_password: "${admin_password}"

email:
  enabled: false
CFGEOF

  cat > "${install_dir}/docker-compose.yml" << COMPOSEEOF
services:
  api:
    image: dujiaonext/api:${tag}
    container_name: dujiaonext-api
    restart: unless-stopped
    environment:
      TZ: Asia/Shanghai
    ports:
      - "${api_port}:8080"
    volumes:
      - ./config.yml:/app/config.yml:ro
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 10
    networks:
      - ${panel_network}

  user:
    image: dujiaonext/user:${tag}
    container_name: dujiaonext-user
    restart: unless-stopped
    environment:
      TZ: Asia/Shanghai
    ports:
      - "${user_port}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - ${panel_network}

  admin:
    image: dujiaonext/admin:${tag}
    container_name: dujiaonext-admin
    restart: unless-stopped
    environment:
      TZ: Asia/Shanghai
    ports:
      - "${admin_port}:80"
    depends_on:
      api:
        condition: service_healthy
    networks:
      - ${panel_network}

networks:
  ${panel_network}:
    external: true
COMPOSEEOF

  info "拉取镜像中..."
  cd "${install_dir}" && docker compose pull

  info "启动服务中..."
  docker compose up -d

  write_state_file "external" "${install_dir}" "${tag}" "${tag}" "${tag}" \
    "postgres" "$(date '+%Y-%m-%d %H:%M:%S')" \
    "false" "" "" "" "" "" \
    "${api_port}" "${pg_host}" "${pg_port}" "${pg_db}" "${pg_user}" ""

  local server_ip; server_ip="$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "服务器IP")"
  echo ""
  print_line
  echo "  ${G}${BOLD}🎉 外部环境安装完成！${NC}"
  print_line
  echo "  安装目录  : ${install_dir}"
  echo "  管理员    : ${admin_username} / ${admin_password}"
  echo ""
  echo "  服务端口："
  echo "  API   : http://${server_ip}:${api_port}"
  echo "  User  : http://${server_ip}:${user_port}"
  echo "  Admin : http://${server_ip}:${admin_port}"
  echo ""
  echo "  ${Y}⚠️  请前往面板配置反向代理和 SSL：${NC}"
  echo "  User  域名 → 代理到 http://127.0.0.1:${user_port}"
  echo "  Admin 域名 → 代理到 http://127.0.0.1:${admin_port}"
  echo "  同时在 User/Admin 站点中添加以下路由代理："
  echo "    /api/      → http://127.0.0.1:${api_port}"
  echo "    /uploads/  → http://127.0.0.1:${api_port}"
  print_author
}

# ══════════════════════════════════════════════════
# HTTPS
# ══════════════════════════════════════════════════
precheck_https_common() {
  ensure_command curl; ensure_command openssl
  ensure_domain_resolved "${1}"; ensure_domain_resolved "${2}"
}

write_docker_https_caddyfile() {
  cat > "${1}" << EOF
{
    email ${4}
}

${2} {
    encode gzip
    @api path /api/* /uploads/*
    handle @api { reverse_proxy api:8080 }
    handle { reverse_proxy user:80 }
}

${3} {
    encode gzip
    @api path /api/* /uploads/*
    handle @api { reverse_proxy api:8080 }
    handle { reverse_proxy admin:80 }
}
EOF
}

write_docker_https_compose_file() {
  cat > "${1}" << 'EOF'
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
    networks:
      - dujiao-net
EOF
}

docker_compose_file_from_db_mode() {
  local dir="$1" mode="$2"
  if [[ "${mode}" == "postgres" ]]; then printf '%s/docker-compose.postgres.yml' "${dir}"
  else printf '%s/docker-compose.sqlite.yml' "${dir}"; fi
}

update_external_compose_tags() {
  local compose_file="$1" new_tag="$2"
  [[ ! -f "${compose_file}" ]] && { error "未找到 docker-compose.yml"; return 1; }

  sed -i -E \
    -e "s#(image:[[:space:]]*dujiaonext/api:).*#\1${new_tag}#" \
    -e "s#(image:[[:space:]]*dujiaonext/user:).*#\1${new_tag}#" \
    -e "s#(image:[[:space:]]*dujiaonext/admin:).*#\1${new_tag}#" \
    "${compose_file}"
}

enable_https_for_docker() {
  local install_dir="${INSTALL_DIR:-}" db_mode="${DB_MODE:-sqlite}"
  [[ -z "${install_dir}" ]] && { error "安装目录为空，请先完成部署"; return 1; }
  local env_file="${install_dir}/.env"
  local base_compose; base_compose="$(docker_compose_file_from_db_mode "${install_dir}" "${db_mode}")"
  [[ ! -f "${env_file}" || ! -f "${base_compose}" ]] && { error "未找到 Docker 部署文件"; return 1; }

  local user_domain admin_domain acme_email
  user_domain="$(prompt_with_default "User 域名" "${USER_DOMAIN:-user.example.com}")"
  admin_domain="$(prompt_with_default "Admin 域名" "${ADMIN_DOMAIN:-admin.example.com}")"
  [[ "${user_domain}" == "${admin_domain}" ]] && { error "两个域名不能相同"; return 1; }
  acme_email="$(prompt_with_default "ACME 邮箱" "admin@${user_domain}")"

  precheck_https_common "${user_domain}" "${admin_domain}"

  local caddy_dir="${install_dir}/caddy"
  local https_compose="${install_dir}/docker-compose.https.yml"
  mkdir -p "${caddy_dir}" "${install_dir}/data/caddy/data" "${install_dir}/data/caddy/config"
  backup_file "${caddy_dir}/Caddyfile"; backup_file "${https_compose}"

  write_docker_https_caddyfile "${caddy_dir}/Caddyfile" "${user_domain}" "${admin_domain}" "${acme_email}"
  write_docker_https_compose_file "${https_compose}"

  info "启动 Caddy HTTPS..."
  if ! docker compose --env-file "${env_file}" -f "${base_compose}" -f "${https_compose}" up -d caddy; then
    restore_file_if_needed "${caddy_dir}/Caddyfile"; restore_file_if_needed "${https_compose}"
    error "HTTPS 启动失败，已回滚配置"; print_fail_author; return 1
  fi

  save_https_state "docker-caddy" "${user_domain}" "${admin_domain}" "acme-http01" ""
  success "Docker HTTPS 已启用"
  echo ""
  echo "  User  HTTPS: https://${user_domain}"
  echo "  Admin HTTPS: https://${admin_domain}"
  print_author
}

install_or_prepare_acme_sh() {
  local acme_bin="${HOME}/.acme.sh/acme.sh"
  local acme_version="${ACME_SH_VERSION:-3.1.1}"
  local acme_url="https://raw.githubusercontent.com/acmesh-official/acme.sh/${acme_version}/acme.sh"
  local tmp_file expected_sha actual_sha
  [[ -x "${acme_bin}" ]] && return 0
  info "安装 acme.sh..."
  tmp_file="$(mktemp)"
  if ! curl --proto '=https' --tlsv1.2 -fsSL "${acme_url}" -o "${tmp_file}"; then
    rm -f "${tmp_file}"
    error "acme.sh 下载失败"
    return 1
  fi
  if ! grep -q "PROJECT_NAME='acme.sh'" "${tmp_file}"; then
    rm -f "${tmp_file}"
    error "acme.sh 下载内容校验失败"
    return 1
  fi
  expected_sha="${ACME_SH_INSTALL_SHA256:-}"
  if [[ -n "${expected_sha}" ]]; then
    actual_sha="$(sha256sum "${tmp_file}" | awk '{print $1}')"
    if [[ "${actual_sha}" != "${expected_sha}" ]]; then
      rm -f "${tmp_file}"
      error "acme.sh SHA256 校验失败"
      return 1
    fi
  else
    warn "未设置 ACME_SH_INSTALL_SHA256，已跳过 SHA256 校验"
  fi
  if ! sh "${tmp_file}" --install --home "${HOME}/.acme.sh" --accountemail "${1}"; then
    rm -f "${tmp_file}"
    error "acme.sh 安装失败"
    return 1
  fi
  rm -f "${tmp_file}"
}

enable_https_for_binary() {
  local install_dir="${INSTALL_DIR:-}"
  [[ -z "${install_dir}" || ! -f "${install_dir}/config.yml" ]] && { error "未找到二进制部署目录或配置文件"; return 1; }
  ensure_command nginx

  local user_domain admin_domain api_domain acme_email
  user_domain="$(prompt_with_default "User 域名" "${USER_DOMAIN:-user.example.com}")"
  admin_domain="$(prompt_with_default "Admin 域名" "${ADMIN_DOMAIN:-admin.example.com}")"
  api_domain="$(prompt_with_default "API 域名" "${API_DOMAIN:-api.example.com}")"
  [[ "${user_domain}" == "${admin_domain}" || "${user_domain}" == "${api_domain}" || "${admin_domain}" == "${api_domain}" ]] && { error "三个域名不能相同"; return 1; }
  acme_email="$(prompt_with_default "ACME 邮箱" "admin@${user_domain}")"

  precheck_https_common "${user_domain}" "${admin_domain}"
  ensure_domain_resolved "${api_domain}"
  install_or_prepare_acme_sh "${acme_email}"

  local api_port; api_port="$(get_saved_api_port)"
  local acme_bin="${HOME}/.acme.sh/acme.sh"
  local cert_base="${install_dir}/certs"

  # 申请三端证书：user 和 admin 用 webroot 模式，api 用 standalone 模式
  # （api 没有静态文件目录，需临时停 Nginx 用 standalone 申请）
  for domain in "${user_domain}" "${admin_domain}"; do
    local cert_dir="${cert_base}/${domain}"
    mkdir -p "${cert_dir}"
    local webroot
    [[ "${domain}" == "${user_domain}" ]] && webroot="${install_dir}/user/dist" || webroot="${install_dir}/admin/dist"
    local _issue_out
    _issue_out="$("${acme_bin}" --issue --server letsencrypt -d "${domain}" -w "${webroot}" --keylength ec-256 2>&1)" || true
    if echo "${_issue_out}" | grep -qE "Skipping|Domains not changed|already issued"; then
      warn "证书有效期内无需重新申请，继续安装已有证书: ${domain}"
    elif ! echo "${_issue_out}" | grep -qE "Cert success|Your cert is in"; then
      if ! "${acme_bin}" --list 2>/dev/null | grep -q "${domain}"; then
        error "证书签发失败: ${domain}"
        echo "${_issue_out}" >&2
        return 1
      fi
      warn "证书已存在，继续安装: ${domain}"
    fi
    "${acme_bin}" --install-cert -d "${domain}" --ecc \
      --key-file "${cert_dir}/privkey.pem" \
      --fullchain-file "${cert_dir}/fullchain.pem" \
      --reloadcmd "true" || { error "证书安装失败: ${domain}"; return 1; }
    success "证书已就绪: ${domain}"
  done

  # API 域名：临时停 Nginx，用 standalone 模式申请
  info "临时停止 Nginx 申请 API 域名证书..."
  systemctl stop nginx 2>/dev/null || service nginx stop 2>/dev/null || true
  sleep 1
  local api_cert_dir="${cert_base}/${api_domain}"
  mkdir -p "${api_cert_dir}"
  local _issue_api
  _issue_api="$("${acme_bin}" --issue --server letsencrypt -d "${api_domain}" --standalone --keylength ec-256 --accountemail "${acme_email}" 2>&1)" || true
  if echo "${_issue_api}" | grep -qE "Skipping|Domains not changed|already issued"; then
    warn "证书有效期内无需重新申请，继续安装已有证书: ${api_domain}"
  elif ! echo "${_issue_api}" | grep -qE "Cert success|Your cert is in"; then
    if ! "${acme_bin}" --list 2>/dev/null | grep -q "${api_domain}"; then
      error "API 域名证书签发失败: ${api_domain}"
      echo "${_issue_api}" >&2
      systemctl start nginx 2>/dev/null || service nginx start 2>/dev/null || true
      return 1
    fi
    warn "证书已存在，继续安装: ${api_domain}"
  fi
  "${acme_bin}" --install-cert -d "${api_domain}" --ecc \
    --key-file "${api_cert_dir}/privkey.pem" \
    --fullchain-file "${api_cert_dir}/fullchain.pem" \
    --reloadcmd "true" || { error "API 证书安装失败: ${api_domain}"; systemctl start nginx 2>/dev/null || true; return 1; }
  success "证书已就绪: ${api_domain}"

  # 写入三端 Nginx SSL 配置
  info "写入 Nginx SSL 配置..."
  setup_nginx_binary_sites \
    "${user_domain}" "${admin_domain}" "${api_domain}" \
    "${install_dir}" "${api_port}" "true" "${cert_base}"

  info "启动 Nginx..."
  systemctl start nginx 2>/dev/null || service nginx start 2>/dev/null || true
  sleep 1
  if systemctl is-active --quiet nginx 2>/dev/null || pgrep -x nginx >/dev/null 2>&1; then
    success "Nginx 已启动"
  else
    error "Nginx 启动失败，请检查: nginx -t && systemctl start nginx"
    return 1
  fi

  # 设置自动续期 cron
  local cron_job="0 3 * * * systemctl stop nginx 2>/dev/null; ${acme_bin} --cron --home ${HOME}/.acme.sh > /dev/null 2>&1; systemctl start nginx 2>/dev/null"
  { crontab -l 2>/dev/null | grep -v "acme.sh --cron"; echo "${cron_job}"; } | crontab - 2>/dev/null || true
  success "SSL 自动续期 cron 已设置（每天凌晨3点检查）"

  save_https_state "binary-nginx-ssl" "${user_domain}" "${admin_domain}" "acme-http01" "${api_domain:-}"
  success "二进制 HTTPS 配置完成"
  echo ""
  echo "  User  HTTPS: https://${user_domain}"
  echo "  Admin HTTPS: https://${admin_domain}"
  echo "  API   HTTPS: https://${api_domain}"
  print_author
}

configure_https() {
  if ! load_deploy_state; then error "未发现部署记录，请先部署"; return 1; fi
  case "${MODE:-}" in
    docker)   enable_https_for_docker ;;
    binary)   enable_https_for_binary ;;
    external) info "外部环境请在面板中配置 SSL 证书" ;;
    *) error "未知部署模式: ${MODE:-}" ;;
  esac
}

# ══════════════════════════════════════════════════
# 更新
# ══════════════════════════════════════════════════
update_binary() {
  local install_dir="$1"
  local current_tag="$2"
  local new_tag="$3"
  local arch; arch="$(detect_binary_arch)"
  local service_name="dujiao-next-api.service"

  print_line
  echo "  ${BOLD}⚙️  二进制更新${NC}"
  print_line
  echo "  安装目录 : ${install_dir}"
  echo "  当前版本 : ${current_tag:-未知}"
  echo "  目标版本 : ${new_tag}"
  echo ""

  if ! ask_yes_no "确认更新" "y"; then
    info "已取消更新"; return 0
  fi

  if command_exists systemctl && systemctl is-active --quiet "${service_name}" 2>/dev/null; then
    info "停止服务 ${service_name}..."
    run_as_root systemctl stop "${service_name}"
  fi

  if [[ -f "${install_dir}/api/dujiao-next" ]]; then
    cp -f "${install_dir}/api/dujiao-next" "${install_dir}/api/dujiao-next.bak"
    info "旧版本已备份至 dujiao-next.bak"
  fi

  local pkg_dir="${install_dir}/packages"
  mkdir -p "${pkg_dir}"
  local api_pkg="${pkg_dir}/api-${new_tag}.tar.gz"
  local user_pkg="${pkg_dir}/user-${new_tag}.zip"
  local admin_pkg="${pkg_dir}/admin-${new_tag}.zip"

  download_asset "https://github.com/${DUJIAO_API_REPO}/releases/download/${new_tag}/dujiao-next_${new_tag}_Linux_${arch}.tar.gz" "${api_pkg}" || {
    error "API 下载失败，回滚旧版本"
    [[ -f "${install_dir}/api/dujiao-next.bak" ]] && cp -f "${install_dir}/api/dujiao-next.bak" "${install_dir}/api/dujiao-next"
    run_as_root systemctl start "${service_name}" 2>/dev/null || true
    print_fail_author; return 1
  }
  download_asset "https://github.com/${DUJIAO_USER_REPO}/releases/download/${new_tag}/dujiao-next-user-${new_tag}.zip" "${user_pkg}" || {
    error "User 下载失败"; print_fail_author; return 1
  }
  download_asset "https://github.com/${DUJIAO_ADMIN_REPO}/releases/download/${new_tag}/dujiao-next-admin-${new_tag}.zip" "${admin_pkg}" || {
    error "Admin 下载失败"; print_fail_author; return 1
  }

  info "替换 API 二进制..."
  extract_api_package "${api_pkg}" "${install_dir}"

  info "替换 User 前端..."
  extract_frontend_package "${user_pkg}" "${install_dir}/user/dist"

  info "替换 Admin 前端..."
  extract_frontend_package "${admin_pkg}" "${install_dir}/admin/dist"

  if command_exists systemctl && systemctl is-enabled --quiet "${service_name}" 2>/dev/null; then
    info "重启服务 ${service_name}..."
    run_as_root systemctl start "${service_name}"
    sleep 3
    if systemctl is-active --quiet "${service_name}"; then
      success "服务启动成功"
    else
      warn "服务启动异常，请检查: journalctl -u ${service_name} -n 50"
    fi
  else
    warn "未找到 systemd 服务，请手动启动: cd ${install_dir} && ./api/dujiao-next -mode all"
  fi

  # 更新状态
  write_state_file "binary" "${install_dir}" "${new_tag}" "${new_tag}" "${new_tag}" \
    "sqlite" "$(date '+%Y-%m-%d %H:%M:%S')" \
    "${HTTPS_ENABLED:-false}" "${HTTPS_MODE:-}" \
    "${USER_DOMAIN:-}" "${ADMIN_DOMAIN:-}" \
    "${CERT_PROVIDER:-}" "${HTTPS_UPDATED_AT:-}" \
    "${API_PORT:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT:-}" \
    "${POSTGRES_DB_NAME:-}" "${POSTGRES_DB_USER:-}" "${API_DOMAIN:-}"

  success "二进制更新完成：${current_tag} → ${new_tag}"
}

do_update() {
  if ! load_deploy_state; then error "未找到部署记录，请先完成部署"; return 1; fi

  print_line
  info "正在检查最新版本..."
  local latest_api; latest_api="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  local current="${API_TAG:-}"
  local install_dir="${INSTALL_DIR:-}"
  local db_mode="${DB_MODE:-}"
  local mode="${MODE:-}"

  echo ""
  echo "  当前版本：${current:-未知}"
  echo "  最新版本：${latest_api:-未知}"
  echo ""

  if [[ -n "${latest_api}" && "${current}" == "${latest_api}" ]]; then
    success "已是最新版本，无需更新"; return 0
  fi

  local new_tag; new_tag="$(prompt_with_default "目标版本" "${latest_api:-${current}}")"
  [[ -z "${new_tag}" ]] && { warn "目标版本不能为空"; return 1; }

  case "${mode}" in
    docker)
      local compose_file env_file
      compose_file="$(docker_compose_file_from_db_mode "${install_dir}" "${db_mode}")"
      env_file="${install_dir}/.env"
      [[ ! -f "${env_file}" ]] && { error "未找到 .env 文件"; return 1; }
      sed -i "s/^TAG=.*/TAG=${new_tag}/" "${env_file}"
      info "正在拉取新镜像..."
      docker compose --env-file "${env_file}" -f "${compose_file}" pull
      info "正在重启服务..."
      docker compose --env-file "${env_file}" -f "${compose_file}" up -d
      write_state_file "docker" "${install_dir}" "${new_tag}" "${new_tag}" "${new_tag}" \
        "${db_mode}" "$(date '+%Y-%m-%d %H:%M:%S')" \
        "${HTTPS_ENABLED:-false}" "${HTTPS_MODE:-}" \
        "${USER_DOMAIN:-}" "${ADMIN_DOMAIN:-}" \
        "${CERT_PROVIDER:-}" "${HTTPS_UPDATED_AT:-}" \
        "${API_PORT:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT:-}" \
        "${POSTGRES_DB_NAME:-}" "${POSTGRES_DB_USER:-}"
      success "更新完成：${new_tag}"
      ;;
    external)
      local compose_file
      compose_file="${install_dir}/docker-compose.yml"
      [[ ! -f "${compose_file}" ]] && { error "未找到 docker-compose.yml"; return 1; }
      update_external_compose_tags "${compose_file}" "${new_tag}" || return 1
      info "正在拉取新镜像..."
      docker compose -f "${compose_file}" pull
      info "正在重启服务..."
      docker compose -f "${compose_file}" up -d
      write_state_file "external" "${install_dir}" "${new_tag}" "${new_tag}" "${new_tag}" \
        "${db_mode}" "$(date '+%Y-%m-%d %H:%M:%S')" \
        "${HTTPS_ENABLED:-false}" "${HTTPS_MODE:-}" \
        "${USER_DOMAIN:-}" "${ADMIN_DOMAIN:-}" \
        "${CERT_PROVIDER:-}" "${HTTPS_UPDATED_AT:-}" \
        "${API_PORT:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT:-}" \
        "${POSTGRES_DB_NAME:-}" "${POSTGRES_DB_USER:-}"
      success "更新完成：${new_tag}"
      ;;
    binary)
      update_binary "${install_dir}" "${current}" "${new_tag}"
      ;;
    *) error "未知部署模式" ;;
  esac
  print_author
}

# ══════════════════════════════════════════════════
# 日常管理
# ══════════════════════════════════════════════════
COMPOSE_CMD=()

prepare_compose_cmd() {
  if ! load_deploy_state; then error "未找到部署记录"; return 1; fi
  local install_dir="${INSTALL_DIR:-}"
  local mode="${MODE:-}"
  local db_mode="${DB_MODE:-}"
  local compose_file env_file

  if [[ "${mode}" == "external" ]]; then
    compose_file="${install_dir}/docker-compose.yml"
    COMPOSE_CMD=(docker compose -f "${compose_file}")
  elif [[ "${mode}" == "docker" ]]; then
    env_file="${install_dir}/.env"
    compose_file="$(docker_compose_file_from_db_mode "${install_dir}" "${db_mode}")"
    COMPOSE_CMD=(docker compose --env-file "${env_file}" -f "${compose_file}")
  else
    return 1
  fi
}

run_compose_cmd() {
  prepare_compose_cmd || return 1
  "${COMPOSE_CMD[@]}" "$@"
}

do_status() {
  if ! load_deploy_state; then error "未找到部署记录，请先完成部署"; return 1; fi
  print_line; echo "  ${BOLD}服务状态${NC}"; print_line
  if [[ "${MODE:-}" == "binary" ]]; then
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --no-pager --full status dujiao-next-api.service || true
    else
      warn "systemctl 不可用，无法显示二进制服务状态"
    fi
  else
    run_compose_cmd ps || { error "当前部署模式不支持 compose 状态查看"; return 1; }
  fi
  echo ""
  local api_port; api_port="$(get_saved_api_port)"
  if curl -sf "http://127.0.0.1:${api_port}/health" > /dev/null 2>&1; then
    success "API 健康检查通过"
  else
    warn "API 健康检查失败，服务可能仍在启动中"
  fi
  print_line
}

do_logs() {
  if ! load_deploy_state; then error "未找到部署记录，请先完成部署"; return 1; fi
  if [[ "${MODE:-}" == "binary" ]]; then
    if command -v journalctl >/dev/null 2>&1; then
      journalctl -u dujiao-next-api.service -f -n 100
    else
      warn "journalctl 不可用，无法查看二进制服务日志"
    fi
    return 0
  fi
  echo ""
  echo "  查看日志："
  echo "  1) API"
  echo "  2) User"
  echo "  3) Admin"
  echo "  4) 全部"
  printf '%s' "  请选择 [默认 4]: " >&2
  read -r choice
  choice="$(trim "${choice:-4}")"
  case "${choice}" in
    1) run_compose_cmd logs -f --tail 100 api ;;
    2) run_compose_cmd logs -f --tail 100 user ;;
    3) run_compose_cmd logs -f --tail 100 admin ;;
    *) run_compose_cmd logs -f --tail 100 ;;
  esac
}

do_restart() {
  if ! load_deploy_state; then error "未找到部署记录，请先完成部署"; return 1; fi
  if [[ "${MODE:-}" == "binary" ]]; then
    echo ""
    echo "  选择要重启的服务："
    echo "  1) API 服务"
    echo "  2) Nginx"
    echo "  3) 全部"
    printf '%s' "  请选择 [默认 3]: " >&2
    read -r choice
    choice="$(trim "${choice:-3}")"
    case "${choice}" in
      1) run_as_root systemctl restart dujiao-next-api.service; success "API 服务已重启" ;;
      2) run_as_root systemctl restart nginx; success "Nginx 已重启" ;;
      *) run_as_root systemctl restart dujiao-next-api.service && run_as_root systemctl restart nginx; success "所有服务已重启" ;;
    esac
    return 0
  fi
  echo ""
  echo "  选择要重启的服务："
  echo "  1) API"
  echo "  2) User"
  echo "  3) Admin"
  echo "  4) 全部"
  printf '%s' "  请选择 [默认 4]: " >&2
  read -r choice
  choice="$(trim "${choice:-4}")"
  case "${choice}" in
    1) run_compose_cmd restart api;   success "API 已重启" ;;
    2) run_compose_cmd restart user;  success "User 已重启" ;;
    3) run_compose_cmd restart admin; success "Admin 已重启" ;;
    *) run_compose_cmd restart;       success "所有服务已重启" ;;
  esac
}

do_backup() {
  if ! load_deploy_state; then error "未找到部署记录，请先完成部署"; return 1; fi
  local install_dir="${INSTALL_DIR:-}"
  local mode="${MODE:-}"
  local db_mode="${DB_MODE:-sqlite}"
  local backup_dir="${install_dir}/backups"
  local ts; ts="$(date '+%Y%m%d_%H%M%S')"
  mkdir -p "${backup_dir}"

  info "正在备份上传文件..."
  tar -czf "${backup_dir}/uploads_${ts}.tar.gz" -C "${install_dir}" data/uploads 2>/dev/null \
    || tar -czf "${backup_dir}/uploads_${ts}.tar.gz" -C "${install_dir}" uploads 2>/dev/null \
    || warn "未找到上传文件目录，已跳过"

  if [[ "${db_mode}" == "sqlite" ]]; then
    info "正在备份 SQLite 数据库..."
    find "${install_dir}" -name "*.db" -exec cp {} "${backup_dir}/dujiao_${ts}.db" \; 2>/dev/null || warn "未找到 SQLite 数据库文件"
  elif [[ "${db_mode}" == "postgres" ]]; then
    info "正在备份 PostgreSQL 数据库..."
    local pg_host="${POSTGRES_HOST:-postgres}"
    local pg_port="${POSTGRES_PORT:-5432}"
    local pg_db="${POSTGRES_DB_NAME:-dujiao_next}"
    local pg_user="${POSTGRES_DB_USER:-dujiao}"
    if [[ "${mode}" == "docker" ]]; then
      docker exec "${pg_host}" pg_dump -U "${pg_user}" "${pg_db}" > "${backup_dir}/postgres_${ts}.sql" 2>/dev/null \
        || warn "PostgreSQL 备份失败，请检查容器状态"
    else
      if ! command -v pg_dump >/dev/null 2>&1; then
        warn "pg_dump 不可用，无法备份外部 PostgreSQL"
      else
        local pg_password=""
        printf '%s' "  PostgreSQL 密码（留空则使用当前环境变量）: " >&2
        read -r pg_password
        if [[ -n "${pg_password}" ]]; then
          PGPASSWORD="${pg_password}" pg_dump -h "${pg_host}" -p "${pg_port}" -U "${pg_user}" "${pg_db}" > "${backup_dir}/postgres_${ts}.sql" \
            || warn "PostgreSQL 备份失败，请检查连接配置"
        else
          pg_dump -h "${pg_host}" -p "${pg_port}" -U "${pg_user}" "${pg_db}" > "${backup_dir}/postgres_${ts}.sql" \
            || warn "PostgreSQL 备份失败，请检查连接配置"
        fi
      fi
    fi
  fi

  success "备份完成：${backup_dir}"
  ls -lh "${backup_dir}/" | tail -5
}

do_clean_docker() {
  print_line; echo "  ${BOLD}🧹 清理 Docker 无用资源${NC}"; print_line
  echo ""
  echo "  将清理："
  echo "  • 已停止的容器"
  echo "  • 未使用的镜像"
  echo "  • 未使用的网络"
  echo "  • 构建缓存"
  echo ""
  if ask_yes_no "确认清理" "n"; then
    docker system prune -f
    success "清理完成"
    docker system df
  fi
}

do_uninstall() {
  if ! load_deploy_state; then error "未发现部署记录，请先部署"; return 1; fi
  local install_dir="${INSTALL_DIR:-}"
  local mode="${MODE:-}"
  echo ""
  warn "此操作将停止服务并删除安装目录，数据将无法恢复！"
  printf '  请输入 '"'"'YES'"'"' 确认卸载: ' >&2
  read -r confirm
  [[ "${confirm}" != "YES" ]] && { info "已取消卸载"; return 0; }

  case "${mode}" in
    docker|external)
      info "停止并删除容器..."
      run_compose_cmd down -v 2>/dev/null || true
      ;;
    binary)
      info "停止 systemd 服务..."
      systemctl stop dujiao-next-api.service 2>/dev/null || true
      systemctl disable dujiao-next-api.service 2>/dev/null || true
      rm -f /etc/systemd/system/dujiao-next-api.service
      systemctl daemon-reload 2>/dev/null || true
      success "systemd 服务已移除"
      ;;
  esac

  info "删除安装目录..."
  rm -rf "${install_dir}"

  info "删除状态文件..."
  rm -f "${STATE_FILE}"

  info "清理 Nginx 配置..."
  rm -f /etc/nginx/sites-available/dujiao-*.conf 2>/dev/null || true
  rm -f /etc/nginx/sites-enabled/dujiao-*.conf 2>/dev/null || true
  rm -f /etc/nginx/conf.d/dujiao-*.conf 2>/dev/null || true
  nginx -t >/dev/null 2>&1 && (systemctl reload nginx 2>/dev/null || nginx -s reload 2>/dev/null || true)

  success "卸载完成"
}

# ══════════════════════════════════════════════════
# 日常管理菜单  【FIX: 删除重复定义，保留唯一完整版本】
# ══════════════════════════════════════════════════
handle_ops_menu() {
  while true; do
    print_line
    echo "  ${BOLD}日常管理${NC}"
    print_line
    echo "  1) 查看服务状态"
    echo "  2) 查看日志"
    echo "  3) 重启服务"
    echo "  4) 备份数据库"
    echo "  5) 清理 Docker 资源"
    echo "  6) 卸载系统"
    echo "  0) 返回上级"
    print_line
    printf '%s' "  请选择 [0-6]: " >&2
    read -r choice
    choice="$(trim "${choice}")"
    case "${choice}" in
      1) do_status ;;
      2) do_logs ;;
      3) do_restart ;;
      4) do_backup ;;
      5) do_clean_docker ;;
      6) do_uninstall; return 0 ;;
      0) return 0 ;;
      *) warn "无效选项" ;;
    esac
  done
}

# ══════════════════════════════════════════════════
# 检查版本  【FIX: 重写此函数，移除混乱的中英文重复逻辑和裸露语句】
# ══════════════════════════════════════════════════
check_updates() {
  print_line
  info "检查最新版本..."
  print_line

  local latest_api latest_user latest_admin
  latest_api="$(fetch_latest_release_tag "${DUJIAO_API_REPO}")"
  latest_user="$(fetch_latest_release_tag "${DUJIAO_USER_REPO}")"
  latest_admin="$(fetch_latest_release_tag "${DUJIAO_ADMIN_REPO}")"

  if [[ -z "${latest_api}" && -z "${latest_user}" && -z "${latest_admin}" ]]; then
    error "获取最新版本失败，请检查网络"; return 1
  fi

  if load_deploy_state; then
    print_line
    echo "  部署模式 : ${MODE:-}"
    echo "  部署目录 : ${INSTALL_DIR:-}"
    echo "  数据库   : ${DB_MODE:-}"
    echo "  部署时间 : ${DEPLOYED_AT:-}"
    print_line
    printf '  %-8s 当前: %-20s 最新: %-20s\n' "API"   "${API_TAG:-N/A}"   "${latest_api:-N/A}"
    printf '  %-8s 当前: %-20s 最新: %-20s\n' "User"  "${USER_TAG:-N/A}"  "${latest_user:-N/A}"
    printf '  %-8s 当前: %-20s 最新: %-20s\n' "Admin" "${ADMIN_TAG:-N/A}" "${latest_admin:-N/A}"
    print_line
    echo "  HTTPS    : ${HTTPS_ENABLED:-false}"
    [[ "${HTTPS_ENABLED:-false}" == "true" ]] && echo "  User 域名: ${USER_DOMAIN:-} | Admin 域名: ${ADMIN_DOMAIN:-}"
  else
    warn "未发现本地部署记录，仅显示线上最新版本"
    print_line
    echo "  API   最新: ${latest_api:-N/A}"
    echo "  User  最新: ${latest_user:-N/A}"
    echo "  Admin 最新: ${latest_admin:-N/A}"
  fi
  print_line
}

# ══════════════════════════════════════════════════
# 系统安全加固
# ══════════════════════════════════════════════════
do_security_hardening() {
  print_line
  echo "  ${BOLD}系统安全加固${NC}"
  echo "  ${DIM}适用于 Debian/Ubuntu 系统${NC}"
  print_line
  echo ""
  warn "此操作会修改系统安全配置，建议在新服务器上执行。"
  if ! ask_yes_no "继续执行系统安全加固" "n"; then
    info "已取消"; return 0
  fi

  echo ""
  print_line
  echo "  ${BOLD}端口设置${NC}"
  print_line
  local ssh_port panel_port custom_ports
  ssh_port="$(prompt_with_default "SSH 端口（重要）" "22")"
  panel_port="$(prompt_with_default "面板端口（可选）" "")"
  custom_ports="$(prompt_with_default "额外开放端口（逗号分隔）" "")"
  if ! validate_port_number "${ssh_port}"; then
    error "SSH 端口无效: ${ssh_port}"
    return 1
  fi

  echo ""
  info "开始执行加固任务..."

  info "检查并安装 Lynis..."
  if ! command_exists lynis; then
    DEBIAN_FRONTEND=noninteractive apt-get update -y -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y lynis
  fi
  success "Lynis 已就绪: $(lynis --version 2>&1 | head -n1)"

  info "更新系统软件包..."
  DEBIAN_FRONTEND=noninteractive apt-get update -y -qq
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"

  info "启用自动安全更新..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades -qq
  cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
  cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
  systemctl enable unattended-upgrades 2>/dev/null || true
  systemctl start unattended-upgrades 2>/dev/null || true
  success "自动安全更新已启用"

  DEBIAN_FRONTEND=noninteractive apt-get install -y libpam-tmpdir -qq
  success "libpam-tmpdir 已安装"

  info "加固 SSH..."
  local SSHD=/etc/ssh/sshd_config
  local sshd_backup="${SSHD}.bak"
  backup_file "${SSHD}"
  set_config_kv "${SSHD}" "PermitRootLogin" "prohibit-password"
  set_config_kv "${SSHD}" "PermitEmptyPasswords" "no"
  set_config_kv "${SSHD}" "MaxAuthTries" "3"
  set_config_kv "${SSHD}" "LoginGraceTime" "20"
  set_config_kv "${SSHD}" "X11Forwarding" "no"
  set_config_kv "${SSHD}" "AllowTcpForwarding" "no"
  set_config_kv "${SSHD}" "AllowAgentForwarding" "no"
  set_config_kv "${SSHD}" "Compression" "no"
  set_config_kv "${SSHD}" "LogLevel" "VERBOSE"
  set_config_kv "${SSHD}" "MaxSessions" "2"
  set_config_kv "${SSHD}" "TCPKeepAlive" "no"
  set_config_kv "${SSHD}" "ClientAliveInterval" "300"
  set_config_kv "${SSHD}" "ClientAliveCountMax" "2"
  set_config_kv "${SSHD}" "Port" "${ssh_port}"
  if ! test_sshd_config "${SSHD}"; then
    [[ -f "${sshd_backup}" ]] && cp -f "${sshd_backup}" "${SSHD}"
    error "sshd_config 校验失败，已回滚 SSH 配置"
    return 1
  fi
  if ! restart_ssh_service; then
    [[ -f "${sshd_backup}" ]] && cp -f "${sshd_backup}" "${SSHD}"
    restart_ssh_service || true
    error "SSH 重启失败，已回滚到原配置"
    return 1
  fi
  success "SSH 加固完成（端口: ${ssh_port}）"

  info "配置 rsyslog..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y rsyslog logrotate -qq
  sed -i 's/\$FileCreateMode.*/\$FileCreateMode 0640/' /etc/rsyslog.conf 2>/dev/null || true
  systemctl restart rsyslog 2>/dev/null || true
  success "rsyslog 配置完成"

  info "应用内核安全参数..."
  cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
kernel.kptr_restrict = 2
fs.suid_dumpable = 0
kernel.randomize_va_space = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
EOF
  sysctl --system > /dev/null 2>&1
  success "内核安全参数已应用"

  info "修复文件权限..."
  chmod 700 /root
  chmod 600 /etc/shadow 2>/dev/null || true
  chmod 600 /etc/gshadow 2>/dev/null || true
  chmod 600 /etc/crontab 2>/dev/null || true
  chmod 700 /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly 2>/dev/null || true
  success "文件权限已更新"

  info "安装并配置 Fail2ban..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban -qq
  cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ${ssh_port}
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
EOF
  systemctl enable fail2ban 2>/dev/null || true
  systemctl restart fail2ban 2>/dev/null || true
  success "Fail2ban 配置完成"

  info "配置 UFW 防火墙..."
  local ufw_after_rules=/etc/ufw/after.rules
  local ufw_after_rules_backup="${ufw_after_rules}.bak"
  local ufw_was_active="false"
  DEBIAN_FRONTEND=noninteractive apt-get install -y ufw -qq
  backup_file "${ufw_after_rules}"
  [[ -f "${ufw_after_rules_backup}" ]] || : > "${ufw_after_rules_backup}"
  if ufw status 2>/dev/null | grep -q '^Status: active'; then
    ufw_was_active="true"
  fi
  write_ufw_after_rules "${ufw_after_rules}"
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 80/tcp comment 'HTTP'
  ufw allow 443/tcp comment 'HTTPS'
  ufw allow "${ssh_port}/tcp" comment 'SSH'
  [[ -n "${panel_port}" ]] && ufw allow "${panel_port}/tcp" comment 'Panel'
  if [[ -n "${custom_ports}" ]]; then
    IFS=',' read -ra ports <<< "${custom_ports}"
    for p in "${ports[@]}"; do
      p="$(trim "${p}")"
      [[ -n "${p}" ]] && ufw allow "${p}/tcp" comment 'Custom'
    done
  fi
  if [[ "${ufw_was_active}" == "true" ]]; then
    ufw reload >/dev/null 2>&1 || {
      [[ -f "${ufw_after_rules_backup}" ]] && cp -f "${ufw_after_rules_backup}" "${ufw_after_rules}"
      error "UFW 重新加载失败，已回滚 after.rules"
      return 1
    }
  else
    echo "y" | ufw enable >/dev/null 2>&1 || {
      [[ -f "${ufw_after_rules_backup}" ]] && cp -f "${ufw_after_rules_backup}" "${ufw_after_rules}"
      ufw --force disable >/dev/null 2>&1 || true
      error "UFW 启用失败，已回滚 after.rules"
      return 1
    }
  fi
  success "UFW 防火墙配置完成"
  ufw status numbered

  info "应用附加安全加固..."
  cat > /etc/modprobe.d/disable-protocols.conf << 'EOF'
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF
  cat > /etc/modprobe.d/disable-usb-storage.conf << 'EOF'
install usb-storage /bin/true
EOF
  sed -i 's/UMASK.*/UMASK 027/' /etc/login.defs 2>/dev/null || true
  grep -q "^UMASK" /etc/login.defs || echo "UMASK 027" >> /etc/login.defs
  sed -i 's/PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs 2>/dev/null || true
  sed -i 's/PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs 2>/dev/null || true
  sed -i 's/PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs 2>/dev/null || true
  grep -q "^SHA_CRYPT_MIN_ROUNDS" /etc/login.defs || {
    echo "SHA_CRYPT_MIN_ROUNDS 5000" >> /etc/login.defs
    echo "SHA_CRYPT_MAX_ROUNDS 5000" >> /etc/login.defs
  }
  grep -q "^\* hard core 0" /etc/security/limits.conf || echo "* hard core 0" >> /etc/security/limits.conf
  cat > /etc/issue << 'EOF'
**********************************************************************
*  Authorized access only!                                           *
*  All actions are logged and monitored.                             *
**********************************************************************
EOF
  cp /etc/issue /etc/issue.net
  grep -q "^auth required pam_wheel.so" /etc/pam.d/su || echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
  success "附加安全加固已完成"

  info "配置密码策略..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y libpam-pwquality debsums apt-show-versions -qq
  cat > /etc/security/pwquality.conf << 'EOF'
minlen = 12
lcredit = -1
ucredit = -1
dcredit = -1
ocredit = -1
maxrepeat = 3
difok = 5
EOF
  success "密码策略已配置"

  echo ""
  print_line
  echo "  ${G}${BOLD}系统安全加固完成${NC}"
  print_line
  echo "  - 已启用自动安全更新"
  echo "  - 已完成 SSH 加固（端口: ${ssh_port}）"
  echo "  - 已配置 Fail2ban"
  echo "  - 已配置 UFW 防火墙"
  echo "  - 已应用内核/文件/密码策略加固"
  echo ""
  echo "  ${Y}请重启服务器以确保所有配置生效：reboot${NC}"
  echo "  ${Y}重启后请使用 SSH 端口 ${ssh_port} 重新连接${NC}"
  print_author
}

# ══════════════════════════════════════════════════
# 部署菜单
# ══════════════════════════════════════════════════
handle_deploy_menu() {
  while true; do
    print_line
    echo "  ${BOLD}开始部署${NC}"
    print_line
    echo "  1) Docker 部署（推荐）"
    echo "  2) 二进制部署"
    echo "  3) 外部环境部署"
    echo "  0) 返回"
    print_line
    printf '%s' "  请选择 [0-3]: " >&2
    read -r choice
    choice="$(trim "${choice}")"
    case "${choice}" in
      1) deploy_with_docker; return 0 ;;
      2) deploy_with_binary; return 0 ;;
      3) deploy_external;    return 0 ;;
      0) return 0 ;;
      *) warn "无效选项" ;;
    esac
  done
}

show_main_menu() {
  print_line
  echo "  ${BOLD}独角 Next 运维脚本${NC}  ${DIM}作者: LangGe  Telegram: @luoyanglang${NC}"
  print_line
  echo "  1) 开始部署"
  echo "  2) 一键更新"
  echo "  3) 配置 HTTPS"
  echo "  4) 日常管理"
  echo "  5) 检查版本"
  echo "  6) 系统加固"
  echo "  0) 退出"
  print_line
}

main() {
  if [[ "$(id -u)" -ne 0 ]]; then
    printf "${R}[ERROR]${NC} 请使用 root 权限运行此脚本\n"
    exit 1
  fi
  ensure_command curl

  print_banner

  while true; do
    show_main_menu
    printf '%s' "  请选择 [0-6]: " >&2
    read -r choice
    choice="$(trim "${choice}")"
    case "${choice}" in
      1) handle_deploy_menu ;;
      2) do_update ;;
      3) configure_https ;;
      4) handle_ops_menu ;;
      5) check_updates ;;
      6) do_security_hardening ;;
      0) echo "  再见"; exit 0 ;;
      *) warn "无效选项: ${choice}" ;;
    esac
  done
}

main "$@"
