#!/bin/bash

# ================= 配置区 =================
GH_USER="caojiaxia"
TUNNEL_IMAGE="ghcr.io/$GH_USER/xray-tunnel:latest"
INFO_FILE="/etc/xray_tunnel_info.txt"
# ==========================================

# 进度条函数
progress_bar() {
    local duration=$1
    local columns=$(tput cols)
    local width=$((columns - 10))
    for ((i=0; i<=duration; i++)); do
        local filled=$((i * width / duration))
        local empty=$((width - filled))
        printf "\r\033[0;32m["
        printf "%${filled}s" | tr ' ' '#'
        printf "%${empty}s" | tr ' ' '.'
        printf "] %d%%" $((i * 100 / duration))
        sleep 0.05
    done
    printf "\n"
}

# 环境检测
check_env() {
    if ! command -v docker &> /dev/null; then
        echo -e "\033[0;31m检测到未安装 Docker，正在自动安装...\033[0m"
        curl -fsSL https://get.docker.com | bash
    fi
}

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

# 安装 Tunnel 函数
install_tunnel() {
    local RAND_UUID=$(cat /proc/sys/kernel/random/uuid)
    local RAND_PATH="/"$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 8)

    read -p "请输入 Tunnel Token: " TOKEN < /dev/tty
    echo -e "\033[0;33m随机生成的 UUID: $RAND_UUID\033[0m"
    read -p "请输入 UUID (回车默认): " MY_UUID < /dev/tty
    MY_UUID=${MY_UUID:-$RAND_UUID}
    
    echo -e "\033[0;33m随机生成的路径: $RAND_PATH\033[0m"
    read -p "请输入 WS 路径 (回车默认): " MY_XPATH < /dev/tty
    MY_XPATH=${MY_XPATH:-$RAND_PATH}
    
    read -p "请输入 CF 绑定域名: " MY_DOMAIN < /dev/tty

    echo -e "\033[0;34m正在拉取镜像 (请稍候)... \033[0m"
    docker pull $TUNNEL_IMAGE > /dev/null &
    progress_bar 20
    
    docker rm -f xray-tunnel 2>/dev/null
    docker run -d --name xray-tunnel --restart always \
        -e TUNNEL_TOKEN="$TOKEN" -e UUID="$MY_UUID" -e XPATH="$MY_XPATH" $TUNNEL_IMAGE
    
    local FULL_LINK="vless://$MY_UUID@$MY_DOMAIN:443?path=$MY_XPATH&security=tls&type=ws&sni=$MY_DOMAIN#CF_WS_$MY_DOMAIN"
    echo "$FULL_LINK" > "$INFO_FILE"
    echo -e "\n\033[0;32m部署成功！配置已保存。\033[0m"
    echo -e "\033[0;36m节点链接：\033[0m\n$FULL_LINK"
}

# 主程序循环
check_env
while true; do
    echo -e "\n===================================="
    echo "1) 安装 Cloudflare Tunnel"
    echo "2) 查看当前节点配置"
    echo "3) 彻底卸载清理"
    echo "4) 开启 BBR 加速"
    echo "5) 退出"
    echo "===================================="
    
    read -p "请输入选项 [1-5]: " choice < /dev/tty
    choice=$(echo "$choice" | tr -d '\r\n\t ')

    case "$choice" in
        1) install_tunnel ;;
        2) [ -f "$INFO_FILE" ] && (echo -e "\n\033[0;36m节点链接：\033[0m"; cat "$INFO_FILE") || echo -e "\033[0;31m未找到配置。\033[0m" ;;
        3) docker rm -f xray-tunnel 2>/dev/null; rm -f "$INFO_FILE"; echo -e "\033[0;32m已清理。\033[0m" ;;
        4) enable_bbr ;;
        5) exit 0 ;;
        *) echo -e "\033[0;31m无效选项！\033[0m" ;;
    esac
done
