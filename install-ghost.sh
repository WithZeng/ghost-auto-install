#!/bin/bash

# ----------------------------------------
# Ghost 一键自动安装脚本 v2.3（增强版）
# 支持动态输入域名 + swap 自动判断 + nginx 修复
# 作者：withzeng 项目记录：https://boke.test12dad.store
# ----------------------------------------

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请以 root 权限运行此脚本。"
  exit 1
fi

# 日志文件
LOG_FILE="/var/log/install-ghost.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ===== 用户输入 =====
read -p "请输入你的域名（如 boke.test12dad.store）: " BLOG_DOMAIN
if [[ ! "$BLOG_DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
  echo "❌ 域名格式不合法，脚本终止。"
  exit 1
fi

BLOG_DIR="/var/www/ghost"
MYSQL_USER="ghost"

# 动态设置数据库密码
read -s -p "请输入数据库密码（留空将随机生成）: " MYSQL_PWD
echo
if [ -z "$MYSQL_PWD" ]; then
  MYSQL_PWD=$(openssl rand -base64 12)
  echo "✅ 随机生成的数据库密码为：$MYSQL_PWD"
fi

MYSQL_DB="ghost_db"

echo "🚀 开始部署 Ghost 博客：$BLOG_DOMAIN"

# ===== Step 0: 自动判断内存并创建 swap（低于 2G）=====
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo "📊 当前物理内存：${TOTAL_MEM} MB"

if [ "$TOTAL_MEM" -lt 2048 ]; then
  echo "⚠️ 物理内存小于 2GB，将自动创建 2GB swap..."
  if ! grep -q swap /etc/fstab; then
    sudo dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  else
    echo "✅ swap 已存在，跳过创建"
  fi
else
  echo "✅ 内存充足，跳过 swap 创建"
fi

# ===== Step 1: 安装系统依赖 =====
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx mysql-server curl unzip git ufw || {
  echo "❌ 系统依赖安装失败，脚本终止。"
  exit 1
}

# ===== Step 2: 安装 Node.js 18（清理旧版本）=====
sudo apt remove -y nodejs libnode-dev || true
sudo apt autoremove -y
sudo rm -rf /usr/include/node /usr/lib/node_modules /etc/apt/sources.list.d/nodesource.list
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs || {
  echo "❌ Node.js 安装失败，脚本终止。"
  exit 1
}
node -v && npm -v

# ===== Step 3: 安装 ghost-cli =====
sudo npm install -g ghost-cli || {
  echo "❌ ghost-cli 安装失败，脚本终止。"
  exit 1
}

# ===== Step 4: 初始化数据库 =====
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PWD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# ===== Step 5: 创建 Ghost 目录 =====
sudo mkdir -p $BLOG_DIR
sudo chown $USER:$USER $BLOG_DIR
cd $BLOG_DIR

# ===== Step 6: 安装 Ghost 博客 =====
ghost install --db mysql \
  --dbhost localhost \
  --dbuser $MYSQL_USER \
  --dbpass $MYSQL_PWD \
  --dbname $MYSQL_DB \
  --url https://$BLOG_DOMAIN \
  --no-prompt --start || {
  echo "❌ Ghost 安装失败，请检查日志：$LOG_FILE"
  exit 1
}

# ===== Step 7: 防火墙配置 =====
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# ===== Step 8: 修复 Nginx 启用站点（核心增强项）=====
NGINX_CONF="/etc/nginx/sites-available/$BLOG_DOMAIN.conf"
if [ -f "$NGINX_CONF" ]; then
  echo "🔧 检测到站点配置：$NGINX_CONF"

  # 启用该站点
  sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$BLOG_DOMAIN.conf"

  # 禁用默认站点
  if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "⚠️ 正在禁用默认站点..."
    sudo rm /etc/nginx/sites-enabled/default
  fi

  # 重启 nginx
  sudo nginx -t && sudo systemctl reload nginx
else
  echo "⚠️ 未找到配置文件 $NGINX_CONF，nginx 站点可能未启用"
fi

# ===== Step 9: 自动申请 HTTPS（如果证书缺失）=====
echo "🔐 正在检查 SSL 证书状态..."
if ! sudo test -f "/etc/letsencrypt/live/$BLOG_DOMAIN/fullchain.pem"; then
  echo "⚠️ 未检测到证书，尝试通过 certbot 自动申请..."
  sudo apt install -y certbot python3-certbot-nginx
  sudo certbot --nginx -d $BLOG_DOMAIN --non-interactive --agree-tos -m admin@$BLOG_DOMAIN
  sudo systemctl reload nginx
else
  echo "✅ SSL 证书已存在"
fi

# ===== 完成提示 =====
echo
echo "🎉 Ghost 博客安装成功，请访问：https://$BLOG_DOMAIN"
echo
echo "✅ 若想再次运行，请使用："
echo "curl -sSL https://raw.githubusercontent.com/WithZeng/ghost-auto-install/main/install-ghost.sh | bash"
