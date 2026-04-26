#!/bin/bash

# 启动脚本 for GitHub Codespace Desktop
# 同时支持 VNC (5900) 和 RDP (3389) 连接

set -e

echo "========================================"
echo "  GitHub Codespace Desktop 启动脚本"
echo "========================================"

# 1. 启动 Tailscale
echo "[1/5] 启动 Tailscale..."
sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
sleep 3

if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
    sudo tailscale up --authkey="${TAILSCALE_AUTHKEY}" 2>/dev/null || echo "Tailscale 可能已登录或认证失败"
else
    echo "注意: 未设置 TAILSCALE_AUTHKEY，请手动运行 'sudo tailscale up' 登录"
fi

# 2. 清理可能存在的旧会话文件
echo "[2/5] 清理旧的会话文件..."
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# 3. 启动 TigerVNC 服务器
echo "[3/5] 启动 TigerVNC 服务器 (端口: 5900)..."
vncserver -kill :1 2>/dev/null || true
vncserver :1 -xstartup 'cinnamon-session' -geometry 1280x720 -depth 24 -rfbport 5900 -rfbauth ~/.vnc/passwd

# 4. 配置并启动 noVNC
echo "[4/5] 启动 noVNC Web 代理 (端口: 6080)..."
# 查找 noVNC 目录
NOVNC_PATH=""
for path in "$HOME/noVNC" "/workspaces/noVNC" "/home/*/noVNC"; do
    if [ -f "$path/utils/novnc_proxy" ]; then
        NOVNC_PATH="$path"
        break
    fi
done

if [ -z "$NOVNC_PATH" ]; then
    echo "警告: 未找到 noVNC，尝试在当前目录查找..."
    if [ -f "./noVNC/utils/novnc_proxy" ]; then
        NOVNC_PATH="./noVNC"
    fi
fi

if [ -n "$NOVNC_PATH" ]; then
    echo "使用 noVNC 路径: $NOVNC_PATH"
    "$NOVNC_PATH/utils/novnc_proxy" --vnc 127.0.0.1:5900 --listen localhost:6080 &
else
    echo "错误: 无法找到 noVNC，Web VNC 将无法使用"
fi

# 5. 配置并启动 xrdp (RDP)
echo "[5/5] 启动 xrdp RDP 服务器 (端口: 3389)..."

# 清理旧的 xrdp PID 文件
sudo rm -f /var/run/xrdp/xrdp-sesman.pid /var/run/xrdp/xrdp.pid 2>/dev/null || true

# 配置 xrdp 使用 Xvnc 连接到 TigerVNC
# 创建 xrdp 启动脚本
sudo tee /etc/xrdp/startwm.sh > /dev/null << 'EOF'
#!/bin/bash
# xrdp 会话启动脚本 - 直接连接到现有的 TigerVNC 会话
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
cinnamon-session
EOF

sudo chmod +x /etc/xrdp/startwm.sh

# 配置 xrdp.ini 使用 Xvnc 后端
sudo tee /etc/xrdp/xrdp.ini > /dev/null << 'EOF'
[Globals]
ini_version=1
fork=true
port=3389
ssl_protocols=TLSv1.2, TLSv1.3
crypt_level=high
max_bpp=24
xserverbpp=24
security_layer=negotiate
allow_channels=true
allow_multimon=true
bitmap_cache=true
bitmap_compression=true
bulk_compression=true
max_bpp=32
new_cursors=true
use_fastpath=both
tcp_keepalive=true
tcp_nodelay=true

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

; 默认使用 Xvnc 会话 - 连接到 TigerVNC
[Xvnc]
name=Xvnc
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=5900
; 关闭 xrdp 的 Xvnc 自动启动，只作为代理
code=20

; 可选的 Xorg 会话
[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
xserverbpp=24
dept=24
EOF

# 启动 xrdp 服务
sudo xrdp-sesman &
sleep 1
sudo xrdp --nodaemon &

echo ""
echo "========================================"
echo "  所有服务已启动！"
echo "========================================"
echo ""
echo "连接方式:"
echo "  • VNC 客户端:  通过 Tailscale IP 连接端口 5900"
echo "  • Web 浏览器:  访问转发的 6080 端口 -> /vnc.html"
echo "  • RDP 客户端:  通过 Tailscale IP 连接端口 3389 (用户: root/vscode, 密码: VNC密码)"
echo ""
echo "保持运行中... (按 Ctrl+C 停止)"

# 保持脚本运行
wait
