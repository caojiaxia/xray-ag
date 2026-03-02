#!/bin/bash

# 检查是否安装了 Docker
if ! [ -x "$(command -v docker)" ]; then
  echo '检测到未安装 Docker，正在安装...'
  curl -fsSL https://get.docker.com | bash
  systemctl enable --now docker
fi

# 获取用户输入的变量 (如果环境变量没设置的话)
read -p "请输入你的 TUNNEL_TOKEN: " TOKEN
read -p "请输入你的 UUID [默认: c67e108d-b135-4acd-b0b4-33f2d18dff44]: " UUID
UUID=${UUID:-c67e108d-b135-4acd-b0b4-33f2d18dff44}
read -p "请输入你的 XPATH [默认: /GEdhhrQEkzaq]: " XPATH
XPATH=${XPATH:-/GEdhhrQEkzaq}

# 定义镜像名 (替换成你自己的)
IMAGE="ghcr.io/你的用户名/你的仓库名:latest"

echo "正在停止并删除旧容器 (如果存在)..."
docker rm -f xray-tunnel 2>/dev/null

echo "正在拉取最新镜像..."
docker pull $IMAGE

echo "正在启动容器..."
docker run -d \
  --name xray-tunnel \
  --restart always \
  -e TUNNEL_TOKEN=$TOKEN \
  -e UUID=$UUID \
  -e XPATH=$XPATH \
  $IMAGE
