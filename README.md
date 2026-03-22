# GitHub Codespaces 上的 Cinnamon 桌面环境

## 管理控制台
[![](https://img.shields.io/badge/创建容器-brightgreen?style=for-the-badge&logo=github)](https://github.com/codespaces/new)
[![](https://img.shields.io/badge/管理容器-blue?style=for-the-badge&logo=github)](https://github.com/codespaces)
[![](https://img.shields.io/badge/管理穿透IP-orange?style=for-the-badge&logo=github)](https://login.tailscale.com/admin/machines)
[![](https://img.shields.io/badge/Fork仓库-8A2BE2?style=for-the-badge&logo=github)](https://github.com/MaxCauIfield/codespace-desktop/fork)

## 介绍：
一个基于CodeSpaceIDE，搭载 Cinnamon 桌面环境的 Ubuntu 24.04 容器，使用Tailscale转发IP地址，并配置网页和客户端的 VNC 连接。
## 快速部署
### 需求
一个Tailscale账户，注册地址： https://login.tailscale.com/admin/machines
### 初始化容器
1. Fork此项目，并点上Star
2. 创建新的桌面空间: https://github.com/codespaces/new
3. 选择Fork的Codespace存储库，如 `MaxCauifield/codespace-desktop`
4. 选择区域，建议选择东南亚地区（Southeast Asia），延迟最低
5. 选择机器类型，若要解锁更高级的机器类型, 请在Github上提交工单: https://support.github.com/contact?tags=rr-codespaces%2Ccat_codespace
6. 点击 创建CodeSpace（Create），创建过程需要耗费一些时间。
### VNC连接
提供2种不同的VNC连接方式，推荐使用Tailscale+VNC客户端连接
#### T+V客户端连接
本项目已集成Tailscale，因此无需在服务端安装

首次部署时，会在Terminal中显示Tailscale的授权链接，完成授权后，后续启动桌面环境时会自动运行Tailscale，您无需执行任何操作，直接使用VNC连接即可

若未能找到或删除了授权，您可在终端中执行以下命令来执行或重新赋予授权
```
sudo tailscale up
```

#### 网页连接
1. 创建完成后, 打开 PORTS 标签页, 访问转发地址, 点击 `vnc.html` 并输入你的VNC密码

默认的 VNC 密码仅为 `password`。您可以通过在终端中运行 `vncpasswd` 命令来更改它。您无需担心密码强度不足的问题，因为 VNC 端口默认并未对外公开；若要访问这些端口，必须先登录您的 GitHub 账号。这一机制极大地提升了安全性。


默认键盘布局为英语（美国）。您可以在 Cinnamon 设置中进行更改。

若要运行 Windows 应用程序，请安装 Wine：https://wiki.winehq.org/Ubuntu

## 这是否被允许？
通常情况下，在 Codespaces 中运行桌面环境是允许的——微软官方甚至提供了关于如何搭建基于 Fluxbox 的桌面环境（并集成浏览器）的文档：https://github.com/devcontainers/features/tree/main/src/desktop-lite。
不过在本文中，我们将改用 Cinnamon 桌面环境。只要您负责任地使用该服务，并严格遵守 GitHub 的《服务条款》，就无需担心任何账号方面的问题。
## 局限性与错误
- 无法启用硬件加速，因为 Codespace 不具备 GPU
- 终端无法打开。请改用 Xfce Terminal 或其他终端工具

## 截图

![2024-05-31 20 36 02](https://github.com/AndnixSH/codespace-desktop/assets/40742924/efe23986-9024-457f-8e10-d04ac1898b18)

![2024-05-31 20 35 27](https://github.com/AndnixSH/codespace-desktop/assets/40742924/5ddd627e-d48f-413c-a153-dff1173e75de)