FROM alpine:latest

# 安装依赖
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    wget \
    unzip \
    gettext

# 安装 Xray
RUN set -eux; \
    wget -O /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip; \
    unzip /tmp/xray.zip -d /tmp; \
    cp /tmp/xray /usr/bin/xray 2>/dev/null || cp /tmp/Xray /usr/bin/xray; \
    chmod +x /usr/bin/xray; \
    rm -rf /tmp/xray.zip /tmp/xray /tmp/Xray

# 安装 Cloudflared
RUN set -eux; \
    wget -O /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    chmod +x /usr/bin/cloudflared

# 复制配置模板
COPY config.template.json /etc/xray/config.template.json

# 创建启动脚本
RUN set -eux; \
    echo '#!/bin/bash' > /entrypoint.sh; \
    echo 'envsubst < /etc/xray/config.template.json > /etc/xray/config.json' >> /entrypoint.sh; \
    echo '/usr/bin/xray -config /etc/xray/config.json &' >> /entrypoint.sh; \
    echo 'exec /usr/bin/cloudflared tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}' >> /entrypoint.sh; \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
