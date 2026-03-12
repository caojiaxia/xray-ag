#!/bin/bash

# ================= 配置区 =================
GH_USER="caojiaxia"
TUNNEL_IMAGE="ghcr.io/$GH_USER/xray-tunnel:latest"
INFO_FILE="/etc/xray_tunnel_info.txt"
# ==========================================

# 开启 BBR 函数
enable_bbr() {
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo "BBR 已处于开启状态。"
    else
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
        echo "BBR 加速已成功开启。"
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
    echo "部署成功！配置已保存。"
}

# 使用 select 替代 read，利用 Bash 原生菜单结构
echo "请选择操作："
PS3="请输入数字选择 [1-5]: "
options=("安装 Cloudflare Tunnel" "查看当前节点配置" "彻底卸载清理" "开启 BBR 加速" "退出")

select opt in "${options[@]}"
do
    case $opt in
        "安装 Cloudflare Tunnel")
            install_tunnel
            ;;
        "查看当前节点配置")
            if [ -f "$INFO_FILE" ]; then
                echo "当前节点链接："
                cat "$INFO_FILE"
            else
                echo "未找到配置信息。"
            fi
            ;;
        "彻底卸载清理")
            docker rm -f xray-tunnel 2>/dev/null
            rm -f "$INFO_FILE"
            echo "清理完成。"
            ;;
        "开启 BBR 加速")
            enable_bbr
            ;;
        "退出")
            break
            ;;
        *) echo "无效选项 $REPLY";;
    esac
done
