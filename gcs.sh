#!/bin/sh

# --- 用户配置区 ---
NAME="tailscale-gcsvnc"
PASS="gcsvnc"   # 请修改你的VNC密码

# 安装你需要的软件包 (桌面环境, 应用等)
install_packages() {
    packages="xfce4 dbus-x11"
    sudo apt update
    sudo apt install -y $packages
}

# VNC会话启动脚本 (类似 xinitrc)
fxstartup="#!/bin/sh
# Put your autostart programs here.

# Run WM/DE (It is usually placed at the end of the file)
dbus-update-activation-environment --all
exec dbus-run-session xfce4-session
"
# --- 用户配置区结束 ---

# --- 脚本内部逻辑 ---
TAILSCALE_AUTHKEY="" # 通过环境变量或手动输入

setup() {
    echo "=== Starting setup for ${NAME} ==="

    # 1. 检查并获取 Tailscale Auth Key
    if [ -z "$TAILSCALE_AUTHKEY" ]; then
        echo "WARNING: You need a Tailscale Auth Key to proceed."
        echo "Please visit https://login.tailscale.com/admin/settings/keys to generate one."
        printf "Enter your Auth Key: "
        read -r TAILSCALE_AUTHKEY
        if [ -z "$TAILSCALE_AUTHKEY" ]; then
            echo "Error: An Auth Key is required for automated setup."
            exit 1
        fi
    fi

    # 2. 启动Tailscale容器 (使用主机网络)
    echo "Joining Tailscale network..."
    docker run \
        -d \
        --rm \
        --net=host \
        --name "${NAME}-tailscale" \
        --cap-add NET_ADMIN \
        --device /dev/net/tun \
        -e TS_AUTHKEY="$TAILSCALE_AUTHKEY" \
        -e TS_STATE_DIR="/var/lib/tailscale" \
        -v "${HOME}/.tailscale_state:/var/lib/tailscale" \
        tailscale/tailscale:latest
    echo "Tailscale container started. Waiting for network to be ready..."

    # 3. 安装VNC软件并配置
    echo "Installing VNC server and desktop environment..."
    sudo apt update
    printf "35\n1\n" | sudo apt install tigervnc-standalone-server tigervnc-xorg-extension -y
    printf "%s\n%s\nn\n" $PASS $PASS | vncpasswd
    echo "$fxstartup" > ~/.vnc/xstartup
    
    # 4. 安装用户自定义软件包
    install_packages

    echo "=== Setup completed! ==="
    echo "You can now start the VNC server by running './tailscale-gcsvnc'"
}

ifnotsetup() {
    if [ ! -x "$(command -v vncserver)" ]; then
        echo "Error: VNC server is not installed."
        echo "Please run './tailscale-gcsvnc setup' first."
        exit 1
    fi
    
    # 确保 Tailscale 容器在运行，如果不在则尝试启动
    if ! docker ps --format '{{.Names}}' | grep -q "^${NAME}-tailscale$"; then
        echo "Warning: Tailscale container is not running. Attempting to start..."
        # 注意：这里需要一个永久有效的 auth key 或已持久化的状态
        if [ -f "$HOME/.tailscale_state/authkey" ]; then
            docker run \
                -d \
                --rm \
                --net=host \
                --name "${NAME}-tailscale" \
                --cap-add NET_ADMIN \
                --device /dev/net/tun \
                -e TS_AUTHKEY="$(cat $HOME/.tailscale_state/authkey)" \
                -e TS_STATE_DIR="/var/lib/tailscale" \
                -v "${HOME}/.tailscale_state:/var/lib/tailscale" \
                tailscale/tailscale:latest
            echo "Tailscale container restarted."
        else
            echo "Error: Cannot restart Tailscale. Please run setup again."
            exit 1
        fi
    fi
}

case "$1" in
    setup)   setup ;;
    "")      ifnotsetup; vncserver -localhost no ;;
    kill)    ifnotsetup; vncserver -kill ":$2" ;;
    killall) ifnotsetup; vncserver -kill :* ;;
    *)
        echo "Usage: $0 [setup|kill <display>|killall]"
        exit 1
        ;;
esac
