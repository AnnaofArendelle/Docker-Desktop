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
### 一键部署CodeSpace：
 [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?ref=main&location=southeastasia)

选择Fork的Codespace存储库，点击 创建**CodeSpace（Create）**，创建过程需要耗费一些时间。

若要解锁更高级的机器类型, 请在Github上[提交工单](https://support.github.com/contact?tags=rr-codespaces%2Ccat_codespace)
 
### 一键部署CloudShell：
 [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FAnnaofArendelle%2FDocker-Desktop&cloudshell_git_branch=main&cloudshell_tutorial=GCSLEARN.md)

按右侧弹出的说明执行下一步部署操作。

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

> 💡 **慢链路/卡顿优化**：在双 NAT 或走中继的网络下，纯 SSH 打字会有明显延迟。推荐改用 **mosh**（已内置），它走 UDP + 本地预测回显，高延迟下体感接近“零延迟”，断线还能无缝重连：
> ```bash
> mosh --ssh="ssh -p 22" root@<Tailscale-IP>
> ```

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
- Cloudshell版本目前仅支持VNC连接，且只有HOME目录有持久化存储

## 🚀 网络优化
容器已针对慢链路/中继场景做了实际有效的调整：

| 优化项 | 配置 | 效果 |
|--------|------|------|
| mosh | 内置 | UDP + 本地预测回显，高延迟下交互体感接近零延迟，断线无缝重连 |
| VNC 色深 | 16 位 | 相比 24 位省约 1/3 带宽 |
| VNC 编码 | 客户端设 Tight + JPEG 质量 4~6 | 减少图形数据传输量 |
| VNC/RDP 分辨率 | 1280x720 | 平衡清晰度与带宽占用 |

> ⚠️ 说明：早期版本写入的 BBR / TCP 缓冲区 / TCP Fast Open 等 sysctl 已移除。原因是 Tailscale 在 Codespaces 中以 `userspace-networking` 模式运行，隧道流量由 gVisor netstack 处理，不走宿主内核协议栈，这些内核 sysctl 对实际隧道流量无效。
>
> 双 NAT（两端均无公网 IP）场景下卡顿的主因是 Tailscale 回退到共享 DERP 中继。如需根本性提速，可自建 DERP 中继或改用 VPS 单跳反向隧道（rathole/frp）。

如需调整分辨率或其他参数，请修改 `start-desktop.sh` 中的配置。

## 🧩 可选扩展：Cloudflare WARP 出口代理

将指定应用（默认 firefox）的出站流量经 Cloudflare WARP 出网，使**出口 IP 变为 Cloudflare 的共享 VPN IP**，而非 Codespace 的数据中心 IP。

> **默认关闭，零感知。** 不设置开关时，容器行为与原来完全一致，不安装、不启动任何 WARP 组件。

### 启用方式

在仓库的 Codespaces Secrets（Settings → Secrets and variables → Codespaces）中新增：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `ENABLE_WARP` | `true` | 开关。设为 `true` 才启用，删除或设为其他值即关闭 |
| `WARP_LICENSE` | *(可选)* | WARP+ / Zero Trust 的 license key，留空用免费版 |
| `WARP_PROXY_PORT` | *(可选)* | 本地 SOCKS5 端口，默认 `40000` |

设置后**重建 Codespace** 即生效。启用时 firefox 会通过企业策略自动走 WARP，无需手动配置代理；关闭时策略自动移除。

### 手动控制

扩展也可在终端手动开关：

```bash
bash .devcontainer/extensions/warp.sh up       # 安装并启用
bash .devcontainer/extensions/warp.sh status   # 查看状态与出口 IP
bash .devcontainer/extensions/warp.sh down     # 断开并停止
```

### 工作原理与注意事项

- 采用 WARP 的 **proxy 模式**（本地 SOCKS5），**不需要 TUN 设备**，与 Tailscale 的 `userspace-networking` 互不冲突：Tailscale SOCKS（`:1055`）负责入站访问，WARP SOCKS（`:40000`）负责指定应用出站。
- ⚠️ **关于「纯净 IP」**：WARP 免费版出口是数百万用户共享的消费级 VPN IP 段。相比数据中心 IP，它更像「住宅级共享 IP」——对部分网站是改善，但 Google 等风控严格的站点会**专门标记 Cloudflare WARP 段**，可能触发更多验证。若需稳定纯净出口，需配合 WARP+ / Zero Trust 专用 egress。
- 仅代理配置了 SOCKS 的应用（默认 firefox）。SSH/VNC/RDP 等访问通道不受影响，仍走 Tailscale。

## 🙏 鸣谢

#### 💖 本项目引用了以下开源代码
- [AndnixSH/codespace-desktop](https://github.com/AndnixSH/codespace-desktop)
- [ttasc/gcsvnc](https://github.com/ttasc/gcsvnc)
- [raspiduino/winecloudshell](https://github.com/raspiduino/winecloudshell)
#### 🛠 本项目使用以下协议分发
- GPL- v3.0
