# GitHub Codespaces 上的 Cinnamon 桌面环境

## 管理控制台

[![](https://img.shields.io/badge/创建容器-brightgreen?style=for-the-badge&logo=github)](https://github.com/codespaces/new)
[![](https://img.shields.io/badge/管理容器-blue?style=for-the-badge&logo=github)](https://github.com/codespaces)
[![](https://img.shields.io/badge/管理穿透IP-orange?style=for-the-badge&logo=github)](https://login.tailscale.com/admin/machines)
[![](https://img.shields.io/badge/管理AUTHKEY-orange?style=for-the-badge&logo=github)](https://login.tailscale.com/admin/settings/keys)
[![](https://img.shields.io/badge/Fork仓库-8A2BE2?style=for-the-badge&logo=github)](https://github.com/MaxCauIfield/codespace-desktop/fork)
## 介绍：
一个基于CodeSpaceIDE，搭载 Cinnamon 桌面环境的 Ubuntu 24.04 容器，使用Tailscale转发IP地址，并配置网页和客户端的 VNC 连接。
## 快速部署
### 需求
- Fork此项目，并点上Star
- 一个Tailscale账户，注册地址： https://login.tailscale.com/admin/machines
### 生成验证密钥
1. 登录Tailscale管理控制台，并前往keys页面 https://login.tailscale.com/admin/settings/keys
2. 在**Auth keys**菜单下点击**Generate auth keys**，创建Key
3. 随便填写一个key名称，并开启“使用多个设备（**Reusable**）”和“自动移除（**Ephemeral**）”，确保入口唯一和避免重复
4. 点击**Generate Key**按钮，生成验证Key，在弹出的窗口中复制**密钥字符串**
### 配置环境变量
1. 前往你的 GitHub 仓库设置：Settings -> Secrets and variables -> Codespaces。
2. ​点击 **New repository secret**，名称填：
```
TAILSCALE_AUTHKEY
```
3. 值填入你刚才生成的**密钥字符串**。
### 初始化容器
1. 创建新的桌面空间: https://github.com/codespaces/new
2. 选择Fork的Codespace存储库，如 `MaxCauifield/codespace-desktop`
3. 选择区域，建议选择东南亚地区（**Southeast Asia**），延迟最低
4. 选择机器类型，若要解锁更高级的机器类型, 请在Github上提交工单: https://support.github.com/contact?tags=rr-codespaces%2Ccat_codespace
5. 点击 创建**CodeSpace（Create）**，创建过程需要耗费一些时间。
### VNC连接
提供2种不同的VNC连接方式，推荐使用Tailscale+VNC客户端连接
#### 客户端连接
本项目已集成Tailscale，因此无需在服务端安装

若服务未能启动，您可在终端中执行以下命令来重新启动Tailscale
```
sudo tailscale up
```

#### 网页连接
创建完成后, 打开 PORTS 标签页, 访问转发地址, 点击 `vnc.html` 并输入你的VNC密码

默认的 VNC 密码仅为 `password`。您可以通过在终端中运行 `vncpasswd` 命令来更改它。您无需担心密码强度不足的问题，因为 VNC 端口默认并未对外公开；若要访问这些端口，必须先登录您的 GitHub 账号。这一机制极大地提升了安全性。


默认键盘布局和语言为中文（中国）。您可以在 Cinnamon 设置中进行更改。

若要运行 Windows 应用程序，请安装 Wine：https://wiki.winehq.org/Ubuntu

## Github隐私政策说明
在 Codespaces 中运行桌面环境通常是被允许的

微软官方甚至提供了关于如何搭建基于 Fluxbox 的桌面环境（并集成浏览器）的文档：https://github.com/devcontainers/features/tree/main/src/desktop-lite。

不过在本文中，我们将改用 Cinnamon 桌面环境。

因此，请负责任地使用该服务，并严格遵守 GitHub 的《服务条款》，就无需担心任何账号方面的问题。
## 局限性与错误
- 无法启用硬件加速，因为 Codespace 不具备 GPU
- 终端无法打开。请改用 Xfce Terminal 或其他终端工具，系统语言
- 由于Tailscale的限制，AuthKey有效期最长为90天，过期后请重新生成Key，并将其填入仓库的环境变量中

## 截图

![2024-05-31 20 36 02](https://github.com/AndnixSH/codespace-desktop/assets/40742924/efe23986-9024-457f-8e10-d04ac1898b18)

![2024-05-31 20 35 27](https://github.com/AndnixSH/codespace-desktop/assets/40742924/5ddd627e-d48f-413c-a153-dff1173e75de)