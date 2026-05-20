#!/bin/bash

set -e

echo "启动 Docker 桌面..."

docker run -d \
  -p 8080:80 \
  -p 5900:5900 \
  -v "$HOME:/root" \
  -e LANG=zh_CN.UTF-8 \
  -e LANGUAGE=zh_CN:zh \
  -e LC_ALL=zh_CN.UTF-8 \
  dorowu/ubuntu-desktop-lxde-vnc

echo "安装 Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "启动 Tailscale..."
sudo tailscale up

echo "完成"
echo "Web VNC: Cloud Shell Preview on port 8080"
echo "VNC: 通过 Tailscale IP:5900 连接"