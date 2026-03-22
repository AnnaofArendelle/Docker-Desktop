# GitHub Codespaces 上的 Cinnamon 桌面环境
此设置将安装一个搭载 Cinnamon 桌面环境的 Ubuntu 24.04 容器，并配置 VNC 连接。

通常情况下，在 Codespaces 中运行桌面环境是允许的——微软官方甚至提供了关于如何搭建基于 Fluxbox 的桌面环境（并集成浏览器）的文档：https://github.com/devcontainers/features/tree/main/src/desktop-lite。
不过在本文中，我们将改用 Cinnamon 桌面环境。只要您负责任地使用该服务，并严格遵守 GitHub 的《服务条款》，就无需担心任何账号方面的问题。


# 如何使用？
1. Create a new space: https://github.com/codespaces/new
2. Select this repo `AndnixSH/codespace-desktop`
3. Select a machine type. To unlock better machine types, file a ticket to Github: https://support.github.com/contact?tags=rr-codespaces%2Ccat_codespace
4. Click "Create codespace". It will take a while to create
5. Once created, open PORTS tab, open forwarded address, click on `vnc.html` link and enter your VNC password

默认的 VNC 密码仅为 `password`。您可以通过在终端中运行 `vncpasswd` 命令来更改它。您无需担心密码强度不足的问题，因为 VNC 端口默认并未对外公开；若要访问这些端口，必须先登录您的 GitHub 账号。这一机制极大地提升了安全性。

已集成Tailscale到CodeSpace中，首次部署时，会在Terminal中显示Tailscale的授权链接，若未能找到，您可在终端中执行 `sudo tailscale up` 来解决，完成授权后，后续启动桌面环境时会自动运行Tailscale，您无需执行任何操作，直接使用VNC连接即可

默认键盘布局为英语（美国）。您可以在 Cinnamon 设置中进行更改。

若要运行 Windows 应用程序，请安装 Wine：https://wiki.winehq.org/Ubuntu

# 局限性与错误
- 无法启用硬件加速，因为 Codespace 不具备 GPU
- 终端无法打开。请改用 Xfce Terminal 或其他终端工具

# 截图

![2024-05-31 20 36 02](https://github.com/AndnixSH/codespace-desktop/assets/40742924/efe23986-9024-457f-8e10-d04ac1898b18)

![2024-05-31 20 35 27](https://github.com/AndnixSH/codespace-desktop/assets/40742924/5ddd627e-d48f-413c-a153-dff1173e75de)
