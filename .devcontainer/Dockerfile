# 使用微软官方 DevContainer 基础镜像
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# 切换到 root 用户
USER root

# 禁用交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive

# 设置系统默认语言为中文
RUN apt-get update && apt-get install -y locales language-pack-zh-hans && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

# 安装必要软件、中文字体以及 Fcitx5 输入法
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
        cabextract \
        htop \
        software-properties-common \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        fcitx5 \
        fcitx5-chinese-addons \
        fcitx5-frontend-gtk3 \
        fcitx5-frontend-qt5 && \
    apt-get remove -y firefox && \
    echo 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' | tee /etc/apt/preferences.d/Mozilla && \
    add-apt-repository ppa:mozillateam/ppa && \
    apt-get update && \
    apt-get install -y firefox

# 设置输入法的全局环境变量
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS=@im=fcitx
ENV SDL_IM_MODULE=fcitx
ENV GLFW_IM_MODULE=ibus

# 安装 Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh