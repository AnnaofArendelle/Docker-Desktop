#!/bin/bash
# =============================================================================
#  可选扩展：Cloudflare WARP 出口代理 (egress via Cloudflare clean-ish IP)
# =============================================================================
#  作用：让指定应用(默认 firefox)的出站流量经 Cloudflare WARP 出网，
#        出口 IP 变为 Cloudflare 的共享 VPN IP，而非 Codespace 数据中心 IP。
#
#  设计原则：
#    - 默认关闭，对现有功能零侵入。仅当环境变量 ENABLE_WARP=true 时才启用。
#    - 采用 proxy 模式(本地 SOCKS5)，不需要 TUN 设备，与 Tailscale 的
#      userspace-networking 互不冲突(Tailscale SOCKS 在 :1055 负责入站，
#      WARP SOCKS 在 :40000 负责指定应用出站)。
#    - 幂等：可重复执行，不会重复安装或报错。
#
#  用法：
#    warp.sh up       安装(首次)、启动 warp-svc、注册、连接，并打印出口 IP
#    warp.sh down     断开 WARP 并停止守护进程(不卸载)
#    warp.sh status   查看连接状态与当前出口 IP
#
#  相关环境变量(均经 Codespaces Secrets 注入，可选)：
#    ENABLE_WARP    = true 时，start-desktop.sh 才会调用本脚本的 up
#    WARP_LICENSE   = WARP+ / Zero Trust 的 license key(可选，留空用免费版)
#    WARP_PROXY_PORT= 本地 SOCKS5 端口(可选，默认 40000)
# =============================================================================

set -uo pipefail

PROXY_PORT="${WARP_PROXY_PORT:-40000}"
SOCKS_ADDR="socks5://127.0.0.1:${PROXY_PORT}"

log() { echo "  [WARP] $*"; }

# ----------------------------------------------------------------------------
# 安装 cloudflare-warp(幂等：已装则跳过)
# ----------------------------------------------------------------------------
warp_install() {
    if command -v warp-cli >/dev/null 2>&1; then
        log "warp-cli 已安装，跳过安装步骤"
        return 0
    fi

    log "安装 cloudflare-warp..."
    local codename
    codename="$(lsb_release -cs 2>/dev/null || echo jammy)"

    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
        | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ ${codename} main" \
        | sudo tee /etc/apt/sources.list.d/cloudflare-client.list >/dev/null

    sudo apt-get update -qq
    if ! sudo apt-get install -y cloudflare-warp; then
        log "错误：cloudflare-warp 安装失败(该发行版代号 ${codename} 可能无对应仓库)"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# 确保守护进程 warp-svc 在运行
# Codespaces 容器通常无 systemd 作为 init，systemctl 多半不可用，
# 因此直接后台拉起 warp-svc。
# ----------------------------------------------------------------------------
warp_start_daemon() {
    if pgrep -x warp-svc >/dev/null 2>&1; then
        log "warp-svc 守护进程已在运行"
        return 0
    fi
    log "启动 warp-svc 守护进程..."
    sudo sh -c 'nohup warp-svc >/var/log/warp-svc.log 2>&1 &'
    # 等待守护进程就绪(最多 ~10s)
    for _ in $(seq 1 20); do
        if warp-cli --accept-tos status >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.5
    done
    log "警告：warp-svc 可能未就绪，继续尝试..."
}

# ----------------------------------------------------------------------------
# 注册 + 配置 proxy 模式 + 连接(全部幂等)
# ----------------------------------------------------------------------------
warp_connect() {
    local wc="warp-cli --accept-tos"

    # 注册(已注册会报错，吞掉即可)
    if ! $wc registration show >/dev/null 2>&1; then
        log "注册新设备..."
        $wc registration new >/dev/null 2>&1 || log "注册可能已存在，继续"
    fi

    # 可选：WARP+ / Zero Trust license
    if [ -n "${WARP_LICENSE:-}" ]; then
        log "应用 WARP+ license..."
        $wc registration license "${WARP_LICENSE}" >/dev/null 2>&1 || log "license 应用失败(忽略)"
    fi

    # 切到 proxy 模式 + 设端口(不需要 TUN)
    log "配置 proxy 模式，SOCKS5 端口 ${PROXY_PORT}..."
    $wc mode proxy >/dev/null 2>&1 || true
    $wc proxy port "${PROXY_PORT}" >/dev/null 2>&1 || true

    # 连接
    log "连接 WARP..."
    $wc connect >/dev/null 2>&1 || true
    sleep 2
}

# ----------------------------------------------------------------------------
# 打印当前(经 WARP 的)出口 IP，用于自检
# ----------------------------------------------------------------------------
warp_show_egress() {
    local ip
    ip="$(curl -fsS --max-time 10 --socks5-hostname "127.0.0.1:${PROXY_PORT}" https://api.ipify.org 2>/dev/null)"
    if [ -n "$ip" ]; then
        log "WARP 出口 IP: ${ip}  (应用请将代理指向 ${SOCKS_ADDR})"
    else
        log "警告：无法通过 ${SOCKS_ADDR} 获取出口 IP，WARP 可能未连接成功"
    fi
}

# ----------------------------------------------------------------------------
# 让 firefox 默认走 WARP 代理(企业策略，对用户零感知)
# 通过 policies.json 配置；开关关闭时会移除该策略，避免 firefox 连不存在的代理。
# ----------------------------------------------------------------------------
FIREFOX_POLICY_DIRS="/usr/lib/firefox/distribution /usr/lib/firefox-esr/distribution /etc/firefox/policies"

firefox_proxy_on() {
    local content
    content=$(cat <<EOF
{
  "policies": {
    "Proxy": {
      "Mode": "manual",
      "SOCKSProxy": "127.0.0.1:${PROXY_PORT}",
      "SOCKSVersion": 5,
      "UseProxyForDNS": true,
      "Locked": false
    }
  }
}
EOF
)
    for d in $FIREFOX_POLICY_DIRS; do
        sudo mkdir -p "$d" 2>/dev/null || continue
        echo "$content" | sudo tee "$d/policies.json" >/dev/null 2>&1 || true
    done
    log "已配置 firefox 默认经 WARP 出网"
}

firefox_proxy_off() {
    for d in $FIREFOX_POLICY_DIRS; do
        sudo rm -f "$d/policies.json" 2>/dev/null || true
    done
}

# ----------------------------------------------------------------------------
# 子命令
# ----------------------------------------------------------------------------
warp_up() {
    warp_install || return 1
    warp_start_daemon
    warp_connect
    warp_show_egress
    firefox_proxy_on
    log "已启用。SOCKS5 代理: ${SOCKS_ADDR}"
}

warp_down() {
    firefox_proxy_off
    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli --accept-tos disconnect >/dev/null 2>&1 || true
        log "已断开 WARP"
    fi
    if pgrep -x warp-svc >/dev/null 2>&1; then
        sudo pkill -x warp-svc 2>/dev/null || true
        log "已停止 warp-svc"
    fi
}

warp_status() {
    if ! command -v warp-cli >/dev/null 2>&1; then
        log "warp-cli 未安装"
        return 0
    fi
    warp-cli --accept-tos status 2>/dev/null || true
    warp_show_egress
}

case "${1:-up}" in
    up)     warp_up ;;
    down)   warp_down ;;
    status) warp_status ;;
    *)      echo "用法: $0 {up|down|status}"; exit 1 ;;
esac
