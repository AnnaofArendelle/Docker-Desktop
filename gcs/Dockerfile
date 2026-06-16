# Cloud Shell Desktop —— 忠实移植 Codespaces 的功能（SSH / RDP / VNC / Web / mosh）
# 基础镜像用纯净的 ubuntu:24.04，桌面用较轻量的 xfce4（Cloud Shell 每会话重建镜像，
# 用 xfce 而非 Cinnamon 能显著缩短构建时间，桌面功能等价）。
FROM ubuntu:24.04

# 禁用交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive

# 系统默认语言设为中文（中国），与 Codespaces 版保持一致
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales language-pack-zh-hans && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# 桌面 + VNC + noVNC + RDP + SSH + mosh + 中文字体/输入法
#   tigervnc-standalone-server  : VNC 服务端（Xvnc）
#   xfce4 / xfce4-goodies       : 桌面环境
#   novnc / websockify          : Web VNC
#   xrdp / xorgxrdp             : RDP 服务端（通过 libvnc 后端接到 Xvnc:5900）
#   openssh-server              : SSH
#   mosh                        : UDP + 本地预测回显，慢链路下交互体感接近零延迟
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        ca-certificates \
        curl \
        netcat-openbsd \
        dbus-x11 \
        xfce4 \
        xfce4-terminal \
        xfce4-goodies \
        tigervnc-standalone-server \
        tigervnc-common \
        novnc \
        websockify \
        python3-numpy \
        xrdp \
        xorgxrdp \
        openssh-server \
        mosh \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        fcitx5 \
        fcitx5-chinese-addons \
        fcitx5-frontend-gtk3 \
        fcitx5-frontend-qt5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 输入法全局环境变量
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS=@im=fcitx
ENV SDL_IM_MODULE=fcitx

# 可选：通过 --build-arg INSTALL_FIREFOX=1 安装 Firefox（默认不装以加快构建）
ARG INSTALL_FIREFOX=0
RUN if [ "$INSTALL_FIREFOX" = "1" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends software-properties-common && \
        printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/Mozilla && \
        add-apt-repository -y ppa:mozillateam/ppa && \
        apt-get update && \
        apt-get install -y --no-install-recommends firefox && \
        apt-get clean && rm -rf /var/lib/apt/lists/*; \
    fi

# SSH 服务端配置：允许 root 密码登录、开启 X11 转发
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?X11Forwarding.*/X11Forwarding yes/' /etc/ssh/sshd_config && \
    sed -i 's/#\?X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config && \
    echo 'export DISPLAY=:1' >> /etc/profile

# xrdp：禁用自带的 sesman 监听端口（我们用 libvnc 直接接到 Xvnc），
# 桌面会话用 xfce4
RUN sed -i 's/^port=3350/port=-1/' /etc/xrdp/sesman.ini 2>/dev/null || true && \
    echo 'startxfce4' > /etc/skel/.xsession && \
    cp /etc/skel/.xsession /root/.xsession && \
    chown root:root /root/.xsession

# 入口脚本（容器内启动所有服务）
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 端口：SSH(22) VNC(5900) RDP(3389) Web-VNC(6080) mosh(UDP 60000-61000)
EXPOSE 22 3389 5900 6080 60000-61000/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
