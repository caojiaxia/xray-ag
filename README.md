## 使用教程
**Docker环境部署**
- 1.更新系统软件包
```
apt update && apt upgrade -y
```
- 2.安装必要的工具
```
apt install -y curl nano
```
- 3.安装docker：
```
bash <(curl -sSL https://cdn.jsdelivr.net/gh/SuperManito/LinuxMirrors@main/DockerInstallation.sh)
```
- 4.安装docker-compose
```
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
```
- 加速镜像
```
curl -L "https://hub.gitmirror.com/https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
```

### Docker-compose配置 

```yml      
services:
  xray-tunnel:
    image: ghcr.io/caojiaxia/xray-ag:latest
    container_name: xray-tunnel
    restart: always
    environment:
      UUID: xxxxxx     #你的UUID
      XPATH: /xxxxxx   #你的路径
      TUNNEL_TOKEN: 你的隧道Token
```

### 启动命令

- 1
```
docker compose pull
```
- 2
```
docker compose up -d
```
- 3
```
 docker logs -f xray-tunnel
```


### cloudflare tunnel创建
| 选项        | 说明                                                                      |
| ----------- | --------------------------------------------------------------------      |
| Type |   HTTP                                                                           |
| URL  | localhost:8080                                                                   |


## 客户端参数配置
**请严格对照以下参数修改你的客户端（如 v2rayN, Clash Meta 等）**

| 选项        | 说明                                                                      |
| ----------- | --------------------------------------------------------------------      |
| 地址 (Address) | tunnel.abc.com (你刚才在 CF 设置的子域名)                                                                           |
| 端口 (Port)| 443 (注意：隧道出口在 CF 边缘，永远是 443)                                  |
| 用户 ID (UUID) | 你的UUID  |
| 传输协议 (Network) | ws (WebSocket)                                                             |
|伪装域名(host)   |tunnel.abc.com (你刚才在 CF 设置的子域名)                                      |
| 伪装路径 (Path) | /你的路径                                                                     |
| 传输安全 (TLS)t | 开启 (ON)                                                                     |
| SNI | tunnel.abc.com (你刚才在 CF 设置的子域名)     |
| 指纹 (Fingerprint) | chrome 或 randomized          |
| ALPN  |   h2, http/1.1    |
| 跳过证书验证(allowlnsecure) |  false      |
