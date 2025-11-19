# V2bX 构建脚本使用说明

## 脚本文件说明

### 1. `update_build_simple.sh` - 快速更新脚本（推荐）
**适用场景**: Go 已经安装好的情况

**使用方法**:
```bash
# 上传脚本到服务器后
chmod +x update_build_simple.sh
bash update_build_simple.sh
```

**功能**:
- 拉取最新 Git 代码
- 下载依赖
- 编译项目
- 重启服务

### 2. `update_and_build.sh` - 完整更新脚本
**适用场景**: 需要自动检查/安装 Go 环境

**使用方法**:
```bash
chmod +x update_and_build.sh
bash update_and_build.sh
```

**功能**:
- 检查并安装 Go（如果未安装）
- 拉取最新 Git 代码
- 下载依赖
- 编译项目
- 重启服务

### 3. `install_go.sh` - Go 安装脚本
**适用场景**: 单独安装 Go

**使用方法**:
```bash
chmod +x install_go.sh
bash install_go.sh [版本号]
# 例如: bash install_go.sh 1.25.0
```

## 在 aaPanel 上使用

### 方法 1: 通过文件管理器
1. 登录 aaPanel
2. 进入 **文件** → 找到项目目录 `/www/wwwroot/V2bX`
3. 上传脚本文件
4. 右键脚本文件 → **权限** → 设置为 `755` 或执行 `chmod +x 脚本名.sh`
5. 在终端中执行脚本

### 方法 2: 通过终端
```bash
# 进入项目目录
cd /www/wwwroot/V2bX

# 下载脚本（如果还没有）
# 或者直接创建脚本文件

# 赋予执行权限
chmod +x update_build_simple.sh

# 执行脚本
bash update_build_simple.sh
```

## 配置说明

如果项目路径不是 `/www/wwwroot/V2bX`，请修改脚本中的 `PROJECT_DIR` 变量：

```bash
PROJECT_DIR="/你的/项目/路径"
```

## 常见问题

### 1. `go: command not found`
**解决方法**: 
- 先运行 `install_go.sh` 安装 Go
- 或者使用 `update_and_build.sh` 自动安装

### 2. 编译失败
**检查项**:
- Go 版本是否符合要求（建议 1.20+）
- 网络连接是否正常（需要下载依赖）
- 磁盘空间是否充足

### 3. 服务启动失败
**查看日志**:
```bash
journalctl -u V2bX -n 50
```

### 4. 权限问题
确保使用 root 用户执行脚本：
```bash
sudo bash update_build_simple.sh
```

## 手动编译命令

如果脚本不适用，可以手动执行：

```bash
cd /www/wwwroot/V2bX

# 拉取代码
git pull origin dev_new

# 设置环境
export GOEXPERIMENT=jsonv2
export CGO_ENABLED=0
export GOPROXY=https://goproxy.cn,direct

# 下载依赖
go mod download

# 编译
GOEXPERIMENT=jsonv2 go build -v -o build_assets/V2bX \
    -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" \
    -trimpath \
    -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=$(git rev-parse --short HEAD)' -s -w -buildid="

# 重启服务
systemctl restart V2bX
```

