#!/bin/sh

# --- 用户配置 ---
NAME="tailscale-gcsvnc"
PASS="password"  # VNC密码
DOCKER_IMAGE="dorowu/ubuntu-desktop-lxde-vnc"
TAILSCALE_AUTHKEY_FILE="$HOME/.tailscale_authkey"
# --- 用户配置结束 ---

# 读取 Tailscale Auth Key，如果不存在就提示输入一次
if [ ! -f "$TAILSCALE_AUTHKEY_FILE" ]; then
    echo "Enter your Tailscale Auth Key (only once, will be saved in $TAILSCALE_AUTHKEY_FILE):"
    read -r TAILSCALE_AUTHKEY
    echo "$TAILSCALE_AUTHKEY" > "$TAILSCALE_AUTHKEY_FILE"
else
    TAILSCALE_AUTHKEY=$(cat "$TAILSCALE_AUTHKEY_FILE")
fi

# 启动 Tailscale 容器
docker run -d \
    --rm \
    --net=host \
    --name "${NAME}-tailscale" \
    --cap-add NET_ADMIN \
    --device /dev/net/tun \
    -e TS_AUTHKEY="$TAILSCALE_AUTHKEY" \
    -e TS_STATE_DIR="/var/lib/tailscale" \
    -v "$HOME/.tailscale_state:/var/lib/tailscale" \
    tailscale/tailscale:latest

# 启动 VNC 容器
docker run -d \
    --name "${NAME}-vnc" \
    --net=host \
    -v "$HOME:/root" \
    -e VNC_PASSWORD="$PASS" \
    $DOCKER_IMAGE

echo "Tailscale and VNC started."
echo "Connect via Tailscale IP on port 5900 using password '$PASS'."
