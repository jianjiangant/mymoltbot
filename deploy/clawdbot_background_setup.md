# Clawdbot Gateway 后台运行指南

## 方法一：使用 systemd (推荐 - Linux系统)

### 1. 创建systemd服务文件
```bash
sudo nano /etc/systemd/system/clawdbot.service
```

### 2. 添加服务配置
```ini
[Unit]
Description=Clawdbot Gateway Service
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/home/your_username/clawd
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /home/your_username/clawd/node_modules/clawdbot/bin/clawdbot gateway start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 3. 重新加载systemd并启动服务
```bash
sudo systemctl daemon-reload
sudo systemctl enable clawdbot
sudo systemctl start clawdbot
```

### 4. 检查服务状态
```bash
sudo systemctl status clawdbot
```

## 方法二：使用 PM2 (推荐 - Node.js应用管理)

### 1. 安装PM2
```bash
npm install -g pm2
```

### 2. 启动clawdbot并保存配置
```bash
cd /home/your_username/clawd
pm2 start clawdbot --name "clawdbot-gateway" -- gateway start
pm2 save
```

### 3. 设置PM2开机自启
```bash
pm2 startup
```

### 4. 查看PM2进程
```bash
pm2 list
pm2 logs clawdbot-gateway
```

## 方法三：使用 nohup

### 1. 启动服务
```bash
cd /home/your_username/clawd
nohup clawdbot gateway start > clawdbot.log 2>&1 &
echo $! > clawdbot.pid
```

### 2. 查看进程
```bash
cat clawdbot.pid
tail -f clawdbot.log
```

### 3. 停止服务
```bash
kill $(cat clawdbot.pid)
```

## 方法四：使用 screen 或 tmux

### 使用 screen
```bash
# 创建新会话
screen -S clawdbot

# 在会话中启动clawdbot
clawdbot gateway start

# 分离会话 (Ctrl+A, 然后按 D)
# 重新连接: screen -r clawdbot
```

### 使用 tmux
```bash
# 创建新会话
tmux new-session -d -s clawdbot

# 在会话中启动clawdbot
tmux send-keys -t clawdbot 'clawdbot gateway start' Enter

# 查看会话: tmux list-sessions
# 连接到会话: tmux attach-session -t clawdbot
```

## 验证后台运行

无论使用哪种方法，都可以通过以下方式验证clawdbot是否正常运行：

```bash
# 检查进程
ps aux | grep clawdbot

# 检查端口占用 (默认可能是3000或其他端口)
netstat -tlnp | grep :3000
# 或者
lsof -i :3000

# 检查服务状态
clawdbot gateway status
```

## 日志管理

### 查看日志
```bash
# 如果使用systemd
sudo journalctl -u clawdbot -f

# 如果使用PM2
pm2 logs clawdbot-gateway

# 如果使用nohup
tail -f clawdbot.log
```

## 自动重启配置

### 为systemd服务添加自动重启
在service部分添加：
```ini
Restart=always
RestartSec=10
StartLimitInterval=60s
StartLimitBurst=3
```

## 故障排除

### 常见问题
1. **权限问题**: 确保运行用户有足够权限
2. **端口占用**: 检查端口是否被其他服务占用
3. **环境变量**: 确保所有必要的环境变量已设置

### 检查配置
```bash
clawdbot gateway status
clawdbot config.get
```

## 停止服务

### 对应的停止方法
- **systemd**: `sudo systemctl stop clawdbot`
- **PM2**: `pm2 stop clawdbot-gateway && pm2 delete clawdbot-gateway`
- **nohup**: `kill $(cat clawdbot.pid)`
- **screen**: `screen -S clawdbot -X quit`
- **tmux**: `tmux kill-session -t clawdbot`

---

推荐使用 **systemd** 方法，因为它提供最佳的系统集成和自动重启功能。如果是在开发环境中，**PM2** 是很好的选择。