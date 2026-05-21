#!/bin/sh

NAME="tailscale-gcsvnc"
PASS="password"
DOCKER_IMAGE="dorowu/ubuntu-desktop-lxde-vnc"
TAILSCALE_AUTHKEY_FILE="$HOME/.tailscale_authkey"
VNC_RESOLUTION="1280x720"

# 清理已有容器
docker rm -f "${NAME}-tailscale" "${NAME}-vnc" >/dev/null 2>&1

# 读取 Tailscale Auth Key
if [ ! -f "$TAILSCALE_AUTHKEY_FILE" ]; then
    echo "Enter your Tailscale Auth Key (will be saved in $TAILSCALE_AUTHKEY_FILE):"
    read -r TAILSCALE_AUTHKEY
    echo "$TAILSCALE_AUTHKEY" > "$TAILSCALE_AUTHKEY_FILE"
else
    TAILSCALE_AUTHKEY=$(cat "$TAILSCALE_AUTHKEY_FILE")
fi

# 拉取镜像
docker pull $DOCKER_IMAGE
docker pull tailscale/tailscale:latest

# 启动 Tailscale
docker run -d --rm --net=host \
    --name "${NAME}-tailscale" \
    --cap-add NET_ADMIN \
    --device /dev/net/tun \
    -e TS_AUTHKEY="$TAILSCALE_AUTHKEY" \
    -e TS_STATE_DIR="/var/lib/tailscale" \
    -v "$HOME/.tailscale_state:/var/lib/tailscale" \
    tailscale/tailscale:latest

# 启动 LXDE VNC + 中文 + SSH + RDP
docker run -d --name "${NAME}-vnc" --net=host \
    -v "$HOME:/root" \
    -e VNC_PASSWORD="$PASS" \
    -e LANG="zh_CN.UTF-8" \
    -e DISPLAY_WIDTH=1280 -e DISPLAY_HEIGHT=720 \
    -p 8080:8080 \
    $DOCKER_IMAGE

echo "=== 完成启动 ==="
echo "VNC (Web): http://127.0.0.1:8080, 密码: $PASS"
echo "SSH: ssh root@<Tailscale-IP>"
echo "RDP: connect to <Tailscale-IP>:3389, resolution 1280x720"
