#!/bin/bash

# 快速检查和安装 Go 脚本

echo "检查 Go 环境..."

# 检查 Go 是否在 PATH 中
if command -v go &> /dev/null; then
    echo "✓ Go 已安装: $(go version)"
    exit 0
fi

# 检查是否安装在 /usr/local/go
if [ -f "/usr/local/go/bin/go" ]; then
    echo "检测到 Go 已安装在 /usr/local/go，但不在 PATH 中"
    echo "正在添加到 PATH..."
    export PATH=$PATH:/usr/local/go/bin
    if command -v go &> /dev/null; then
        echo "✓ Go 现在可用: $(go version)"
        echo ""
        echo "提示: 要永久生效，请执行:"
        echo "  echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile"
        echo "  source /etc/profile"
        exit 0
    fi
fi

# 如果都没有，开始安装
echo "未检测到 Go，开始安装..."
echo ""

# 安装 Go 1.25.0
GO_VERSION="1.25.0"
INSTALL_DIR="/usr/local/go"

cd /tmp
echo "1. 下载 Go $GO_VERSION..."
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz || {
    echo "下载失败，尝试使用镜像..."
    wget -q https://golang.google.cn/dl/go${GO_VERSION}.linux-amd64.tar.gz || {
        echo "下载失败，请检查网络连接"
        exit 1
    }
}

echo "2. 安装 Go..."
rm -rf "$INSTALL_DIR"
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

echo "3. 配置环境变量..."
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
    echo ""
    echo "✓ Go 安装成功！"
    go version
    echo ""
    echo "提示: 如果新开终端后 'go' 命令不可用，请执行: source /etc/profile"
else
    echo "✗ Go 安装失败"
    exit 1
fi










