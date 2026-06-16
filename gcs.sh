#!/bin/bash
# Cloud Shell Desktop —— 一键部署 SSH / RDP / VNC / Web / mosh
#
# 设计要点（针对 Google Cloud Shell 的限制）：
#   * 只有 $HOME 持久化  -> 所有状态（镜像缓存、Tailscale 状态、容器 /root 家目录、
#     SSH 主机密钥、VNC 配置）全部落在 $HOME 下。
#   * Docker 层每会话清空 -> 首次构建后用 `docker save | gzip` 把镜像缓存到 $HOME，
#     下次会话 `docker load` 秒级恢复，避免每次重建 ~5 分钟。
#   * Tailscale 以内核模式运行（TS_USERSPACE=false + /dev/net/tun + NET_ADMIN），
#     这样入站 SSH/RDP/VNC 端口才能在 tailnet 上被真正访问到；桌面容器用
#     --net=host 与 Tailscale 容器共享网络命名空间。
set -e

# ---------- 用户配置 ----------
NAME="${NAME:-gcs-desktop}"
VNC_PASS="${VNC_PASS:-password}"        # VNC / RDP 密码
ROOT_PASS="${ROOT_PASS:-codespace}"     # SSH root 密码
RESOLUTION="${RESOLUTION:-1280x720}"    # 分辨率
DEPTH="${DEPTH:-16}"                     # VNC 色深（16 位省带宽）
IMAGE_TAG="${IMAGE_TAG:-gcs-desktop:latest}"
INSTALL_FIREFOX="${INSTALL_FIREFOX:-0}" # 设为 1 在镜像内安装 Firefox
# ---------- 配置结束 ----------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_CTX="$SCRIPT_DIR/gcs"
STATE_DIR="$HOME/.gcs-desktop"
CACHE_IMG="$STATE_DIR/image.tar.gz"
CACHE_SUM="$STATE_DIR/image.sha256"
CONTAINER_HOME="$STATE_DIR/home"        # 映射到容器 /root，持久化桌面/SSH/VNC 配置
TS_STATE_DIR="$STATE_DIR/tailscale"
AUTHKEY_FILE="$STATE_DIR/authkey"

mkdir -p "$STATE_DIR" "$CONTAINER_HOME" "$TS_STATE_DIR"

if [ ! -f "$BUILD_CTX/Dockerfile" ]; then
    echo "错误: 找不到构建上下文 $BUILD_CTX/Dockerfile" >&2
    exit 1
fi

# ---------- Tailscale Auth Key（只问一次，存到 $HOME）----------
if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
    echo "$TAILSCALE_AUTHKEY" > "$AUTHKEY_FILE"
elif [ ! -f "$AUTHKEY_FILE" ]; then
    echo "请输入你的 Tailscale Auth Key（只需一次，将保存到 $AUTHKEY_FILE）:"
    read -r KEY_IN
    echo "$KEY_IN" > "$AUTHKEY_FILE"
fi
chmod 600 "$AUTHKEY_FILE" 2>/dev/null || true
AUTHKEY="$(cat "$AUTHKEY_FILE")"

# ---------- 镜像：构建或从 $HOME 缓存恢复 ----------
# 用构建上下文的内容哈希判断是否需要重建
ctx_sum() { cat "$BUILD_CTX/Dockerfile" "$BUILD_CTX/entrypoint.sh" 2>/dev/null | sha256sum | awk '{print $1}'; }
CUR_SUM="$(ctx_sum)"

need_build=1
if docker image inspect "$IMAGE_TAG" >/dev/null 2>&1 && [ "$(cat "$CACHE_SUM" 2>/dev/null)" = "$CUR_SUM" ]; then
    echo "镜像已在本地且与构建上下文一致，跳过构建。"
    need_build=0
elif [ -f "$CACHE_IMG" ] && [ "$(cat "$CACHE_SUM" 2>/dev/null)" = "$CUR_SUM" ]; then
    echo "从 $HOME 缓存恢复镜像（docker load）..."
    if gunzip -c "$CACHE_IMG" | docker load; then
        need_build=0
    else
        echo "缓存恢复失败，将重新构建。"
    fi
fi

if [ "$need_build" -eq 1 ]; then
    echo "构建镜像 $IMAGE_TAG（首次约需数分钟）..."
    docker build \
        --build-arg INSTALL_FIREFOX="$INSTALL_FIREFOX" \
        -t "$IMAGE_TAG" "$BUILD_CTX"
    echo "缓存镜像到 $HOME（下次会话秒级恢复）..."
    docker save "$IMAGE_TAG" | gzip > "$CACHE_IMG.tmp" && mv "$CACHE_IMG.tmp" "$CACHE_IMG"
    echo "$CUR_SUM" > "$CACHE_SUM"
fi

# ---------- 清理旧容器 ----------
docker rm -f "${NAME}-tailscale" "${NAME}-desktop" 2>/dev/null || true

# ---------- 启动 Tailscale（内核模式，提供 tailnet 网络命名空间）----------
echo "启动 Tailscale（内核模式）..."
docker run -d \
    --name "${NAME}-tailscale" \
    --hostname "$NAME" \
    --cap-add NET_ADMIN \
    --cap-add SYS_MODULE \
    --device /dev/net/tun \
    -e TS_AUTHKEY="$AUTHKEY" \
    -e TS_USERSPACE=false \
    -e TS_STATE_DIR=/var/lib/tailscale \
    -e TS_EXTRA_ARGS="--accept-dns=false" \
    -p 5900:5900 \
    -p 6080:6080 \
    -p 3389:3389 \
    -p 22:22 \
    -p 60000-61000:60000-61000/udp \
    -v "$TS_STATE_DIR:/var/lib/tailscale" \
    tailscale/tailscale:latest

# 等待 Tailscale 起来并取得 IP
echo "等待 Tailscale 取得 IP..."
TS_IP=""
for i in $(seq 1 20); do
    TS_IP="$(docker exec "${NAME}-tailscale" tailscale ip -4 2>/dev/null | head -n1 || true)"
    [ -n "$TS_IP" ] && break
    sleep 1
done

# ---------- 启动桌面容器（共享 Tailscale 容器的网络命名空间）----------
echo "启动桌面容器（SSH/RDP/VNC/Web/mosh）..."
docker run -d \
    --name "${NAME}-desktop" \
    --network "container:${NAME}-tailscale" \
    --shm-size=512m \
    -e RESOLUTION="$RESOLUTION" \
    -e DEPTH="$DEPTH" \
    -e VNC_PASS="$VNC_PASS" \
    -e ROOT_PASS="$ROOT_PASS" \
    -v "$CONTAINER_HOME:/root" \
    "$IMAGE_TAG"

echo ""
echo "========================================"
echo "  Cloud Shell Desktop 已启动"
echo "  Tailscale IP: ${TS_IP:-<在 Tailscale 控制台查看>}"
echo "========================================"
echo "  • SSH:     ssh root@${TS_IP:-<IP>}            (密码: $ROOT_PASS)"
echo "  • mosh:    mosh --ssh=\"ssh -p 22\" root@${TS_IP:-<IP>}  (慢链路推荐)"
echo "  • VNC:     ${TS_IP:-<IP>}:5900                (密码: $VNC_PASS, ${RESOLUTION}/${DEPTH}bit)"
echo "  • RDP:     ${TS_IP:-<IP>}:3389  用户 root     (密码: $VNC_PASS)"
echo "  • Web VNC: http://${TS_IP:-<IP>}:6080/vnc.html"
echo "========================================"
echo "查看桌面日志: docker logs -f ${NAME}-desktop"
