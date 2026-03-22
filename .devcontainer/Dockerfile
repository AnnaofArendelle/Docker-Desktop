# 使用微软官方 DevContainer 基础镜像
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# 切换到 root 用户
USER root

# 禁用交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive

# 预设键盘布局
RUN echo 'keyboard-configuration keyboard-configuration/layoutcode string us' | debconf-set-selections && \
    echo 'keyboard-configuration keyboard-configuration/layout select English (US)' | debconf-set-selections

# 安装必要软件
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        tigervnc-standalone-server \
        cinnamon-desktop-environment \
        dbus-x11 \
        xfce4 \
        xfce4-goodies \
        novnc \
        python3-websockify \
        python3-numpy \
        python3-pip \
        pipx \
        cabextract \
        tightvncserver \
        htop \
        software-properties-common && \
    apt-get remove -y firefox && \
    echo 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' | tee /etc/apt/preferences.d/Mozilla && \
    add-apt-repository ppa:mozillateam/ppa && \
    apt-get update && \
    apt-get install -y firefox

# 安装 Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh
