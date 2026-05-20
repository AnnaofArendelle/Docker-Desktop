# CloudShell-Desktop
在 Google Cloud Shell 中安装默认的 xfce4 桌面、VNC 和 Tailscale，并通过网页方式访问 VNC 桌面。

本项目不额外嵌套任何容器，桌面依旧使用默认的 xfce 桌面和 VNC 服务器。

# I want to install it now!
[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FAnnaofArendelle%2FCloudShell-Desktop&cloudshell_git_branch=main&cloudshell_tutorial=README.md)

# How to run it?

```
chmod +x wcs.sh
./wcs.sh
```

脚本会自动安装默认的 xfce4 桌面和 VNC Server，并启用 noVNC 网页访问和 Tailscale 登录授权。

# Note
Google Cloud Shell 的 `$HOME` 目录是持久化存储，VNC 配置和桌面数据会保存在 `$HOME` 中。

# License
[MIT License](https://github.com/AnnaofArendelle/CloudShell-Desktop/blob/main/LICENSE)

脚本作者不对脚本本身或用户操作造成的任何损失负责。
