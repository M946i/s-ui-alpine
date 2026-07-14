#!/usr/bin/env bash

set -e

VERSION="v1.4.1"
INSTALL_DIR="/usr/local/s-ui"
LOG_DIR="/var/log/s-ui"

echo "[1/6] 安装依赖..."

apk update
apk add --no-cache \
    bash curl wget tar tzdata ca-certificates gcompat

ARCH=$(uname -m)

case "$ARCH" in
    x86_64) ARCH=amd64 ;;
    aarch64) ARCH=arm64 ;;
    armv7*) ARCH=armv7 ;;
    *)
        echo "不支持架构: $ARCH"
        exit 1
        ;;
esac

echo "[2/6] 下载 s-ui..."

cd /tmp
wget -O s-ui.tar.gz \
https://github.com/alireza0/s-ui/releases/download/${VERSION}/s-ui-linux-${ARCH}.tar.gz

rm -rf s-ui
tar -zxf s-ui.tar.gz

echo "[3/6] 安装文件..."

rm -rf ${INSTALL_DIR}
mkdir -p /usr/local
cp -rf s-ui ${INSTALL_DIR}

chmod +x ${INSTALL_DIR}/sui
chmod +x ${INSTALL_DIR}/s-ui.sh

ln -sf ${INSTALL_DIR}/s-ui.sh /usr/bin/s-ui

echo "[4/6] 初始化数据库..."
${INSTALL_DIR}/sui migrate || true

mkdir -p ${LOG_DIR}

echo "[5/6] 创建容器守护脚本..."

cat >/usr/local/s-ui/run.sh <<'RUN'
#!/usr/bin/env bash

while true; do
    echo "[s-ui] starting..." >> /var/log/s-ui.log

    /usr/local/s-ui/sui >> /var/log/s-ui.log 2>&1

    echo "[s-ui] crashed, restarting in 3s..." >> /var/log/s-ui.log
    sleep 3
done
RUN

chmod +x /usr/local/s-ui/run.sh

echo "[6/6] 启动服务..."

nohup /usr/local/s-ui/run.sh >/dev/null 2>&1 &

sleep 2

echo ""
echo "=============================="
echo "s-ui 容器模式安装完成"
echo "=============================="
echo ""

echo "查看地址："
/usr/local/s-ui/sui uri || true

echo ""
echo "查看日志："
echo "tail -f /var/log/s-ui.log"
echo ""
echo "进程检查："
echo "ps | grep sui"
