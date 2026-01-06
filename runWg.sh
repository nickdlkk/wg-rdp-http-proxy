#!/bin/bash

CONFIG_DIR="/etc/wireguard/config"
INTERFACE_NAME="wg0"

# 切换到配置目录
cd "$CONFIG_DIR" || { echo "ERROR: Cannot access $CONFIG_DIR"; exit 1; }

# 查找第一个配置文件
CONFIG_FILE=$(find "$CONFIG_DIR" -type f -name '*.conf' | head -n 1)

if [[ -z "$CONFIG_FILE" ]]; then
  echo "ERROR: No WireGuard config found in $CONFIG_DIR"
  echo "Please ensure you have a .conf file (e.g., wg0.conf) in the config directory"
  ls -l "$CONFIG_DIR" || echo "Cannot list directory contents"
  exit 1
fi

echo "Starting WireGuard with: $CONFIG_FILE"

# 复制配置文件到标准位置
cp "$CONFIG_FILE" "/etc/wireguard/$INTERFACE_NAME.conf"

# 启动WireGuard接口
echo "Bringing up WireGuard interface: $INTERFACE_NAME"
if ! wg-quick up "$INTERFACE_NAME"; then
    echo "ERROR: Failed to bring up WireGuard interface"
    exit 1
fi

echo "WireGuard interface $INTERFACE_NAME is up"
wg show "$INTERFACE_NAME"

# 保持脚本运行，监控连接状态
while true; do
    if ! wg show "$INTERFACE_NAME" >/dev/null 2>&1; then
        echo "ERROR: WireGuard interface $INTERFACE_NAME is down, attempting to restart..."
        wg-quick down "$INTERFACE_NAME" 2>/dev/null || true
        sleep 2
        if ! wg-quick up "$INTERFACE_NAME"; then
            echo "ERROR: Failed to restart WireGuard interface"
            exit 1
        fi
        echo "WireGuard interface $INTERFACE_NAME restarted successfully"
    fi
    sleep ${CHECK_INTERVAL:-300}
done