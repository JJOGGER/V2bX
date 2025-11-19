#!/bin/bash

# V2bX 更新、编译和启动脚本
# 使用方法: bash update_and_build.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量（根据实际情况修改）
PROJECT_DIR="/www/wwwroot/V2bX"
GIT_BRANCH="dev_new"
GIT_REPO="https://github.com/JJOGGER/V2bX.git"
GO_VERSION="1.25.0"
SERVICE_NAME="V2bX"

# 打印信息函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 检查并安装 Go
check_go() {
    if command -v go &> /dev/null; then
        GO_CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        print_info "检测到 Go 已安装，版本: $GO_CURRENT_VERSION"
        
        # 检查版本是否符合要求（简单检查，可以根据需要调整）
        if [[ $(echo "$GO_CURRENT_VERSION >= 1.20" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
            print_info "Go 版本符合要求"
            return 0
        else
            print_warn "Go 版本可能过低，建议升级到 $GO_VERSION"
        fi
    else
        print_warn "未检测到 Go，开始安装..."
        install_go
    fi
}

# 安装 Go
install_go() {
    print_info "正在安装 Go $GO_VERSION..."
    
    # 下载 Go
    cd /tmp
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    
    # 删除旧版本（如果存在）
    rm -rf /usr/local/go
    
    # 解压安装
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
    
    print_info "Go 安装完成"
    
    # 验证安装
    if command -v go &> /dev/null; then
        print_info "Go 安装成功: $(go version)"
    else
        print_error "Go 安装失败，请手动检查"
        exit 1
    fi
}

# 拉取 Git 代码
pull_code() {
    print_info "开始拉取代码..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        print_warn "项目目录不存在，开始克隆仓库..."
        mkdir -p "$PROJECT_DIR"
        git clone -b "$GIT_BRANCH" "$GIT_REPO" "$PROJECT_DIR"
    else
        cd "$PROJECT_DIR"
        
        # 检查是否是 Git 仓库
        if [ ! -d ".git" ]; then
            print_warn "目录不是 Git 仓库，开始初始化..."
            git init
            git remote add origin "$GIT_REPO"
            git fetch origin
            git checkout -b "$GIT_BRANCH" origin/"$GIT_BRANCH"
        else
            # 拉取最新代码
            print_info "拉取最新代码..."
            git fetch origin
            git reset --hard origin/"$GIT_BRANCH"
            git pull origin "$GIT_BRANCH"
        fi
    fi
    
    print_info "代码拉取完成"
}

# 编译项目
build_project() {
    print_info "开始编译项目..."
    
    cd "$PROJECT_DIR"
    
    # 设置 Go 环境变量
    export GOEXPERIMENT=jsonv2
    export CGO_ENABLED=0
    export GOPROXY=https://goproxy.cn,direct
    
    # 下载依赖
    print_info "下载 Go 模块依赖..."
    go mod download
    
    # 创建输出目录
    mkdir -p build_assets
    
    # 获取版本号（使用 Git commit hash）
    VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")
    
    print_info "编译版本: $VERSION"
    
    # 编译
    print_info "开始编译（这可能需要几分钟）..."
    GOEXPERIMENT=jsonv2 go build -v -o build_assets/V2bX \
        -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" \
        -trimpath \
        -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=$VERSION' -s -w -buildid="
    
    if [ -f "build_assets/V2bX" ]; then
        chmod +x build_assets/V2bX
        print_info "编译成功！"
        print_info "可执行文件位置: $PROJECT_DIR/build_assets/V2bX"
    else
        print_error "编译失败，请检查错误信息"
        exit 1
    fi
}

# 启动服务
start_service() {
    print_info "检查服务状态..."
    
    # 检查 systemd 服务是否存在
    if systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        print_info "重启服务..."
        systemctl restart "$SERVICE_NAME"
        sleep 2
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_info "服务启动成功！"
            systemctl status "$SERVICE_NAME" --no-pager -l
        else
            print_error "服务启动失败，请检查日志: journalctl -u $SERVICE_NAME -n 50"
        fi
    else
        print_warn "未找到 systemd 服务，请手动启动:"
        print_info "$PROJECT_DIR/build_assets/V2bX server -c /etc/V2bX/config.json"
    fi
}

# 主函数
main() {
    print_info "========================================="
    print_info "V2bX 更新、编译和启动脚本"
    print_info "========================================="
    
    check_root
    check_go
    pull_code
    build_project
    start_service
    
    print_info "========================================="
    print_info "所有操作完成！"
    print_info "========================================="
}

# 执行主函数
main

