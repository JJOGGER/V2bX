#!/bin/bash

# V2bX 快速更新、编译和启动脚本（简化版）
# 使用方法: bash update_build_simple.sh

set -e

# 配置变量（根据实际情况修改）
PROJECT_DIR="/www/wwwroot/V2bX"
GIT_BRANCH="dev_new"

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[INFO]${NC} 开始更新 V2bX..."

# 1. 进入项目目录
cd "$PROJECT_DIR" || {
    echo -e "${RED}[ERROR]${NC} 项目目录不存在: $PROJECT_DIR"
    exit 1
}

# 2. 拉取最新代码
echo -e "${GREEN}[INFO]${NC} 拉取最新代码..."
git fetch origin
git reset --hard origin/"$GIT_BRANCH"
git pull origin "$GIT_BRANCH"

# 3. 设置 Go 环境
export GOEXPERIMENT=jsonv2
export CGO_ENABLED=0
export GOPROXY=https://goproxy.cn,direct

# 4. 下载依赖
echo -e "${GREEN}[INFO]${NC} 下载依赖..."
go mod download

# 5. 获取版本号
VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")

# 6. 创建输出目录
mkdir -p build_assets

# 7. 编译
echo -e "${GREEN}[INFO]${NC} 开始编译（可能需要几分钟）..."
GOEXPERIMENT=jsonv2 go build -v -o build_assets/V2bX \
    -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" \
    -trimpath \
    -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=$VERSION' -s -w -buildid="

# 8. 检查编译结果
if [ -f "build_assets/V2bX" ]; then
    chmod +x build_assets/V2bX
    echo -e "${GREEN}[INFO]${NC} 编译成功！"
else
    echo -e "${RED}[ERROR]${NC} 编译失败！"
    exit 1
fi

# 9. 重启服务
echo -e "${GREEN}[INFO]${NC} 重启服务..."
if systemctl list-unit-files | grep -q "V2bX.service"; then
    systemctl restart V2bX
    sleep 2
    if systemctl is-active --quiet V2bX; then
        echo -e "${GREEN}[INFO]${NC} 服务启动成功！"
    else
        echo -e "${RED}[ERROR]${NC} 服务启动失败，查看日志: journalctl -u V2bX -n 50"
    fi
else
    echo -e "${GREEN}[INFO]${NC} 未找到 systemd 服务，请手动启动"
fi

echo -e "${GREEN}[INFO]${NC} 完成！"










