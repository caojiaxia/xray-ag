#!/bin/bash

# ================= 配置区 =================
GH_USER="caojiaxia"
TUNNEL_IMAGE="ghcr.io/$GH_USER/xray-tunnel:latest"
INFO_FILE="/etc/xray_tunnel_info.txt"
# ==========================================

# 颜色定义
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# 进度条函数
progress_bar() {
    local duration=$1
    local width=30
    for ((i=0; i<=duration; i++)); do
        local filled=$((i * width / duration))
        local empty=$((width - filled))
        printf "\r${GREEN}["
        printf "%${filled}s" | tr ' ' '#'
        printf "%${empty}s" | tr ' ' '.'
        printf "] %d%%" $((i * 100 / duration))
        sleep 0.1
    done
    printf "\n"
}

# 环境检测
check_env() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}检测到未安装 Docker，正在自动安装...${NC}"
        curl -fsSL https://get.docker.com | bash
    fi
}

# 开启 BBR 函数
enable_bbr() {
    echo -e "${BLUE}正在检测 BBR...${NC}"
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "${GREEN}BBR 已处于开启状态！${NC}"
    else
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
        echo -e "${GREEN}BBR 加速已成功开启。${NC}"
    fi
}

# 安装 Tunnel 函数
install_tunnel() {
    local RAND_UUID=$(cat /proc/sys/kernel/random/uuid)
    local RAND_PATH="/"$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 8)

    read -p "请输入 Tunnel Token: " TOKEN < /dev/tty
    read -p "请输入 UUID (回车默认): " MY_UUID < /dev/tty
    MY_UUID=${MY_UUID:-$RAND_UUID}
    read -p "请输入 WS 路径 (回车默认): " MY_XPATH < /dev/tty
    MY_XPATH=${MY_XPATH:-$RAND_PATH}
    read -p "请输入 CF 绑定域名: " MY_DOMAIN < /dev/tty
    
    # 新增伪装参数
    echo -e "${CYAN}--- 高级伪装配置 ---${NC}"
    read -p "请输入伪装域名 (Host/SNI, 回车默认使用 $MY_DOMAIN): " MY_HOST < /dev/tty
    MY_HOST=${MY_HOST:-$MY_DOMAIN}
    read -p "请输入伪装类型 (例如: web, cdn, 或自定义): " MY_TYPE < /dev/tty
    MY_TYPE=${MY_TYPE:-"cdn"}

    echo -e "${BLUE}正在拉取镜像... ${NC}"
    docker pull $TUNNEL_IMAGE > /dev/null &
    progress_bar 15
    
    docker rm -f xray-tunnel 2>/dev/null
    docker run -d --name xray-tunnel --restart always \
        -e TUNNEL_TOKEN="$TOKEN" -e UUID="$MY_UUID" -e XPATH="$MY_XPATH" $TUNNEL_IMAGE
    
    # 生成链接：整合了 Host 和 SNI 参数
    local FULL_LINK="vless://$MY_UUID@$MY_DOMAIN:443?path=$MY_XPATH&security=tls&encryption=none&type=ws&host=$MY_HOST&sni=$MY_HOST&fp=chrome&alpn=h2,http/1.1#CF_WS_${MY_TYPE}_$MY_DOMAIN"
    echo "$FULL_LINK" > "$INFO_FILE"
    
    echo -e "\n${GREEN}部署成功！${NC}"
    echo -e "${CYAN}节点链接 (已加入伪装参数)：${NC}\n$FULL_LINK"
}

# 菜单列表
show_menu() {
    clear
    echo -e "${BLUE}====================================${NC}"
    echo -e "${GREEN}      BoGe Cloudflare Tunnel      ${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo "1) 安装 Cloudflare Tunnel"
    echo "2) 开启 BBR 加速"
    echo "3) 查看已生成的节点链接"
    echo "4) 彻底卸载并清理残留"
    echo "5) 退出"
    echo -e "${BLUE}====================================${NC}"
}

# 主程序循环
check_env
while true; do
    show_menu
    read -p "请选择操作 [1-5]: " choice < /dev/tty
    choice=$(echo "$choice" | tr -d '\r\n\t ')

    case "$choice" in
        1) install_tunnel ;;
        2) enable_bbr ;;
        3) [ -f "$INFO_FILE" ] && (echo -e "\n${CYAN}当前节点链接：${NC}"; cat "$INFO_FILE") || echo -e "${RED}未找到配置。${NC}" ;;
        4) docker rm -f xray-tunnel 2>/dev/null; rm -f "$INFO_FILE"; echo -e "${GREEN}已清理。${NC}" ;;
        5) exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}" ;;
    esac
    read -p "按回车键返回菜单..." _ < /dev/tty
done
