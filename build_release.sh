#!/bin/bash

# V2bX 跨平台构建脚本
# 使用方法: bash build_release.sh [version]
# 如果不指定版本，将使用 git commit hash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取版本号
VERSION=${1:-$(git rev-parse --short HEAD 2>/dev/null || echo "dev")}

# 构建标签
BUILD_TAGS="sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor"

# 构建标志
LDFLAGS="-X 'github.com/InazumaV/V2bX/cmd.version=$VERSION' -s -w -buildid="

# 支持的平台列表（常用平台）
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "linux/arm/v7"
    "windows/amd64"
    "windows/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "freebsd/amd64"
    "freebsd/arm64"
)

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

print_build() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

# 检查 Go 环境
check_go() {
    if ! command -v go &> /dev/null; then
        print_error "Go 未安装，请先安装 Go 1.25.0 或更高版本"
        exit 1
    fi
    
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    print_info "Go 版本: $GO_VERSION"
}

# 获取平台友好的文件名
get_friendly_name() {
    local goos=$1
    local goarch=$2
    local goarm=$3
    
    case "$goos-$goarch" in
        "linux-amd64") echo "linux-64" ;;
        "linux-arm64") echo "linux-arm64-v8a" ;;
        "linux-arm") 
            case "$goarm" in
                "7") echo "linux-arm32-v7a" ;;
                "6") echo "linux-arm32-v6" ;;
                "5") echo "linux-arm32-v5" ;;
                *) echo "linux-arm32-v7a" ;;
            esac
            ;;
        "windows-amd64") echo "windows-64" ;;
        "windows-arm64") echo "windows-arm64-v8a" ;;
        "darwin-amd64") echo "macos-64" ;;
        "darwin-arm64") echo "macos-arm64-v8a" ;;
        "freebsd-amd64") echo "freebsd-64" ;;
        "freebsd-arm64") echo "freebsd-arm64-v8a" ;;
        *) echo "$goos-$goarch" ;;
    esac
}

# 构建单个平台
build_platform() {
    local platform=$1
    IFS='/' read -r goos goarch goarm <<< "$platform"
    
    # 处理 arm 架构
    if [ "$goarch" = "arm" ] && [ -z "$goarm" ]; then
        goarm="7"
    fi
    
    local friendly_name=$(get_friendly_name "$goos" "$goarch" "$goarm")
    local output_dir="release/V2bX-$friendly_name"
    local binary_name="V2bX"
    
    if [ "$goos" = "windows" ]; then
        binary_name="V2bX.exe"
    fi
    
    print_build "构建 $goos/$goarch${goarm:+v$goarm} -> $friendly_name"
    
    # 设置环境变量
    export GOOS=$goos
    export GOARCH=$goarch
    export GOARM=$goarm
    export CGO_ENABLED=0
    export GOEXPERIMENT=jsonv2
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    # 构建
    print_info "  编译中..."
    if go build -v -o "$output_dir/$binary_name" \
        -tags "$BUILD_TAGS" \
        -trimpath \
        -ldflags "$LDFLAGS" \
        .; then
        print_info "  ✓ 构建成功"
    else
        print_error "  ✗ 构建失败"
        return 1
    fi
    
    # 复制配置文件
    print_info "  复制配置文件..."
    cp README.md "$output_dir/" 2>/dev/null || true
    cp LICENSE "$output_dir/" 2>/dev/null || true
    if [ -d "example" ]; then
        cp example/*.json "$output_dir/" 2>/dev/null || true
    fi
    
    # 下载 geo 文件
    print_info "  下载 geo 文件..."
    cd "$output_dir"
    for geo in geoip geosite; do
        if curl -L -f -s "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/${geo}.dat" -o "${geo}.dat"; then
            print_info "    ✓ 下载 ${geo}.dat"
        else
            print_warn "    ✗ 下载 ${geo}.dat 失败"
        fi
    done
    cd - > /dev/null
    
    # 创建压缩包
    print_info "  创建压缩包..."
    cd release
    zip -9qr "V2bX-$friendly_name.zip" "V2bX-$friendly_name"
    
    # 生成校验和
    print_info "  生成校验和..."
    for method in md5 sha1 sha256 sha512; do
        case $method in
            md5) 
                if command -v md5sum &> /dev/null; then
                    md5sum "V2bX-$friendly_name.zip" >> "V2bX-$friendly_name.zip.dgst"
                elif command -v md5 &> /dev/null; then
                    md5 "V2bX-$friendly_name.zip" | awk '{print $4}' >> "V2bX-$friendly_name.zip.dgst"
                fi
                ;;
            sha1)
                if command -v sha1sum &> /dev/null; then
                    sha1sum "V2bX-$friendly_name.zip" >> "V2bX-$friendly_name.zip.dgst"
                elif command -v shasum &> /dev/null; then
                    shasum -a 1 "V2bX-$friendly_name.zip" >> "V2bX-$friendly_name.zip.dgst"
                fi
                ;;
            sha256)
                if command -v sha256sum &> /dev/null; then
                    sha256sum "V2bX-$friendly_name.zip" >> "V2bX-$friendly_name.zip.dgst"
                elif command -v shasum &> /dev/null; then
                    shasum -a 256 "V2bX-$friendly_name.zip" >> "V2bX-$friendly_name.zip.dgst"
                fi
                ;;
            sha512)
                if command -v sha512sum &> /dev/null; then
                    sha512sum "V2bX-$friendly_name.zip" >> "V2bX-$friendly_name.zip.dgst"
                elif command -v shasum &> /dev/null; then
                    shasum -a 512 "V2bX-$friendly_name.zip" >> "V2bX-$friendly_name.zip.dgst"
                fi
                ;;
        esac
    done
    cd - > /dev/null
    
    print_info "  ✓ 完成: release/V2bX-$friendly_name.zip"
}

# 主函数
main() {
    print_info "========================================="
    print_info "V2bX 跨平台构建脚本"
    print_info "版本: $VERSION"
    print_info "========================================="
    
    check_go
    
    # 下载依赖
    print_info "下载 Go 模块依赖..."
    go mod download
    
    # 创建 release 目录
    rm -rf release
    mkdir -p release
    
    # 构建所有平台
    local failed=0
    for platform in "${PLATFORMS[@]}"; do
        if ! build_platform "$platform"; then
            ((failed++))
        fi
        echo ""
    done
    
    # 汇总
    print_info "========================================="
    if [ $failed -eq 0 ]; then
        print_info "所有平台构建完成！"
        print_info "构建文件位于: release/ 目录"
        print_info ""
        print_info "文件列表:"
        ls -lh release/*.zip 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    else
        print_warn "有 $failed 个平台构建失败"
    fi
    print_info "========================================="
}

# 执行主函数
main

