#!/bin/bash

#############################################################
# Bash 脚本：在 Google Cloud Shell 中安装 xfce4、VNC、noVNC 和 Tailscale #
# 默认使用 xfce 桌面和 VNC 服务器，不再安装 Wine 相关组件                 #
#############################################################

set -e

# 安装 VNC Server、xfce4 以及网页 VNC 依赖
echo "开始安装 VNC Server、xfce4 和 noVNC..."
sudo apt update
sudo apt install tigervnc-standalone-server xfce4 xfce4-terminal xfce4-taskmanager dbus-x11 novnc websockify -y

# 配置 VNC xstartup
echo "配置 VNC 桌面启动脚本..."
mkdir -p "$HOME/.vnc"
cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
chmod +x "$HOME/.vnc/xstartup"

# 启动 VNC 服务
echo "启动 VNC 服务..."
vncserver -geometry 1280x720 -depth 24 :1

# 启动 noVNC 网页访问
echo "启动 noVNC 网页访问..."
nohup websockify --web=/usr/share/novnc/ 8080 localhost:5901 >/tmp/novnc.log 2>&1 &

# 安装 Tailscale
echo "安装 Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "请完成 Tailscale 登录授权，使用默认授权方式登录。"
sudo tailscale up

# 说明信息
echo "------------------------------------------------------------"
echo "安装完成。"
echo "VNC 网页访问地址: http://127.0.0.1:8080/vnc.html"
echo "Cloud Shell 将 $HOME 目录作为持久化存储，VNC 配置和桌面数据会保存在此目录。"
echo "如果需要，可通过 Tailscale 访问此环境。"
echo "------------------------------------------------------------"

