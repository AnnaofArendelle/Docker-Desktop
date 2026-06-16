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

# 安装 xrdp (RDP服务器)、Xorg 后端、OpenSSH 服务器和 mosh
# mosh 走 UDP + 本地预测回显，在高延迟/中继链路下交互体感远好于纯 SSH
RUN apt-get update && \
    apt-get install -y \
        xrdp \
        xorgxrdp \
        openssh-server \
        xauth \
        mosh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 配置 SSH 服务器
RUN mkdir -p /var/run/sshd && \
    echo 'root:codespace' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config && \
    sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config && \
    printf '# 仅当 DISPLAY 未设置时，才回退到本地 VNC 桌面 :1\n# ssh -X 登录时 sshd 已设好转发 DISPLAY (如 localhost:10.0)，此处不覆盖，X11 转发正常\n# 普通 ssh 登录时 DISPLAY 为空，回退到 :1 以便操作 VNC 桌面\nif [ -z "$DISPLAY" ]; then\n    export DISPLAY=:1\nfi\n' > /etc/profile.d/desktop-display.sh

# 配置 xrdp 使用 Xvnc 后端连接到 TigerVNC
RUN sed -i 's/^port=3350/port=-1/' /etc/xrdp/sesman.ini && \
    sed -i 's/^ListenPort=3350/ListenPort=-1/' /etc/xrdp/sesman.ini && \
    sed -i 's/^ssl_protocols=.*/ssl_protocols=TLSv1.2, TLSv1.3/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^crypt_level=.*/crypt_level=high/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^max_bpp=.*/max_bpp=24/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^#xserverbpp=24/xserverbpp=24/' /etc/xrdp/xrdp.ini

# 设置 xrdp 用户权限
RUN usermod -a -G ssl-cert xrdp && \
    echo 'cinnamon-session' > /etc/skel/.xsession && \
    cp /etc/skel/.xsession /root/.xsession && \
    chown root:root /root/.xsession

# 复制启动脚本
COPY start-desktop.sh /usr/local/bin/start-desktop.sh
RUN chmod +x /usr/local/bin/start-desktop.sh