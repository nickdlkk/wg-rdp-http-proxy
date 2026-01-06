FROM nickdlk/ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要软件
RUN apt-get update --fix-missing || apt-get update && \
    apt-get install -y --no-install-recommends \
        wireguard-tools \
        iproute2 \
        socat \
        squid \
        curl net-tools dnsutils tcpdump iputils-ping nmap mtr \
        iptables procps \
        ca-certificates && \
    # 清理缓存
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # 创建WireGuard配置目录
    mkdir -p /etc/wireguard/config && \
    # 配置 squid
    mv /etc/squid/squid.conf /etc/squid/squid.conf.back && \
    touch /etc/squid/squid.conf && \
    echo "http_access allow all" >> /etc/squid/squid.conf && \
    echo "http_access allow CONNECT all" >> /etc/squid/squid.conf && \
    echo "http_port 8000" >> /etc/squid/squid.conf 

# 复制脚本文件
COPY runWg.sh /runWg.sh
COPY rdp-forward.sh /rdp-forward.sh
COPY https-forward.sh /https-forward.sh
COPY start.sh /start.sh

# 设置权限
RUN chmod +x /runWg.sh /rdp-forward.sh /https-forward.sh /start.sh

# WireGuard配置目录（运行时挂载）
VOLUME ["/etc/wireguard/config"]

# 暴露RDP和HTTPS转发端口
EXPOSE 3389 443

# 设置容器启动时执行的命令
CMD ["/start.sh"]