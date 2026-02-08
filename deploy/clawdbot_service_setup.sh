#!/bin/bash

# Clawdbot Gateway 后台服务设置脚本

echo "设置 Clawdbot Gateway 后台服务..."

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
  echo "请以root权限运行此脚本 (使用 sudo)"
  exit 1
fi

# 创建systemd服务文件
SERVICE_FILE="/etc/systemd/system/clawdbot.service"

echo "创建 systemd 服务文件..."

cat > $SERVICE_FILE << EOF
[Unit]
Description=Clawdbot Gateway Service
After=network.target

[Service]
Type=simple
User=codespace
Group=codespace
WorkingDirectory=/home/codespace/clawd
Environment=NODE_ENV=production
Environment=PATH=/usr/local/share/nvm/versions/node/v24.11.1/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/local/share/nvm/versions/node/v24.11.1/bin/clawdbot gateway start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 设置正确的权限
chmod 644 $SERVICE_FILE

echo "重新加载 systemd 配置..."
systemctl daemon-reload

echo "启用 Clawdbot 服务..."
systemctl enable clawdbot

echo "启动 Clawdbot 服务..."
systemctl start clawdbot

echo "检查服务状态..."
systemctl status clawdbot --no-pager -l

echo ""
echo "Clawdbot Gateway 现在已设置为后台服务!"
echo ""
echo "常用命令:"
echo "  检查状态: sudo systemctl status clawdbot"
echo "  启动服务: sudo systemctl start clawdbot"
echo "  停止服务: sudo systemctl stop clawdbot"
echo "  重启服务: sudo systemctl restart clawdbot"
echo "  查看日志: sudo journalctl -u clawdbot -f"
echo ""
echo "服务将在系统启动时自动运行。"