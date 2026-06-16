#!/bin/bash
# Cloud Shell Desktop —— 容器内服务启动脚本
# 在容器内拉起 VNC(:1) -> noVNC -> xrdp(libvnc 接 5900) -> sshd，并保持运行。
# Tailscale 由独立容器负责（与本容器共享 host 网络命名空间）。
set -e

# ---------- 可调参数（由 docker run -e 传入，带默认值）----------
RESOLUTION="${RESOLUTION:-1280x720}"
DEPTH="${DEPTH:-16}"                 # 16 位色深，相比 24 位省约 1/3 带宽
VNC_PASS="${VNC_PASS:-password}"     # VNC / RDP 密码
ROOT_PASS="${ROOT_PASS:-codespace}"  # SSH root 密码
# 持久化目录：本容器的 /root 已由宿主 $HOME 挂载进来
PERSIST_DIR="/root/.gcs"
SSH_KEY_DIR="$PERSIST_DIR/ssh"

echo "========================================"
echo "  Cloud Shell Desktop 启动中"
echo "  分辨率: ${RESOLUTION}  色深: ${DEPTH}bit"
echo "========================================"

mkdir -p "$PERSIST_DIR" "$SSH_KEY_DIR" /var/run/sshd /run/dbus

# ---------- 1. SSH：持久化主机密钥 + root 密码 ----------
echo "[1/5] 配置 SSH..."
echo "root:${ROOT_PASS}" | chpasswd
# 主机密钥放在持久化目录，避免每次会话指纹变化导致客户端告警
if [ ! -f "$SSH_KEY_DIR/ssh_host_ed25519_key" ]; then
    echo "  首次生成 SSH 主机密钥（持久化到 $SSH_KEY_DIR）..."
    ssh-keygen -q -t rsa     -f "$SSH_KEY_DIR/ssh_host_rsa_key"     -N "" || true
    ssh-keygen -q -t ecdsa   -f "$SSH_KEY_DIR/ssh_host_ecdsa_key"   -N "" || true
    ssh-keygen -q -t ed25519 -f "$SSH_KEY_DIR/ssh_host_ed25519_key" -N "" || true
fi
chmod 600 "$SSH_KEY_DIR"/ssh_host_*_key
# 让 sshd 使用持久化主机密钥
sed -i '/^HostKey \/etc\/ssh/d' /etc/ssh/sshd_config
{
    echo "HostKey $SSH_KEY_DIR/ssh_host_rsa_key"
    echo "HostKey $SSH_KEY_DIR/ssh_host_ecdsa_key"
    echo "HostKey $SSH_KEY_DIR/ssh_host_ed25519_key"
} >> /etc/ssh/sshd_config

# ---------- 2. VNC 密码 ----------
echo "[2/5] 配置 VNC 密码..."
mkdir -p /root/.vnc
printf '%s\n' "$VNC_PASS" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# 桌面会话脚本（VNC 与 RDP 共用 xfce4）
cat > /root/.vnc/xstartup << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
[ -x /usr/bin/dbus-launch ] && eval "$(dbus-launch --sh-syntax)"
exec startxfce4
EOF
chmod +x /root/.vnc/xstartup

# 清理可能残留的旧 X 锁
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
vncserver -kill :1 2>/dev/null || true

# ---------- 3. 启动 Xvnc (:1 -> 5900) ----------
echo "[3/5] 启动 TigerVNC (端口 5900, ${RESOLUTION}, ${DEPTH}bit)..."
vncserver :1 \
    -geometry "$RESOLUTION" \
    -depth "$DEPTH" \
    -rfbport 5900 \
    -rfbauth /root/.vnc/passwd \
    -localhost no \
    -alwaysshared \
    -xstartup /root/.vnc/xstartup
sleep 2

# ---------- 4. noVNC (Web VNC, 6080) ----------
echo "[4/5] 启动 noVNC Web 代理 (端口 6080)..."
NOVNC_PROXY=""
for p in /usr/share/novnc/utils/novnc_proxy /usr/bin/novnc_proxy /usr/share/novnc/utils/launch.sh; do
    [ -x "$p" ] && { NOVNC_PROXY="$p"; break; }
done
if [ -n "$NOVNC_PROXY" ]; then
    # 提供一个跳转到 vnc.html 的默认首页
    [ -f /usr/share/novnc/index.html ] || \
        ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html 2>/dev/null || true
    "$NOVNC_PROXY" --vnc 127.0.0.1:5900 --listen 6080 --web /usr/share/novnc &
else
    echo "  警告: 未找到 novnc_proxy，Web VNC 不可用"
fi

# ---------- 5. xrdp (RDP 3389, libvnc 接到 5900) ----------
echo "[5/5] 启动 xrdp RDP 服务 (端口 3389)..."
mkdir -p /var/run/xrdp
rm -f /var/run/xrdp/xrdp-sesman.pid /var/run/xrdp/xrdp.pid 2>/dev/null || true

# xrdp.ini：仅暴露 libvnc 会话，直连本机 Xvnc:5900（与 Codespaces 版思路一致）
cat > /etc/xrdp/xrdp.ini << EOF
[Globals]
ini_version=1
fork=true
port=3389
ssl_protocols=TLSv1.2, TLSv1.3
crypt_level=high
security_layer=negotiate
max_bpp=24
xserverbpp=24
new_cursors=true
use_fastpath=both
tcp_nodelay=true
tcp_keepalive=true

[Logging]
LogFile=/var/log/xrdp.log
LogLevel=INFO
EnableSyslog=true

[Channels]
rdpdr=true
rdpsnd=true
drdynvc=true
cliprdr=true
rail=true

; 直接连接到本机 TigerVNC (${RESOLUTION})
[Xvnc-VNC]
name=Cloud Shell Desktop (VNC)
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=5900
code=20
EOF

xrdp-sesman --kill 2>/dev/null || true
sleep 1
xrdp-sesman
sleep 1
xrdp

# ---------- SSH 启动 ----------
/usr/sbin/sshd
sleep 1

echo ""
echo "========================================"
echo "  所有服务已启动"
echo "========================================"
echo "  • SSH:     ssh root@<Tailscale-IP>          (密码: ${ROOT_PASS})"
echo "  • mosh:    mosh --ssh=\"ssh -p 22\" root@<Tailscale-IP>  (慢链路推荐)"
echo "  • VNC:     <Tailscale-IP>:5900               (密码: ${VNC_PASS})"
echo "  • RDP:     <Tailscale-IP>:3389  用户 root    (密码: ${VNC_PASS})"
echo "  • Web VNC: http://<Tailscale-IP>:6080/vnc.html"
echo "========================================"

# 保持容器运行并监控关键进程
while true; do
    sleep 30
    pgrep -f Xtigervnc >/dev/null 2>&1 || echo "警告: VNC(Xtigervnc) 已停止"
    pgrep -x xrdp      >/dev/null 2>&1 || echo "警告: xrdp 已停止"
    pgrep -x sshd      >/dev/null 2>&1 || { echo "sshd 已停止，重启..."; /usr/sbin/sshd; }
done
