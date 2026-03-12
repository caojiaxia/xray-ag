#!/bin/bash

# ================= 配置区 =================
GH_USER="caojiaxia"
TUNNEL_IMAGE="ghcr.io/$GH_USER/xray-tunnel:latest"
INFO_FILE="/etc/xray_tunnel_info.txt"
# ==========================================

# 环境检测：检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "\033[0;31m检测到未安装 Docker，正在自动安装...\033[0m"
        curl -fsSL https://get.docker.com | bash
        if [ $? -ne 0 ]; then
            echo -e "\033[0;31mDocker 安装失败，请手动安装后重试。\033[0m"
            exit 1
        fi
        echo -e "\033[0;32mDocker 安装完成。\033[0m"
    fi
}

# 运行检查
check_docker

# 开启 BBR 函数
enable_bbr() {
    echo -e "\033[0;34m正在检测 BBR...\033[0m"
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "\033[0;32mBBR 已处于开启状态！\033[0m"
    else
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
        echo -e "\033[0;32mBBR 加速已成功开启。\033[0m"
    fi
}

# 安装 Tunnel 函数 (包含拉取镜像与信息记录)
install_tunnel() {
    # 随机生成器
    local RAND_UUID=$(cat /proc/sys/kernel/random/uuid)
    local RAND_PATH="/"$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 8)

    read -p "请输入 Tunnel Token: " TOKEN < /dev/tty
    
    echo -e "\033[0;33m系统生成的随机 UUID: $RAND_UUID\033[0m"
    read -p "请输入 UUID (回车默认): " MY_UUID < /dev/tty
    MY_UUID=${MY_UUID:-$RAND_UUID}
    
    echo -e "\033[0;33m系统生成的随机路径: $RAND_PATH\033[0m"
    read -p "请输入 WS 路径 (回车默认): " MY_XPATH < /dev/tty
    MY_XPATH=${MY_XPATH:-$RAND_PATH}
    
    read -p "请输入 CF 绑定域名: " MY_DOMAIN < /dev/tty

    # 1. 确保拉取最新镜像
    echo -e "\033[0;34m正在从 Docker Hub 拉取镜像: $TUNNEL_IMAGE ...\033[0m"
    docker pull $TUNNEL_IMAGE
    
    # 2. 清理并部署容器
    docker rm -f xray-tunnel 2>/dev/null
    docker run -d --name xray-tunnel --restart always \
        -e TUNNEL_TOKEN="$TOKEN" -e UUID="$MY_UUID" -e XPATH="$MY_XPATH" $TUNNEL_IMAGE
    
    # 3. 记录节点信息 (供查看)
    local FULL_LINK="vless://$MY_UUID@$MY_DOMAIN:443?path=$MY_XPATH&security=tls&type=ws&sni=$MY_DOMAIN#CF_WS_$MY_DOMAIN"
    echo "$FULL_LINK" > "$INFO_FILE"
    
    echo -e "\n\033[0;32m部署成功！\033[0m"
    echo -e "\033[0;36m节点链接：\033[0m"
    echo "$FULL_LINK"
}

# 主程序循环
while true; do
    echo -e "\n===================================="
    echo "1) 安装 Cloudflare Tunnel (自动拉取镜像)"
    echo "2) 查看当前节点配置"
    echo "3) 彻底卸载清理"
    echo "4) 开启 BBR 加速"
    echo "5) 退出"
    echo "===================================="
    
    read -p "请输入选项 [1-5]: " choice < /dev/tty
    choice=$(echo "$choice" | tr -d '\r\n\t ')

    case "$choice" in
        1) install_tunnel ;;
        2) 
            if [ -f "$INFO_FILE" ]; then
                echo -e "\n\033[0;36m保存的节点配置：\033[0m"
                cat "$INFO_FILE"
            else
                echo -e "\033[0;31m未找到配置信息，请先安装。\033[0m"
            fi
            ;;
        3) 
            docker rm -f xray-tunnel 2>/dev/null
            rm -f "$INFO_FILE"
            echo -e "\033[0;32m容器与配置已清理。\033[0m"
            ;;
        4) enable_bbr ;;
        5) echo "退出程序。"; exit 0 ;;
        *) echo -e "\033[0;31m无效选项，请重新输入！\033[0m" ;;
    esac
done
