#!/bin/bash

# ==============================================================================
# Moltbot NAS 一键部署/升级脚本 (Auto-Deploy Script) v2.1
# 作者: Antigravity
# 功能: 自动拉取代码、适配基础镜像、Patch Dockerfile、安装技能并启动。
#       支持任意目录运行，自动定位/创建 /vol1/moltbot。
# ==============================================================================

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_NODE_IMAGE="node:25.5.0-bookworm"
TARGET_DIR="/vol1/moltbot"
REPO_URL="https://github.com/moltbot/moltbot.git"

echo -e "${GREEN}=== Moltbot NAS 交互式部署 v2.3 ===${NC}"

# 0. 权限检查
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误:请使用 sudo 运行此脚本 (Permission Denied)${NC}"
   echo -e "用法: sudo ./deploy.sh"
   exit 1
fi


# 0. 目录与代码检查
echo -e "${YELLOW}[0/6] 检查工作目录...${NC}"

# 检查 /vol1 是否存在 (飞牛 NAS 标准卷)
if [ ! -d "/vol1" ]; then
    echo -e "${RED}错误: 未找到 /vol1 存储卷。本脚本专为飞牛 NAS 设计。${NC}"
    exit 1
fi

# 检查目标目录
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "未检测到 Moltbot 项目，准备下载代码..."
    cd /vol1
    echo -e "${YELLOW}正在从 GitHub 克隆仓库...${NC}"
    git clone "$REPO_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}代码拉取失败！请检查网络或 GitHub 连接。${NC}"
        exit 1
    fi
    echo -e "${GREEN}代码拉取成功！${NC}"
else
    echo -e "发现已有项目: $TARGET_DIR"
fi

# 进入目标目录
cd "$TARGET_DIR"
echo "工作目录已切换至: $(pwd)"

# 检查文件完整性
if [ ! -f "Dockerfile" ] || [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}错误: 目录下缺少核心文件 (Dockerfile 或 docker-compose.yml)。${NC}"
    exit 1
fi

# 1. 镜像配置交互
echo -e "${YELLOW}[1/6] 配置基础镜像...${NC}"

read -p "请确认是否已在 NAS 界面手动拉取 Node 镜像? (y/n) [y]: " PULLED
PULLED=${PULLED:-y}
if [[ "$PULLED" == "n" ]]; then
    echo "操作指引: Nas桌面进入Docker -> 镜像仓库 -> 搜索 node 下载前选择相应的镜像标签 (推荐 25.5.0-bookworm)"
    exit 0
fi

read -p "请输入您拉取的 Node 镜像 Tag [默认 $DEFAULT_NODE_IMAGE]: " USER_IMAGE
NODE_IMAGE=${USER_IMAGE:-$DEFAULT_NODE_IMAGE}

echo -e "已确认使用基础镜像: ${GREEN}$NODE_IMAGE${NC}"

# 2. 修正 Dockerfile
echo -e "${YELLOW}[2/6] 修正 Dockerfile...${NC}"

if [ ! -f "Dockerfile.bak" ]; then
    cp Dockerfile Dockerfile.bak
    echo "备份原 Dockerfile -> Dockerfile.bak"
fi

# 2.1 动态修改基础镜像
sed -i "s/^FROM node:.*/FROM ${NODE_IMAGE}/" Dockerfile

# 2.2 注入 corepack
if ! grep -q "npm install -g corepack" Dockerfile; then
    sed -i '/ENV PATH="\/root\/.bun\/bin:${PATH}"/a RUN npm install -g corepack' Dockerfile
    echo "已注入 corepack 安装命令"
fi

# 3. 生成配置覆盖 (Override)
echo -e "${YELLOW}[3/6] 生成配置修正文件...${NC}"
cat > docker-compose.override.yml <<EOF
services:
  moltbot-gateway:
    environment:
      CLAWDBOT_SKILLS_DIR: /app/skills
      TAVILY_API_KEY: \${TAVILY_API_KEY}
    volumes:
      - ./skills:/app/skills

  moltbot-cli:
    volumes:
      - ./skills:/app/skills
EOF
echo "已生成 docker-compose.override.yml"

# 4. 重新构建
echo -e "${YELLOW}[4/6] 构建 Docker 镜像...${NC}"
sudo docker build -t moltbot:local .

if [ $? -ne 0 ]; then
    echo -e "${RED}构建失败！请检查镜像 Tag 是否正确或网络是否通畅。${NC}"
    exit 1
fi

# 5. 安装技能
echo -e "${YELLOW}[5/6] 安装推荐技能 (使用 $NODE_IMAGE)...${NC}"
# 确保 skills 目录存在，否则 docker run 会自动创建为 root 权限
mkdir -p skills 

sudo docker run --rm \
    -v $(pwd):/app \
    -w /app \
    $NODE_IMAGE \
    /bin/sh -c "npm install -g undici clawdhub && \
    clawdhub install --force tavily && \
    clawdhub install --force github && \
    clawdhub install --force summarize && \
    clawdhub install --force weather"

# 6. 启动
echo -e "${YELLOW}[6/6] 启动服务...${NC}"
sudo docker compose up -d

echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}   所有的活都干完了！(Deployment Complete)    ${NC}"
echo -e "${GREEN}==============================================${NC}"