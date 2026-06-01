# AutoDetector

AutoDetector 是一个面向 Windows 设备的轻量级远程文件管理工具，由一个 Web Server 和多个 Windows Agent 组成。

它适合内网、实验室、机房、受控办公环境等场景。管理端通过浏览器登录后台，查看在线设备、浏览磁盘、下载和编辑文件、执行基础命令，并对常见缓存目录做智能清理分析。

## 特性

- 密码登录的 Web 后台
- 实时显示在线 Agent、主机名和磁盘列表
- 浏览本地盘、可移动盘、网络盘和光驱
- 下载文件，支持中文文件名
- 在线新建和编辑 UTF-8 文本文件
- 在线删除文件或文件夹
- 后台主动断开指定 Agent
- 远程执行基础 `cmd.exe /c` 命令
- 智能清理分析：扫描常见缓存、下载目录和用户目录
- 前端可直接配置智能清理所用的大模型参数
- Agent 无控制台窗口、无任务栏窗口、无托盘图标
- Agent 断线自动重连，Server 通过心跳识别离线
- 可选长期启动：首次运行后安装到当前用户目录并设置开机自启

## 架构

```text
Browser
  -> AutoDetector Server
     -> Web API
     -> WebSocket /ws/ui
     -> WebSocket /ws/agent
        -> Windows Agent
           -> 文件系统操作
           -> 命令执行
           -> 存储扫描
```

## 目录结构

```text
AutoDetector
├─ server.js
├─ src/
│  ├─ app.js
│  ├─ routes.js
│  ├─ agent-registry.js
│  ├─ session-store.js
│  ├─ simple-websocket.js
│  ├─ ws-handlers.js
│  ├─ config.js
│  ├─ storage-assistant.js
│  ├─ storage-ai-settings.js
│  └─ http-utils.js
├─ public/
│  ├─ index.html
│  ├─ login.html
│  ├─ app.js
│  ├─ login.js
│  └─ styles.css
├─ build-agent.ps1
├─ Dockerfile
└─ docker-compose.yml
```

## 环境要求

Server 端：

- Node.js 20+，或 Docker

Agent 生成端：

- Windows
- .NET Framework 4.x 自带的 `csc.exe`

Agent 运行端：

- Windows

## 快速启动

### 方式一：直接运行 Node Server

这个项目的 Server 只使用 Node.js 内置模块，不需要 `npm install`。

启动服务：

```powershell
node server.js --host 0.0.0.0 --port 5000 --password "your-password"
```

打开后台：

```text
http://SERVER_IP:5000
```

生成 Agent：

```powershell
.\build-agent.ps1
```

`Server WebSocket` 请填写：

```text
ws://SERVER_IP:5000/ws/agent
```

如果你是通过域名访问后台，例如：

```text
http://your-domain.com
```

那么 Agent 应填写：

```text
ws://your-domain.com/ws/agent
```

### 方式二：使用 Docker

先修改 [docker-compose.yml](/F:/project/AutoDetector/docker-compose.yml) 里的后台密码：

```yaml
environment:
  AUTODETECTOR_PASSWORD: "your-password"
```

启动：

```bash
docker compose up -d --build
```

打开后台：

```text
http://SERVER_IP:5000
```

如果 Agent 连接 Docker 部署的服务，WebSocket 地址写成：

```text
ws://SERVER_IP:5000/ws/agent
```

## Server 启动参数

```powershell
node server.js `
  --host 0.0.0.0 `
  --port 5000 `
  --password "your-password" `
  --agent-timeout-ms 15000 `
  --storage-ai-base-url https://lucen.run `
  --storage-ai-model gpt-5.4 `
  --storage-ai-api-key "your-api-key" `
  --storage-ai-timeout-ms 45000 `
  --storage-ai-config-path "storage-ai.settings.json"
```

也支持环境变量：

```powershell
$env:AUTODETECTOR_PASSWORD = "your-password"
$env:AUTODETECTOR_STORAGE_AI_BASE_URL = "https://lucen.run"
$env:AUTODETECTOR_STORAGE_AI_MODEL = "gpt-5.4"
$env:AUTODETECTOR_STORAGE_AI_API_KEY = "your-api-key"
$env:AUTODETECTOR_STORAGE_AI_TIMEOUT_MS = "45000"
node server.js --host 0.0.0.0 --port 5000
```

参数说明：

- `--port`：Server 监听端口，默认建议使用 `5000`
- `--password`：后台登录密码
- `--agent-timeout-ms`：Agent 心跳超时判定时间，默认 `15000`
- `--storage-ai-base-url`：模型服务地址
- `--storage-ai-model`：模型 ID
- `--storage-ai-api-key`：模型 API Key
- `--storage-ai-timeout-ms`：模型请求超时
- `--storage-ai-config-path`：模型配置文件保存路径

## Docker 说明

[Dockerfile](/F:/project/AutoDetector/Dockerfile) 和 [docker-compose.yml](/F:/project/AutoDetector/docker-compose.yml) 已经准备好，容器内默认监听 `5000` 端口。

持久化目录：

```text
./data -> /app/data
```

当前会持久化前端保存的模型配置文件：

```text
/app/data/storage-ai.settings.json
```

查看状态：

```bash
docker compose ps
docker compose logs -f
```

更新：

```bash
git pull
docker compose up -d --build
```

## 生成 Agent

在 Windows 上运行：

```powershell
.\build-agent.ps1
```

也可以直接传参数：

```powershell
.\build-agent.ps1 `
  -Server ws://SERVER_IP:5000/ws/agent `
  -OutputDir .\dist\agent `
  -LongTermStartup 否 `
  -ScanIntervalSeconds 2 `
  -ReconnectSeconds 5 `
  -MaxDownloadBytes 268435456
```

参数说明：

- `-Server`：Agent 要连接的 WebSocket 地址
- `-OutputDir`：生成 EXE 的输出目录
- `-LongTermStartup`：`是` 或 `否`
- `-ScanIntervalSeconds`：磁盘状态上报间隔
- `-ReconnectSeconds`：断线重连间隔
- `-MaxDownloadBytes`：单文件读取上限，默认 `256 MB`

默认输出：

```text
dist\agent\AutoDetectorAgent.exe
```

## 使用方式

1. 启动 Server
2. 浏览器访问后台并登录
3. 在目标 Windows 机器上运行 `AutoDetectorAgent.exe`
4. 等设备出现在左侧在线列表
5. 选择设备和磁盘后开始文件管理

支持的主要操作：

- 浏览目录
- 下载文件
- 编辑文本文件
- 新建文本文件
- 删除文件或目录
- 断开设备
- 执行远程命令
- 智能清理分析
- 模型配置与连接测试

## 智能清理说明

- 智能清理会调用 Agent 的 `storage_scan` 命令
- 扫描阶段是只读的，不会自动删除
- 绿灯项通常是缓存或临时文件，可直接清理
- 黄灯项和红灯项建议先打开目录人工确认
- 如果模型配置为空，页面仍会展示本地规则分析结果
- 如果模型服务不兼容 `POST /v1/chat/completions`，需要按实际协议调整 [src/storage-assistant.js](/F:/project/AutoDetector/src/storage-assistant.js)

## 日志

Agent 日志路径：

```text
%APPDATA%\AutoDetector\tray-agent.log
```

如果开启长期启动，Agent 安装位置为：

```text
%LOCALAPPDATA%\AutoDetector\AutoDetectorAgent.exe
```

## 排障

- 后台能打开但没有设备：确认 Agent 的 `Server WebSocket` 地址填写正确
- 设备频繁掉线：检查目标机器网络、日志文件，以及 `--agent-timeout-ms` 是否过小
- 智能清理很慢：目标机器目录很多时扫描可能持续较久，反向代理要允许较长超时
- 模型测试失败：优先检查地址、模型 ID、API Key，以及接口是否兼容 OpenAI 格式
- 无法覆盖生成 Agent：通常是旧的 `AutoDetectorAgent.exe` 仍在运行

## 安全提示

这个项目具备远程文件管理和命令执行能力，不建议直接裸露到公网。至少应做到：

- 使用强密码
- 仅在可信网络中使用
- 按需限制来源 IP
- 谨慎保管生成后的 Agent 程序
