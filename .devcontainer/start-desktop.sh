#!/bin/bash

# 启动脚本 for GitHub Codespace Desktop
# 支持 SSH (22)、VNC (5900)、RDP (3389) 和 Web VNC (6080)

set -e

# 默认分辨率设置
DEFAULT_WIDTH=1280
DEFAULT_HEIGHT=720
GEOMETRY="${DEFAULT_WIDTH}x${DEFAULT_HEIGHT}"

echo "========================================"
echo "  GitHub Codespace Desktop 启动脚本"
echo "  分辨率: ${GEOMETRY}"
echo "========================================"

# 1. 启动 Tailscale
echo "[1/6] 启动 Tailscale..."
sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 \
    --state=/var/lib/tailscale/tailscaled.state &
sleep 3

if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
    echo "  使用 AuthKey 登录 Tailscale..."
    sudo tailscale up --authkey="${TAILSCALE_AUTHKEY}" --accept-routes --accept-dns=false 2>/dev/null || echo "  Tailscale 可能已登录或认证失败，尝试手动登录..."
else
    echo "  注意: 未设置 TAILSCALE_AUTHKEY，请手动运行 'sudo tailscale up' 登录"
fi

# 显示Tailscale状态
echo "  Tailscale IP 地址:"
sudo tailscale ip -4 2>/dev/null || echo "    (未获取到IP，可能尚未登录)"

# 2. 清理可能存在的旧会话文件
echo "[2/6] 清理旧的会话文件..."
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true
rm -f /tmp/.X2-lock /tmp/.X11-unix/X2 2>/dev/null || true
rm -f /tmp/.X3-lock /tmp/.X11-unix/X3 2>/dev/null || true

# 3. 启动 TigerVNC 服务器 - 使用固定1280x720分辨率
echo "[3/6] 启动 TigerVNC 服务器 (端口: 5900, 分辨率: ${GEOMETRY})..."
vncserver -kill :1 2>/dev/null || true
sleep 1

# VNC 配置优化 - 针对慢链路/中继场景
# 16 位色深相比 24 位可省约 1/3 带宽，交互体感更顺
mkdir -p ~/.vnc
cat > ~/.vnc/config << EOF
geometry=${GEOMETRY}
depth=16
rfbport=5900
localhost=no
alwaysshared
EOF

# 启动VNC服务器（16 位色深）
vncserver :1 -xstartup 'cinnamon-session' -geometry ${GEOMETRY} -depth 16 -rfbport 5900 -rfbauth ~/.vnc/passwd -alwaysshared &
sleep 2

# 4. 配置并启动 noVNC
echo "[4/6] 启动 noVNC Web 代理 (端口: 6080)..."
# 查找 noVNC 目录
NOVNC_PATH=""
for path in "$HOME/noVNC" "/workspaces/noVNC" "/home/*/noVNC"; do
    if [ -f "$path/utils/novnc_proxy" ]; then
        NOVNC_PATH="$path"
        break
    fi
done

if [ -z "$NOVNC_PATH" ]; then
    echo "  警告: 未找到 noVNC，尝试在当前目录查找..."
    if [ -f "./noVNC/utils/novnc_proxy" ]; then
        NOVNC_PATH="./noVNC"
    fi
fi

if [ -n "$NOVNC_PATH" ]; then
    echo "  使用 noVNC 路径: $NOVNC_PATH"
    # 启动 noVNC 并优化WebSocket参数
    "$NOVNC_PATH/utils/novnc_proxy" --vnc 127.0.0.1:5900 --listen localhost:6080 --web "$NOVNC_PATH" &
else
    echo "  错误: 无法找到 noVNC，Web VNC 将无法使用"
fi

# 5. 配置并启动 xrdp (RDP) - 固定1280x720分辨率
echo "[5/6] 启动 xrdp RDP 服务器 (端口: 3389, 分辨率: ${GEOMETRY})..."

# 清理旧的 xrdp PID 文件
sudo rm -f /var/run/xrdp/xrdp-sesman.pid /var/run/xrdp/xrdp.pid 2>/dev/null || true
sudo rm -f /var/run/xrdp-sesman.pid /var/run/xrdp.pid 2>/dev/null || true

# 确保 xrdp 运行目录存在
sudo mkdir -p /var/run/xrdp
sudo chown xrdp:xrdp /var/run/xrdp 2>/dev/null || true

# 配置 xrdp 启动脚本
sudo tee /etc/xrdp/startwm.sh > /dev/null << 'EOF'
#!/bin/bash
# xrdp 会话启动脚本
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
export DISPLAY=:1
exec cinnamon-session
EOF
sudo chmod +x /etc/xrdp/startwm.sh

# 配置分辨率环境变量
sudo tee /etc/xrdp/xrdp-session-env.txt > /dev/null << EOF
GEOMETRY=${GEOMETRY}
RES_WIDTH=${DEFAULT_WIDTH}
RES_HEIGHT=${DEFAULT_HEIGHT}
EOF

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

; Xvnc 会话 - 连接到 TigerVNC (1280x720)
[Xvnc]
name=Xvnc (1280x720)
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=5900
code=20

; Xorg 会话 (备用)
[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
xserverbpp=24
depth=24
EOF

# 启动 xrdp 服务
sudo xrdp-sesman --kill 2>/dev/null || true
sleep 1
sudo xrdp-sesman &
sleep 2
sudo xrdp --nodaemon &

# 6. 启动 SSH 服务器
echo "[6/6] 启动 SSH 服务器 (端口: 22)..."
sudo mkdir -p /var/run/sshd
# 生成主机密钥（如果不存在）
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "  生成 SSH 主机密钥..."
    sudo ssh-keygen -A
fi
# 设置 root 密码（如果未设置）
echo 'root:codespace' | sudo chpasswd 2>/dev/null || true
# 启动SSH服务
sudo /usr/sbin/sshd
sleep 1

# 验证SSH端口
if nc -z localhost 22 2>/dev/null || netstat -tlnp 2>/dev/null | grep -q ':22'; then
    echo "  SSH 服务已启动成功"
else
    echo "  警告: SSH 服务可能未正常启动"
fi

echo ""
echo "========================================"
echo "  所有服务已启动！"
echo "========================================"
echo ""
echo "连接方式:"
echo "  • SSH 连接:    ssh root@<Tailscale-IP>  (密码: codespace)"
echo "  • mosh 连接:   mosh --ssh=\"ssh -p 22\" root@<Tailscale-IP>  (慢链路推荐，本地预测回显)"
echo "  • VNC 客户端:  <Tailscale-IP>:5900  (密码: password)"
echo "  • Web VNC:     访问转发的 6080 端口 -> /vnc.html"
echo "  • RDP 客户端:  <Tailscale-IP>:3389 (用户: root, 密码: password)"
echo ""
echo "性能相关:"
echo "  • VNC 色深: 16 位 (相比 24 位省约 1/3 带宽)"
echo "  • 分辨率固定: ${GEOMETRY}"
echo "  • SSH 卡顿请优先用 mosh; VNC 客户端建议设 Tight 编码 + JPEG 质量 4~6"
echo ""
echo "保持运行中... (按 Ctrl+C 停止)"

# 保持脚本运行，监控关键进程
while true; do
    sleep 30
    # 检查关键进程是否还在运行
    if ! pgrep -x "vncserver" > /dev/null && ! pgrep -f "Xtigervnc" > /dev/null; then
        echo "警告: VNC 服务器已停止"
    fi
    if ! pgrep -x "xrdp" > /dev/null; then
        echo "警告: XRDP 服务器已停止"
    fi
done
