# GitHub Codespaces 上的 Cinnamon 桌面环境

在CloudSpace上运行你的桌面

## 💻 管理控制台

[![](https://img.shields.io/badge/创建容器-brightgreen?style=for-the-badge&logo=github)](https://github.com/codespaces/new)
[![](https://img.shields.io/badge/管理容器-blue?style=for-the-badge&logo=github)](https://github.com/codespaces)
[![](https://img.shields.io/badge/管理穿透IP-orange?style=for-the-badge&logo=github)](https://login.tailscale.com/admin/machines)
[![](https://img.shields.io/badge/管理AUTHKEY-orange?style=for-the-badge&logo=github)](https://login.tailscale.com/admin/settings/keys)
[![](https://img.shields.io/badge/Fork仓库-8A2BE2?style=for-the-badge&logo=github)](https://github.com/MaxCauIfield/codespace-desktop/fork)
## 📖 项目简介
![2024-05-31 20 36 02](https://github.com/user-attachments/assets/4ad02b06-5019-4d2e-85f0-4e0cbfcaa578)


一个基于CodeSpaceIDE，搭载 Cinnamon 桌面环境的 Ubuntu 24.04 容器。
## ✨ 核心特色
- ​🌐 **混合组网** 支持SSH/RDP/VNC/网页四种登录方式，敏感认证均有环境变量保护
- ​🛡️ **安全传输** 所有访问经过认证+加密传输，环境变量保护，深度保障安全
- ​📦 **开箱即用** 详细的文档，精心的配置，自动化的流程，本土化适配
- ​🚀 **性能优化** TCP Fast Open + BBR拥塞控制，1280x720固定分辨率，流畅体验
- ​🛠️ **工具集成** 核心组件与扩展包分离，模块设计灵活选装，开发者友好
- ​💻 **RDP支持** Windows远程桌面协议支持，Windows用户可直接使用mstsc连接
- ​🔐 **SSH支持** 内置OpenSSH服务器，支持命令行访问和X11转发
## 💡 快速部署
### 需求
- Fork此项目，并点上Star
- 一个Tailscale账户， [点此注册](https://login.tailscale.com/admin/machines)
### 生成验证密钥
1. 登录Tailscale管理控制台，并生成key[点此进入key页面](https://login.tailscale.com/admin/settings/keys)
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
1. 创建新的桌面空间: [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=1169948011&location=southeastasia)

2. 选择Fork的Codespace存储库，如 `MaxCauifield/codespace-desktop`
3. 选择区域，建议选择东南亚地区（**Southeast Asia**），延迟最低
4. 选择机器类型，若要解锁更高级的机器类型, 请在Github上[提交工单](https://support.github.com/contact?tags=rr-codespaces%2Ccat_codespace)
5. 点击 创建**CodeSpace（Create）**，创建过程需要耗费一些时间。
### 连接方式
提供4种不同的连接方式，推荐使用Tailscale+客户端连接

#### 1. SSH连接 (推荐开发者)
通过SSH命令行访问容器，支持X11转发和文件传输：

1. 在 Tailscale 管理控制台获取 Codespace 的 IP 地址
2. 连接命令：
   ```bash
   ssh root@<Tailscale-IP>
   ```
3. 登录信息：
   - **用户名**: `root`
   - **密码**: `codespace`
4. X11转发（可选）：
   ```bash
   ssh -X root@<Tailscale-IP>
   ```

**注意**: SSH使用22端口，已在devcontainer.json中配置转发。首次连接需确认主机密钥指纹。

#### 2. RDP连接 (推荐Windows用户)
通过Windows自带的远程桌面客户端连接，体验最佳：

1. 在 Tailscale 管理控制台获取 Codespace 的 IP 地址
2. 打开 Windows 远程桌面连接 (mstsc)
3. 输入 Tailscale IP 地址，点击连接
4. 登录信息：
   - **用户名**: `root`
   - **密码**: `password` (与VNC密码相同)
   - **分辨率**: 固定 1280x720
5. 首次连接时会出现证书警告，点击"是"继续

**注意**: RDP使用3389端口，分辨率固定为1280x720以保证流畅度

#### 3. VNC客户端连接
本项目已集成Tailscale，因此无需在服务端安装

**推荐客户端**：TigerVNC Viewer / RealVNC / TightVNC

1. 在 Tailscale 管理控制台获取 Codespace 的 IP 地址
2. VNC 连接地址：`<Tailscale-IP>:5900`
3. 密码：`password`
4. 分辨率：固定 1280x720

若服务未能启动，您可在终端中执行以下命令来重新启动Tailscale
```
sudo tailscale up
```

#### 4. 网页连接 (Web VNC)
创建完成后, 打开 PORTS 标签页, 访问转发地址, 点击 `vnc.html` 并输入你的VNC密码

默认分辨率：1280x720

默认的 VNC 密码仅为 `password`。您可以通过在终端中运行 `vncpasswd` 命令来更改它。


默认键盘布局和语言为中文（中国）。您可以在 Cinnamon 设置中进行更改。

若要运行 Windows 应用程序，请[安装 Wine](https://wiki.winehq.org/Ubuntu)

## ⚠️ 隐私政策说明
在 Codespaces 中运行桌面环境通常是被允许的

微软官方甚至提供了关于如何搭建基于 Fluxbox 的桌面环境（并集成浏览器）的文档：https://github.com/devcontainers/features/tree/main/src/desktop-lite。

不过在本文中，我们将改用 Cinnamon 桌面环境。

因此，请负责任地使用该服务，并严格遵守 GitHub 的《服务条款》，就无需担心任何账号方面的问题。
## ⛔ 局限性与错误
- 无法启用硬件加速，因为 Codespace 不具备 GPU，系统语言汉化不完整
- 由于Tailscale的限制，AuthKey有效期最长为90天，过期后请重新生成Key，并将其填入仓库的环境变量中
- ~~终端无法打开~~（已修复）

## 🚀 网络优化
容器已内置网络性能优化，针对Tailscale隧道进行了特别调整：

| 优化项 | 配置 | 效果 |
|--------|------|------|
| TCP Fast Open | 启用 | 减少连接建立延迟 |
| BBR拥塞控制 | 启用 | 提升高延迟网络下的吞吐量 |
| TCP缓冲区 | 16MB | 优化大带宽延迟积网络 |
| VNC/RDP分辨率 | 1280x720 | 平衡清晰度与带宽占用 |
| 压缩算法 | 启用 | 减少数据传输量 |

如需调整分辨率或其他参数，请修改 `start-desktop.sh` 中的配置。

## 🙏 鸣谢

#### 💖 本项目引用了以下开源代码
- [AndnixSH/codespace-desktop](https://github.com/AndnixSH/codespace-desktop)
- [shields.io(图标)](https://img.shields.io/)
#### 🛠 本项目使用以下协议分发
- GPL- v3.0