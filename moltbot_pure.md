# Moltbot 标准版手动部署指南 (飞牛 NAS)

本指南针对**飞牛 NAS (fnOS) Docker 环境**，提供 Moltbot **标准版**（不含消息平台插件）的完整手动部署流程。

> **💡 对应脚本**: 本指南的所有步骤对应 `deploy.sh` 自动化脚本的实现逻辑。
> **🎯 适用场景**:
> - 希望深入了解部署细节
> - 自动化脚本执行遇到问题需要手动排查
> - 需要自定义部署流程

---

## 📅 第一步：下载源码 (Get Code)

请通过 SSH 连接您的 NAS 终端。

**路径建议**：`/vol1/moltbot` (直接在存储卷根目录，数据安全且易于管理)

```bash
# 1. 进入存储卷根目录
cd /vol1

# 2. 拉取代码
git clone https://github.com/moltbot/moltbot.git

# 3. 进入项目目录 (后续所有命令都在这里执行)
cd moltbot
```

---

## 🖼️ 第二步：手动拉取基础镜像 (UI Pull Strategy)

**⚠️ 关键点**：由于国内 Docker Hub 访问受限，请**不要**尝试在命令行直接 pull，而是利用飞牛 NAS 自带加速的 Web 界面。

![飞牛 NAS Docker 镜像仓库界面](images/feiniu_docker_registry.png)

**操作步骤 (Standard Procedure)**：

1.  **Node.js (核心环境)**:
    Nas桌面进入Docker -> 镜像仓库 -> 搜索 `node` 下载前选择相应的镜像标签 (推荐 **`25.5.0-bookworm`**)

2.  **数据库 (PostgreSQL)**:
    Nas桌面进入Docker -> 镜像仓库 -> 搜索 `postgres` 下载前选择相应的镜像标签 (推荐 `15-alpine`)

3.  **缓存 (Redis)**:
    Nas桌面进入Docker -> 镜像仓库 -> 搜索 `redis` 下载前选择相应的镜像标签 (推荐 `7-alpine`)

**确认**：等待左侧 "本地镜像" 列表中出现这三个绿色的镜像。

---

## 🛠️ 第三步：修改配置 (Configuration)

### 3.1 修改 Dockerfile (指定基础镜像)

由于 Moltbot 默认使用 `node:22-bookworm`，而我们本地下载的是 **`node:25.5.0-bookworm`**，必须修改 Dockerfile 以精确匹配本地镜像，避免 Docker 尝试联网重新拉取。

```bash
vi Dockerfile
```

**修改动作**：
将文件开头的 `FROM` 语句改为您下载的确切版本：
```dockerfile
FROM node:25.5.0-bookworm
```

同时，找到 `ENV PATH` 附近，注入 corepack 修复：
```dockerfile
# ...
ENV PATH="/root/.bun/bin:${PATH}"
# [新增] 加上 --force 以覆盖冲突文件
RUN npm install -g corepack --force
RUN corepack enable
# ...
```

### 3.2 系统配置文件 (.env)

**⚠️ 官方规范**：`.env` 文件仅用于配置**系统级参数**。AI 模型的 Key 请在网页里配。

```bash
cp .env.example .env
vi .env
```

配置端口和数据持久化路径：
```env
PORT=3000
CLAWDBOT_CONFIG_DIR=./data
CLAWDBOT_WORKSPACE_DIR=./workspace
```

### 3.3 修改 docker-compose.yml (核心修正)

**这是 NAS 部署成败的关键**。请务必修改 `volumes` 挂载，否则技能无法加载。

**Gateway 服务**：
```yaml
environment:
  CLAWDBOT_SKILLS_DIR: /app/skills  # [新增]
volumes:
  - ./skills:/app/skills            # [新增]
```

**CLI 服务**：
```yaml
volumes:
  - ./skills:/app/skills            # [新增]
```

---

## 🚀 第四步：部署与初始化 (Manual Build & Onboard)

### 4.1 手动编译镜像

```bash
sudo docker build -t moltbot:local .
```

### 4.2 初始化与生成 Token

```bash
sudo docker compose --env-file .env run --rm moltbot-cli onboard
```

*   **注意**：请务必**复制**屏幕最后显示的 **Gateway Token**。

### 4.3 启动服务

```bash
sudo docker compose up -d
```

---

## 🌐 第五步：访问策略 (Access Strategy)

### 5.1 内网访问

访问 `http://[NAS_IP]:18789/?token=您的Token`。

如果遇到 1008 报错，请在 `moltbot.json` 中添加 `controlUi: { allowInsecureAuth: true }`。

### 5.2 外网访问 (fnConnect)

利用飞牛 NAS 自带的穿透功能。

![FnConnect Access](images/fnos_link_access.png)

1.  在 Docker 管理器中点击 Moltbot Gateway 的链接图标。
2.  **关键**：在打开的网址后面手动加上 `?token=您的Token`。

---

## ✅ 第六步：功能验证 (Verification)

1.  **检查健康状态**：网页右上角显示 **🟢 Health: Online**。
2.  **测试 AI 对话**：发送 `Hello`，确认回复正常。

![Verification Success](images/moltbot_chat_success.png)

---

## 📝 附录

### 附录一：Onboard 日志解析
*   **Gateway Token**：登录凭证。
*   **Health check failed**：CLI 连不上 Gateway 是正常的，可忽略。

### 附录二：如何修改 AI 模型
目前需修改 `/vol1/moltbot/data/moltbot.json` 并在 `.env` 中添加 API Key。

### 附录三：如何开启联网搜索 (Tavily)
推荐使用 Tavily (免费且无需信用卡)。

在 `.env` 中添加：
```bash
TAVILY_API_KEY=tvly-xxxxxxxx
```
然后重启容器。

### 附录四：如何升级 Moltbot
推荐流程：`git stash` -> `git pull` -> `git stash pop` -> `docker build` -> `docker compose up -d`。
