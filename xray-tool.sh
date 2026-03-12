#!/bin/bash

# ================= 配置区 =================
GH_USER="caojiaxia"
TUNNEL_IMAGE="ghcr.io/$GH_USER/xray-tunnel:latest"
INFO_FILE="/etc/xray_tunnel_info.txt"
# ==========================================

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
    read -p "请输入 Tunnel Token: " TOKEN
    read -p "请输入 UUID (回车默认): " MY_UUID
    MY_UUID=${MY_UUID:-"c67e108d-b135-4acd-b0b4-33f2d18dff44"}
    read -p "请输入 WS 路径 (回车默认 /ws): " MY_XPATH
    MY_XPATH=${MY_XPATH:-"/ws"}
    read -p "请输入 CF 绑定域名: " MY_DOMAIN

    docker rm -f xray-tunnel 2>/dev/null
    docker run -d --name xray-tunnel --restart always \
        -e TUNNEL_TOKEN="$TOKEN" -e UUID="$MY_UUID" -e XPATH="$MY_XPATH" $TUNNEL_IMAGE
    
    echo "vless://$MY_UUID@$MY_DOMAIN:443?path=$MY_XPATH&security=tls&type=ws&sni=$MY_DOMAIN#CF_WS_$MY_DOMAIN" > "$INFO_FILE"
    echo -e "\033[0;32m部署成功！配置已保存。\033[0m"
}

# 主程序循环
while true; do
    echo -e "\n===================================="
    echo "1) 安装 Cloudflare Tunnel"
    echo "2) 查看当前节点配置"
    echo "3) 彻底卸载清理"
    echo "4) 开启 BBR 加速"
    echo "5) 退出"
    echo "===================================="
    
    # 强制清理用户输入的所有不可见字符
    read -p "请输入选项 [1-5]: " raw_choice
    choice=$(echo "$raw_choice" | tr -d '\r\n\t ')

    case "$choice" in
        1) install_tunnel ;;
        2) 
            if [ -f "$INFO_FILE" ]; then
                echo -e "\n\033[0;36m当前节点链接：\033[0m"
                cat "$INFO_FILE"
            else
                echo -e "\033[0;31m未找到配置信息，请先安装。\033[0m"
            fi
            ;;
        3) 
            docker rm -f xray-tunnel 2>/dev/null
            rm -f "$INFO_FILE"
            echo -e "\033[0;32m清理完成。\033[0m"
            ;;
        4) enable_bbr ;;
        5) echo "退出程序。"; exit 0 ;;
        *) echo -e "\033[0;31m无效选项，请重新输入！(你输入的是: $choice)\033[0m" ;;
    esac
done
