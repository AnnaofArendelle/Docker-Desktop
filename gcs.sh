#!/bin/sh

NAME="tailscale-gcsvnc"
PASS="password"           # VNC密码
SSH_PASS="password"       # SSH密码
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
    -e SSH_PASSWORD="$SSH_PASS" \
    -e LANG="zh_CN.UTF-8" \
    -e DISPLAY_WIDTH=1280 -e DISPLAY_HEIGHT=720 \
    -p 8080:8080 \
    $DOCKER_IMAGE /bin/sh -c "
        # 设置中文
        apt-get update && apt-get install -y language-pack-zh-hans locales sudo \
        && locale-gen zh_CN.UTF-8 \
        && update-locale LANG=zh_CN.UTF-8 \
        # 安装 SSH 和 RDP
        && apt-get install -y openssh-server xrdp \
        && mkdir -p /var/run/sshd \
        # 设置 root 密码
        && echo 'root:$SSH_PASSWORD' | chpasswd \
        # 启动服务
        && service ssh start \
        && service xrdp start \
        # 启动 VNC
        && vncserver :1 -geometry ${VNC_RESOLUTION} -depth 24 \
        && echo 'Ready'"
