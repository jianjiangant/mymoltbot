# Clawdbot Gateway 容器环境后台运行指南

在容器环境中，systemd不可用，我们需要使用其他方法来让Clawdbot Gateway在后台运行。

## 方法一：使用 PM2 (推荐)

### 1. 安装 PM2
```bash
npm install -g pm2
```

### 2. 创建 PM2 配置文件
```bash
mkdir -p /home/codespace/clawd
cd /home/codespace/clawd
```

创建 ecosystem.config.js 文件：
```javascript
module.exports = {
  apps: [{
    name: 'clawdbot-gateway',
    script: '/usr/local/share/nvm/versions/node/v24.11.1/bin/clawdbot',
    args: 'gateway start',
    cwd: '/home/codespace/clawd',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PATH: '/usr/local/share/nvm/versions/node/v24.11.1/bin:/usr/local/bin:/usr/bin:/bin'
    }
  }]
};
```

### 3. 启动服务
```bash
# 启动应用
pm2 start ecosystem.config.js

# 保存配置以便重启后自动启动
pm2 save

# 设置开机自启
pm2 startup
```

### 4. 常用 PM2 命令
```bash
# 查看应用状态
pm2 status

# 查看日志
pm2 logs clawdbot-gateway

# 停止应用
pm2 stop clawdbot-gateway

# 重启应用
pm2 restart clawdbot-gateway

# 删除应用
pm2 delete clawdbot-gateway
```

## 方法二：使用 nohup

### 1. 启动 Clawdbot Gateway
```bash
cd /home/codespace/clawd
nohup clawdbot gateway start > /tmp/clawdbot.log 2>&1 &
echo $! > /tmp/clawdbot.pid
```

### 2. 验证进程
```bash
# 检查进程是否存在
cat /tmp/clawdbot.pid
ps aux | grep clawdbot | grep -v grep

# 查看日志
tail -f /tmp/clawdbot.log
```

### 3. 停止服务
```bash
kill $(cat /tmp/clawdbot.pid)
```

## 方法三：使用 screen

### 1. 安装 screen (如果未安装)
```bash
sudo apt-get update && sudo apt-get install -y screen
```

### 2. 创建并启动 screen 会话
```bash
# 创建名为 clawdbot 的会话
screen -dmS clawdbot

# 在会话中运行 clawdbot
screen -S clawdbot -X stuff "cd /home/codespace/clawd && clawdbot gateway start$(printf \\r)"

# 或者手动连接并运行
# screen -S clawdbot -c /dev/null
# cd /home/codespace/clawd
# clawdbot gateway start
# 按 Ctrl+A, 然后按 D 来分离会话
```

### 3. 管理 screen 会话
```bash
# 列出所有会话
screen -ls

# 连接到会话
screen -r clawdbot

# 终止会话
screen -S clawdbot -X quit
```

## 方法四：使用自定义启动脚本

### 1. 创建启动脚本
```bash
cat > /home/codespace/start-clawdbot.sh << 'EOF'
#!/bin/bash

# Clawdbot Gateway 启动脚本

CLAWDBOT_DIR="/home/codespace/clawd"
LOG_FILE="/tmp/clawdbot.log"
PID_FILE="/tmp/clawdbot.pid"

cd $CLAWDBOT_DIR

# 检查是否已在运行
if [ -f $PID_FILE ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Clawdbot Gateway 已在运行 (PID: $PID)"
        exit 1
    fi
fi

# 启动 Clawdbot Gateway
echo "启动 Clawdbot Gateway..."
nohup clawdbot gateway start > $LOG_FILE 2>&1 &
NEW_PID=$!
echo $NEW_PID > $PID_FILE

echo "Clawdbot Gateway 已启动 (PID: $NEW_PID)"
echo "日志文件: $LOG_FILE"
EOF

chmod +x /home/codespace/start-clawdbot.sh
```

### 2. 创建停止脚本
```bash
cat > /home/codespace/stop-clawdbot.sh << 'EOF'
#!/bin/bash

# Clawdbot Gateway 停止脚本

PID_FILE="/tmp/clawdbot.pid"

if [ ! -f $PID_FILE ]; then
    echo "Clawdbot Gateway 未运行或 PID 文件不存在"
    exit 1
fi

PID=$(cat $PID_FILE)

if ps -p $PID > /dev/null 2>&1; then
    echo "停止 Clawdbot Gateway (PID: $PID)..."
    kill $PID
    rm -f $PID_FILE
    echo "Clawdbot Gateway 已停止"
else
    echo "进程 $PID 未找到，删除 PID 文件"
    rm -f $PID_FILE
fi
EOF

chmod +x /home/codespace/stop-clawdbot.sh
```

### 3. 使用脚本
```bash
# 启动服务
/home/codespace/start-clawdbot.sh

# 停止服务
/home/codespace/stop-clawdbot.sh

# 查看日志
tail -f /tmp/clawdbot.log
```

## 验证运行状态

无论使用哪种方法，都可以通过以下命令验证服务是否正常运行：

```bash
# 检查进程
ps aux | grep clawdbot | grep -v grep

# 检查端口是否在监听
netstat -tlnp | grep :18789
# 或者
lsof -i :18789

# 检查 Clawdbot 状态
clawdbot gateway status

# 查看服务日志
# 如果使用 nohup: tail -f /tmp/clawdbot.log
# 如果使用 PM2: pm2 logs clawdbot-gateway
```

## 自动重启配置

如果你希望在系统重启后自动启动Clawdbot，可以将启动命令添加到用户的crontab中：

```bash
# 编辑 crontab
crontab -e

# 添加以下行来在重启后启动服务
@reboot sleep 10 && /home/codespace/start-clawdbot.sh
```

---

对于容器环境，推荐使用 **PM2** 方法，因为它提供了进程管理、自动重启和日志管理等丰富功能。如果只想快速启动，**nohup** 方法也很简单有效。