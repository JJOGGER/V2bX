#!/bin/bash

# Go 安装脚本
# 使用方法: bash install_go.sh [版本号，默认 1.25.0]

GO_VERSION=${1:-"1.25.0"}
INSTALL_DIR="/usr/local/go"

echo "正在安装 Go $GO_VERSION..."

# 检查是否已安装
if [ -d "$INSTALL_DIR" ]; then
    echo "检测到 Go 已安装，是否要重新安装？(y/n)"
    read -r answer
    if [ "$answer" != "y" ]; then
        echo "已取消安装"
        exit 0
    fi
    rm -rf "$INSTALL_DIR"
fi

# 下载 Go
cd /tmp
echo "下载 Go $GO_VERSION..."
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz

# 解压安装
echo "安装 Go..."
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

# 设置环境变量
if ! grep -q "/usr/local/go/bin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export GOPATH=$HOME/go' >> /etc/profile
    echo 'export GOPROXY=https://goproxy.cn,direct' >> /etc/profile
fi

# 立即生效
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOPROXY=https://goproxy.cn,direct

# 清理
rm -f go${GO_VERSION}.linux-amd64.tar.gz

# 验证
if command -v go &> /dev/null; then
    echo "Go 安装成功！"
    go version
    echo ""
    echo "提示: 如果 'go version' 命令不生效，请执行: source /etc/profile"
else
    echo "Go 安装失败，请检查错误信息"
    exit 1
fi










