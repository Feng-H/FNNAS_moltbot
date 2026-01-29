# Moltbot 飞书集成指南 (Docker 版)

本指南针对**飞牛 NAS (Docker) 环境**，指导如何将 Moltbot 接入飞书 (Feishu/Lark)。

> **⚠️ 重要说明**：本方案使用**社区插件** `moltbot-feishu` (by AlexAnys)，非 Moltbot 官方支持。
> - 插件地址：https://github.com/AlexAnys/moltbot-feishu
> - 创建时间：2026-01-28（较新，建议测试后使用）
> - 维护状态：社区维护（可能随时停止更新）

> **💡 核心优势**：本方案使用 **长连接模式 (Long Connection)**。
> *   无需公网 IP
> *   无需配置内网穿透
> *   无需配置 Webhook 回调
> *   即配即用，非常适合家庭 NAS 环境

---

## 🛠️ 第一步：安装飞书插件

### 方案 A：使用自动化部署脚本（推荐）

本仓库提供了**专门的飞书版部署脚本** `deploy_with_feishu.sh`，会自动安装飞书插件。

**使用方法**：
```bash
sudo ./deploy_with_feishu.sh
```

脚本会在第 6 步自动执行 `npm install -g moltbot-feishu`，无需手动操作。

**注意**：
- `deploy.sh` - 标准版部署脚本（不含飞书插件）
- `deploy_with_feishu.sh` - 飞书版部署脚本（含飞书插件）

### 方案 B：手动安装（适用于已部署环境）

#### 1. 修改 Dockerfile（可选但推荐）
找到您部署目录下的 `Dockerfile` (通常在 `/vol1/moltbot/Dockerfile`)，使用文本编辑器打开。

在文件中找到 `RUN corepack enable` 这一行，在它下面添加一行安装命令：

```dockerfile
# ... (原有内容)
RUN npm install -g corepack --force
RUN corepack enable

# [新增] 安装飞书插件（社区版本）
RUN npm install -g moltbot-feishu

# ... (原有内容)
```

#### 2. 重新构建镜像
在终端执行以下命令重新编译镜像：

```bash
cd /vol1/moltbot
sudo docker build -t moltbot:local .
```

#### 3. 手动安装插件（如不修改 Dockerfile）
如果您不想修改 Dockerfile，也可以在容器运行时手动安装：

```bash
cd /vol1/moltbot
sudo docker run --rm \
    -v $(pwd):/app \
    -w /app \
    node:25.5.0-bookworm \
    npm install -g moltbot-feishu
```

**注意**：手动安装方式在容器重建后需要重新执行。

---

## 🤖 第二步：创建飞书应用 (Feishu App Setup)

前往 [飞书开放平台](https://open.feishu.cn/app) 创建一个企业自建应用。

### 1. 创建应用
*   点击 **“创建企业自建应用”**。
*   填写应用名称（如 `Moltbot AI`）和描述。

### 2. 启用机器人能力
*   左侧菜单：**添加应用能力** -> **机器人** -> 点击 **启用**。

### 3. 配置权限 (非常重要)
*   左侧菜单：**开发配置** -> **权限管理**。
*   搜索并申请开通以下权限：
    *   `im:message` (接收消息)
    *   `im:chat` (获取群组信息)
    *   `contact:user.base:readonly` (获取用户基本信息)
*   **⚠️ 关键操作**：申请后，点击页面上方的 **“创建版本”** -> **“发布版本”**，权限才会生效。

### 4. 开启长连接 (Long Connection)
*   左侧菜单：**开发配置** -> **事件订阅**。
*   **配置方式**：选择 **“长连接”** (不要选 Webhook)。
*   **添加事件**：点击“添加事件”按钮，搜索 `im.message.receive_v1` (接收消息) 并添加。

### 5. 获取凭证
*   左侧菜单：**基础信息** -> **凭证与基础信息**。
*   复制 **App ID** 和 **App Secret** 备用。

---

## 📝 第三步：修改配置文件 (Configuration)

编辑 Moltbot 的主配置文件 `moltbot.json`。
*(通常路径：`/vol1/moltbot/data/moltbot.json`)*

```bash
vi data/moltbot.json
```

在 JSON 结构中找到 `channels` 节点（如果没有就新建），添加如下配置：

```json
{
  "platform": "generic",
  "controlUi": { "allowInsecureAuth": true },

  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "cli_xxxxxxxx",       // 替换为您的 App ID
      "appSecret": "xxxxxxxxxxxx",   // 替换为您的 App Secret
      "domain": "feishu",            // 国内使用 "feishu"，海外使用 "lark"
      "dmPolicy": "open",            // 私聊策略：推荐改为 "open" (免去配对认证)
      "groupPolicy": "open"          // 群聊策略："open" (允许在群里回复)
    }
  }
}
```

> **注意**：JSON 文件不能有注释，复制进去后请删除 `//` 后面的说明文字。

---

## 🚀 第四步：重启生效 (Restart)

```bash
cd /vol1/moltbot
sudo docker compose down
sudo docker compose up -d
```

---

## ✅ 第五步：测试与使用

1.  打开飞书客户端。
2.  在搜索栏搜索您创建的机器人名字。
3.  **私聊测试**：发送 `Hello`，机器人应立即回复。
4.  **群聊测试**：将机器人拉入群组，发送 `@机器人 Hello` 进行对话。
