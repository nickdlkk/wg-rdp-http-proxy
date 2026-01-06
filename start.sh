#!/bin/bash

set -e

# Start squid service
start_squid()
{
    # 清理可能存在的 PID 文件
    if [ -f /run/squid.pid ]; then
        echo "Cleaning up stale Squid PID file..."
        rm -f /run/squid.pid
    fi
    
    # 确保 Squid 进程完全停止
    service squid stop 2>/dev/null || true
    sleep 2
    
    service squid start
    if [ ! `service squid status | grep "squid is running" | wc -l` -gt 0 ]; then 
        echo "Error: failed to start squid service" >&2; 
        return 1
    fi
    return 0
}

# 启动WireGuard (后台运行)
echo "=== Starting WireGuard ==="
/runWg.sh &
WIREGUARD_PID=$!

# 启动RDP转发 (后台运行)
echo "=== Starting RDP Forwarder ==="
/rdp-forward.sh &
RDP_FORWARD_PID=$!

# 启动HTTPS转发 (后台运行)
echo "=== Starting HTTPS Forwarder ==="
/https-forward.sh &
HTTPS_FORWARD_PID=$!

echo "==== Try Start Squid Proxy ===="
# 启动 squid
for i in `seq 3`
do
    start_squid
    if [ $? -eq 0 ]; then
        break 
    fi
    if [ $i -eq 3 ]; then
        echo "Error: failed to start squid service." >&2
        exit 1
    fi
done
service squid status

# 捕获退出信号
trap "kill $WIREGUARD_PID $RDP_FORWARD_PID $HTTPS_FORWARD_PID 2>/dev/null; wg-quick down wg0 2>/dev/null || true; exit 0" SIGINT SIGTERM

# 等待所有后台进程退出
wait -n $WIREGUARD_PID $RDP_FORWARD_PID $HTTPS_FORWARD_PID
EXIT_CODE=$?

# 如果任一进程退出，终止其他进程和WireGuard连接
kill $WIREGUARD_PID $RDP_FORWARD_PID $HTTPS_FORWARD_PID 2>/dev/null || true
wg-quick down wg0 2>/dev/null || true

exit $EXIT_CODE