#!/bin/bash

# 检查目标RDP服务器是否设置
if [ -z "$RDP_TARGET" ]; then
  echo "ERROR: RDP_TARGET environment variable not set"
  echo "Please set using: -e RDP_TARGET=<target_ip>"
  exit 1
fi

# 等待WireGuard接口建立
echo "Waiting for WireGuard tunnel to establish..."
INTERFACE_NAME="wg0"
for i in {1..30}; do
  if ip link show "$INTERFACE_NAME" &> /dev/null; then
    echo "WireGuard tunnel established"
    break
  fi
  if [[ $i == 30 ]]; then
    echo "ERROR: Failed to establish WireGuard tunnel within 30 seconds"
    exit 1
  fi
  sleep 1
done

# 获取WireGuard接口的IP地址
WG_IP=$(ip -4 addr show "$INTERFACE_NAME" | awk '/inet/ {print $2}' | cut -d'/' -f1)
if [ -z "$WG_IP" ]; then
  echo "ERROR: Could not get WireGuard IP address"
  exit 1
fi

echo "Using WireGuard IP: $WG_IP"
echo "Forwarding RDP traffic to: $RDP_TARGET"

# 启动socat进行端口转发
exec socat \
    TCP-LISTEN:${RDP_PORT:-3389},fork,reuseaddr \
    TCP:$RDP_TARGET:3389,bind=$WG_IP