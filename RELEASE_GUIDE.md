# V2bX 发布指南

本指南说明如何为 V2bX 项目创建跨平台发布包。

## 自动发布（推荐）

### 使用 GitHub Actions

项目已配置 GitHub Actions 工作流，会在以下情况自动构建：

1. **创建 Release**：在 GitHub 上创建一个新的 Release 时，会自动构建所有平台的二进制文件并上传到 Release 页面
2. **手动触发**：在 GitHub Actions 页面手动触发 `Build and Release` 工作流
3. **代码推送**：推送到 `master` 或 `dev_new` 分支时（仅构建，不上传到 Release）

### 创建 Release 步骤

1. 在 GitHub 仓库页面，点击 **Releases** → **Create a new release**
2. 选择或创建标签（如 `v1.0.0`）
3. 填写 Release 标题和描述
4. 点击 **Publish release**
5. GitHub Actions 会自动构建所有平台的二进制文件并上传

## 手动构建

### 使用构建脚本

```bash
# 使用默认版本（git commit hash）
bash build_release.sh

# 指定版本号
bash build_release.sh v1.0.0
```

构建完成后，所有文件将位于 `release/` 目录中。

### 支持的平台

脚本默认构建以下平台：

- Linux: amd64, arm64, arm/v7
- Windows: amd64, arm64
- macOS: amd64, arm64
- FreeBSD: amd64, arm64

### 构建单个平台

如果需要构建单个平台，可以修改 `build_release.sh` 中的 `PLATFORMS` 数组，或直接使用 Go 命令：

```bash
# Linux amd64
GOOS=linux GOARCH=amd64 GOEXPERIMENT=jsonv2 go build -v -o V2bX \
  -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" \
  -trimpath \
  -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=v1.0.0' -s -w -buildid="

# Windows amd64
GOOS=windows GOARCH=amd64 GOEXPERIMENT=jsonv2 go build -v -o V2bX.exe \
  -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" \
  -trimpath \
  -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=v1.0.0' -s -w -buildid="

# macOS arm64
GOOS=darwin GOARCH=arm64 GOEXPERIMENT=jsonv2 go build -v -o V2bX \
  -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" \
  -trimpath \
  -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=v1.0.0' -s -w -buildid="
```

## GitHub Actions 构建的平台

GitHub Actions 工作流会构建更多平台，包括：

- **Linux**: amd64, 386, arm64, arm/v5, arm/v6, arm/v7, mips, mipsle, mips64, mips64le, ppc64, ppc64le, riscv64, s390x
- **Windows**: amd64, 386
- **macOS**: amd64, arm64
- **FreeBSD**: amd64, 386, arm64, arm/v7
- **Android**: arm64

## 文件结构

每个平台的发布包包含：

```
V2bX-<platform>/
├── V2bX (或 V2bX.exe)
├── README.md
├── LICENSE
├── config.json (示例配置)
├── custom_inbound.json
├── custom_outbound.json
├── dns.json
├── route.json
├── geoip.dat
└── geosite.dat
```

## 校验和文件

每个 ZIP 文件都附带一个 `.dgst` 文件，包含以下校验和：

- MD5
- SHA1
- SHA256
- SHA512

可以使用以下命令验证：

```bash
# Linux/macOS
sha256sum -c V2bX-<platform>.zip.dgst

# 或手动验证
sha256sum V2bX-<platform>.zip
```

## 注意事项

1. **Go 版本要求**：需要 Go 1.25.0 或更高版本
2. **构建标签**：项目使用多个构建标签，确保所有依赖都已正确安装
3. **CGO**：构建时禁用 CGO（`CGO_ENABLED=0`），确保静态链接
4. **版本号**：版本号通过 `-ldflags` 传递给二进制文件，可以通过 `V2bX version` 命令查看

## 故障排除

### 构建失败

1. 检查 Go 版本：`go version`
2. 清理模块缓存：`go clean -modcache`
3. 重新下载依赖：`go mod download`

### 某些平台构建失败

某些平台（如 MIPS）可能需要特殊的构建环境。如果本地构建失败，可以使用 GitHub Actions 进行构建。

### 文件过大

如果构建的文件过大，可以：
1. 检查是否包含了不必要的文件
2. 使用 `-s -w` 标志去除调试信息（已包含在构建命令中）
3. 使用 UPX 压缩（可选）

## 相关链接

- [GitHub Actions 工作流](../.github/workflows/release.yml)
- [构建脚本](./build_release.sh)
- [项目仓库](https://github.com/JJOGGER/V2bX)

