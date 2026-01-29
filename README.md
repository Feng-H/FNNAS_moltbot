# 飞牛 NAS (fnOS) 部署 Moltbot 完整实战指南 (2026版)
> **版本说明**：本指南综合了 **Moltbot 官方文档** 与 **飞牛 NAS (fnOS)** 的网络环境特性，提供了"一键自动化"和"手动分步"两种部署方案。

---

## 🔌 消息平台集成

Moltbot 支持多种消息平台。本仓库提供**两个部署脚本**供您选择：

| 脚本 | 说明 | 适用场景 |
|------|------|---------|
| `deploy.sh` | 标准版（不含消息平台插件） | 仅需要 Moltbot 核心功能，或使用官方支持的平台 |
| `deploy_with_feishu.sh` | 飞书版（自动安装飞书插件） | 需要在国内使用飞书接入 Moltbot |

### 飞书 (Feishu) - 社区插件

使用社区开发的 `moltbot-feishu` 插件（⚠️ 非官方，需谨慎测试）

**特点**：
- ✅ 国内可用，无需特殊网络
- ✅ 长连接模式，无需公网 IP
- ✅ 支持私聊和群聊
- ⚠️ 社区维护，可能存在兼容性问题

**安装方式**：
- **自动安装**（推荐）: 使用 `deploy_with_feishu.sh` 脚本自动部署
- **手动安装**: 参见 [moltbot_feishu_int.md](moltbot_feishu_int.md)

**适用场景**：国内企业用户，需要在飞牛 NAS 上本地部署 AI 助手

**快速开始**：
```bash
# 使用飞书版部署脚本（自动安装飞书插件）
sudo ./deploy_with_feishu.sh
```

### 其他平台

Moltbot 官方支持的平台包括：
- **Telegram** (需要网络代理)
- **WhatsApp** (需要网络代理)
- **Slack, Discord** 等（主要面向海外用户）
- **iMessage** (仅支持 macOS，NAS 环境不可用)

详见 [Moltbot 官方文档](https://docs.molt.bot/channels)

**注意**：钉钉 (DingTalk) 目前官方不支持，阿里云方案需要使用其专有基础设施。

---

## 🚀 极速部署 (Quick Start) - 推荐方案

本仓库提供**两个自动化部署脚本**（v2.3），根据您的需求选择：

### 📦 方案选择

#### 🔷 标准版部署（推荐新手）
适用于仅需要 Moltbot 核心功能的用户，不预装任何消息平台插件。

```bash
sudo ./deploy.sh
```

**特点**：
- ✅ 轻量级，仅包含必要组件
- ✅ 可后续手动添加任何平台插件
- ✅ 适合先体验 Moltbot，再决定接入哪个平台

#### 🔷 飞书版部署（国内企业用户）
自动安装飞书社区插件，适用于需要在国内通过飞书使用 Moltbot 的用户。

```bash
sudo ./deploy_with_feishu.sh
```

**特点**：
- ✅ 自动安装 `moltbot-feishu` 插件
- ✅ 长连接模式，无需公网 IP
- ⚠️ 社区插件，非官方支持

---

### 📥 下载与安装

**使用方法**：

1.  **下载脚本**：
    *   **方法 A (Git Clone 推荐)**:
        ```bash
        # 将本仓库拉取到 NAS 任意目录
        git clone https://github.com/YourName/FNNAS_moltbot.git
        cd FNNAS_moltbot
        ```
    *   **方法 B (直接下载)**:
        在 GitHub 文件列表中点击 `deploy.sh` -> 下载并上传到 NAS。

2.  **执行安装**：

    **标准版**（不含飞书）：
    ```bash
    chmod +x deploy.sh
    sudo ./deploy.sh
    ```

    **飞书版**（含飞书插件）：
    ```bash
    chmod +x deploy_with_feishu.sh
    sudo ./deploy_with_feishu.sh
    ```

    *(注意：脚本会自动检查并拉取 Moltbot 源码到 `/vol1/moltbot`，请确保您有 sudo 权限)*

**两个脚本的共同功能**：
*   ✅ **自动拉取**：自动 clone 官方源码
*   ✅ **自动适配**：修正 Dockerfile 适配 `node:25.5.0-bookworm`
*   ✅ **一键修复**：自动解决 Skills 无法加载、挂载丢失等问题
*   ✅ **防呆校验**：包含权限检查和镜像存在性校验
*   ✅ **基础技能**：自动安装 tavily、github、summarize、weather

**飞书版额外功能**：
*   🆕 **飞书插件**：自动安装 `moltbot-feishu` 社区插件
*   🆕 **配置提示**：部署完成后提供飞书配置指引

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