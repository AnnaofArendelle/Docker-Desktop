# CloudShell-Desktop
在 Google Cloud Shell 中一键部署带桌面的 Ubuntu 容器，提供 **SSH / RDP / VNC / Web / mosh** 五种登录方式，并通过 Tailscale 组网安全访问。

功能与 Codespaces 版本对齐：xfce4 桌面 + TigerVNC + noVNC + xrdp + OpenSSH + mosh，VNC 16 位色深、1280x720 固定分辨率。

# I want to install it now!
[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FAnnaofArendelle%2FDocker-Desktop&cloudshell_git_branch=main&cloudshell_tutorial=README.md)

# How to run it?

先在 Tailscale 控制台生成一个 **Reusable + Ephemeral** 的 Auth Key，然后：

```
export TAILSCALE_AUTHKEY=tskey-auth-xxxxx   # 也可不设，脚本会交互式询问一次
chmod +x gcs.sh
./gcs.sh
```

脚本会：
1. 用 `gcs/Dockerfile` 构建桌面镜像（首次约数分钟），并把镜像缓存到 `$HOME`，下次会话秒级恢复。
2. 以**内核模式**启动 Tailscale 容器（提供 tailnet 网络命名空间）。
3. 启动桌面容器，拉起 VNC / noVNC / xrdp / sshd，并保持运行。

启动完成后会打印各连接方式的地址与密码。

# 连接方式

获取 Tailscale IP 后（脚本会打印，或在 Tailscale 控制台查看）：

| 方式 | 地址 | 用户 / 密码 | 说明 |
|------|------|-------------|------|
| SSH | `ssh root@<IP>` | root / `codespace` | 支持 X11 转发（`ssh -X`） |
| mosh | `mosh --ssh="ssh -p 22" root@<IP>` | root / `codespace` | **慢链路推荐**，UDP + 本地预测回显 |
| VNC | `<IP>:5900` | / `password` | 16 位色深，1280x720 |
| RDP | `<IP>:3389` | root / `password` | Windows mstsc 直连 |
| Web VNC | `http://<IP>:6080/vnc.html` | / `password` | 浏览器访问 |

> 💡 **慢链路/卡顿优化**：双 NAT 或走 DERP 中继时，纯 SSH 打字会有明显延迟。优先使用 **mosh**（已内置），高延迟下体感接近“零延迟”，断线还能无缝重连。VNC 客户端建议设 Tight 编码 + JPEG 质量 4~6。

# 自定义参数

通过环境变量覆盖默认值，例如：

```
VNC_PASS=mypass ROOT_PASS=mysecret RESOLUTION=1920x1080 INSTALL_FIREFOX=1 ./gcs.sh
```

| 变量 | 默认 | 说明 |
|------|------|------|
| `VNC_PASS` | `password` | VNC / RDP 密码 |
| `ROOT_PASS` | `codespace` | SSH root 密码 |
| `RESOLUTION` | `1280x720` | 桌面分辨率 |
| `DEPTH` | `16` | VNC 色深（位） |
| `INSTALL_FIREFOX` | `0` | 设为 `1` 在镜像内安装 Firefox |
| `TAILSCALE_AUTHKEY` | — | Tailscale Auth Key（不设则交互询问） |

# Note
Google Cloud Shell **只有 `$HOME` 目录持久化**，且 Docker 镜像层每会话清空。因此本项目把所有状态都放在 `$HOME/.gcs-desktop/` 下：

- `image.tar.gz` —— 缓存的桌面镜像（避免每次会话重新构建）
- `home/` —— 映射到容器 `/root`，持久化桌面配置、VNC 密码、**SSH 主机密钥**（指纹不变）
- `tailscale/` —— Tailscale 状态
- `authkey` —— 保存的 Auth Key

> Tailscale Auth Key 有效期最长 90 天，过期后请重新生成并重新运行脚本。

# License
[MIT License](https://github.com/AnnaofArendelle/CloudShell-Desktop/blob/main/LICENSE)

脚本作者不对脚本本身或用户操作造成的任何损失负责。
