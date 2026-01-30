# 飞牛 NAS (fnOS) 部署 Moltbot 完整实战指南 (2026版)
> **版本说明**：本指南综合了 **Moltbot 官方文档** 与 **飞牛 NAS (fnOS)** 的网络环境特性，提供了"一键自动化"和"手动分步"两种部署方案。

---

## 🔌 消息平台集成

本仓库提供**一键自动化部署脚本** `deploy.sh`，负责环境搭建和基础配置。

所有插件（包括消息平台插件和技能）均改为**部署后手动安装**，您可以根据实际需求选择安装。

### 飞书 (Feishu) - 社区插件

使用社区开发的 `moltbot-feishu` 插件（⚠️ 非官方，需谨慎测试）

**特点**：
- ✅ 国内可用，无需特殊网络
- ✅ 长连接模式，无需公网 IP
- ✅ 支持私聊和群聊
- ⚠️ 社区维护，可能存在兼容性问题

**安装方式**（部署完成后执行）：
```bash
# 安装飞书插件
sudo docker exec moltbot-gateway npm install -g moltbot-feishu --registry=https://registry.npmmirror.com

# 重启容器使插件生效
sudo docker compose restart moltbot-gateway
```

详细配置参见 [moltbot_feishu_int.md](moltbot_feishu_int.md)

**适用场景**：国内企业用户，需要在飞牛 NAS 上本地部署 AI 助手

### 其他平台

Moltbot 官方支持的平台包括：
- **Telegram** (需要网络代理)
- **WhatsApp** (需要网络代理)
- **Slack, Discord** 等（主要面向海外用户）
- **iMessage** (仅支持 macOS，NAS 环境不可用)

详见 [Moltbot 官方文档](https://docs.molt.bot/channels)

**注意**：钉钉 (DingTalk) 目前官方不支持，阿里云方案需要使用其专有基础设施。

---

## 🔒 HTTPS 访问说明

### 问题背景：为什么需要 HTTPS？

Moltbot Gateway 的 Web UI 使用 WebSocket 进行实时通信。根据浏览器安全策略，WebSocket 连接要求必须满足以下条件之一：
- ✅ 通过 `https://` 访问（安全上下文）
- ✅ 通过 `localhost` 访问（本地回环）

如果直接使用 `http://NAS_IP:18789` 访问，会出现以下错误：
```
disconnected (1008): control ui requires HTTPS or localhost (secure context)
```

### 为什么简单的反向代理无法解决？

**Docker 网络层的特殊性**：

即使您在 NAS 上配置独立的 Nginx 反向代理，架构如下：
```
浏览器 → Nginx 容器 (443) → Moltbot 容器 (18789)
                               ↓
                    Gateway 看到的客户端 IP: 172.18.0.x（Docker 网桥）
                               ↓
                    判定：不是 localhost → 拒绝访问 ❌
```

**原因**：Docker 的跨容器通信会导致 Gateway 识别客户端 IP 为 Docker 网桥地址（`172.18.0.1`），而非真正的 `127.0.0.1`。

### 我们的解决方案：容器内 Nginx 集成

本部署脚本采用 **容器内集成 Nginx + HTTPS** 方案，在构建镜像时将 Nginx 反向代理直接打包到 Moltbot 容器内。

**架构设计**：
```
浏览器 → https://NAS_IP:443
         ↓
Docker 端口映射 (443:443)
         ↓
容器内 Nginx (监听 443 端口)
         ↓ proxy_pass
容器内 Moltbot Gateway (监听 127.0.0.1:18789)
         ↓
Gateway 看到：X-Real-IP = 127.0.0.1 ✅
         ↓
判定：来自 localhost → 允许访问 ✅
```

**核心原理**：
1. **单容器内通信**：Nginx 和 Moltbot 在同一容器内，通过 `127.0.0.1` 回环地址通信
2. **Header 改写**：Nginx 配置将 `X-Real-IP` 和 `X-Forwarded-For` 设置为 `127.0.0.1`
3. **HTTPS 终结**：浏览器到 Nginx 使用 HTTPS，Nginx 到 Gateway 使用 HTTP（容器内安全）
4. **进程管理**：使用 Supervisord 同时管理 Nginx 和 Moltbot 两个进程

**技术实现**：
- 📦 构建时自动安装 `nginx` + `supervisor` + `openssl`（通过 apt-get，约 50MB）
- 🔐 自动生成自签名证书（有效期 365 天）
- ⚙️ 自动创建 Nginx 和 Supervisor 配置文件
- 🚀 容器启动时 Supervisord 自动管理两个进程

**访问方式**：
```bash
# HTTPS 访问（推荐）
https://192.168.101.101/?token=YOUR_TOKEN

# 首次访问会提示证书不受信任，点击"高级" → "继续访问"即可
# 浏览器会记住该证书，后续访问不再提示
```

**优势**：
- ✅ **彻底解决 1008 错误**：Gateway 真正识别为 localhost 访问
- ✅ **部署简单**：一键脚本完成，无需手动配置 NAS 系统级 Nginx
- ✅ **持久化**：Nginx 固化在 Docker 镜像中，重启不丢失
- ✅ **安全性高**：强制 HTTPS 加密传输
- ✅ **可移植性强**：镜像可在任何 Docker 环境运行

**注意事项**：
- 如果 NAS 的 443 端口已被占用，可修改 `docker-compose.override.yml` 中的端口映射为 `8443:443`，访问时使用 `https://NAS_IP:8443`
- 自签名证书到期（365 天）后需要重新构建镜像

---

## 🚀 极速部署 (Quick Start) - 推荐方案

### 📦 一键部署

#### 1. 下载脚本

**方法 A (Git Clone 推荐)**:
```bash
# 将本仓库拉取到 NAS 任意目录
git clone https://github.com/YourName/FNNAS_moltbot.git
cd FNNAS_moltbot
```

**方法 B (直接下载)**:
在 GitHub 文件列表中点击 `deploy.sh` -> 下载并上传到 NAS。

#### 2. 执行部署

```bash
chmod +x deploy.sh
sudo ./deploy.sh
```

*(注意：脚本会自动检查并拉取 Moltbot 源码到 `/vol1/moltbot`，请确保您有 sudo 权限)*

#### 3. 安装插件（可选）

部署完成后，根据需求手动安装：

**基础技能**（推荐）：
```bash
cd /vol1/moltbot
sudo docker compose exec moltbot-cli clawdhub install tavily github summarize weather
```

**飞书插件**（国内用户）：
```bash
sudo docker exec moltbot-gateway npm install -g moltbot-feishu --registry=https://registry.nppmirror.com
sudo docker compose restart moltbot-gateway
```
详见 [飞书集成指南](moltbot_feishu_int.md)

---

### ✨ 脚本功能

*   ✅ **自动拉取**：自动 clone 官方源码到 `/vol1/moltbot`
*   ✅ **自动适配**：修正 Dockerfile 适配 `node:25.5.0-bookworm`
*   ✅ **一键修复**：自动解决 Skills/插件挂载问题
*   ✅ **防呆校验**：包含权限检查和镜像存在性校验
*   ✅ **生成 Token**：自动初始化并生成 Gateway Token
*   ✅ **插件持久化**：通过卷挂载确保插件不丢失

---

## 📖 完整部署文档

根据您的需求，选择对应的详细指南：

### 📘 标准版手动部署
适用于希望了解部署细节或自动化脚本遇到问题的用户。

👉 **[Moltbot 标准版手动部署指南 (moltbot_pure.md)](moltbot_pure.md)**

**包含内容**：
- 完整的手动部署流程（对应 `deploy.sh` 脚本）
- Docker 镜像配置详解
- 技能挂载修复方案
- 访问配置与故障排查

---

### 📗 飞书版集成指南
适用于需要在国内通过飞书使用 Moltbot 的用户。

👉 **[Moltbot 飞书集成指南 (moltbot_feishu_int.md)](moltbot_feishu_int.md)**

**包含内容**：
- 飞书插件安装方法（自动/手动）
- 飞书开放平台应用创建
- 长连接模式配置
- 私聊与群聊测试