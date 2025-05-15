#!/bin/bash

# ----------------------------------------
# Ghost 一键自动化安装脚本 v2.2
# 支持动态输入域名 · 自动判断内存创建 swap
# 作者：withzeng 项目记录：https://boke.test12dad.store
# ----------------------------------------

# ===== 动态输入用户配置 =====
read -p "请输入你的域名（如 boke.test12dad.store）: " BLOG_DOMAIN
if [ -z "$BLOG_DOMAIN" ]; then
  echo "❌ 域名不能为空，脚本终止。"
  exit 1
fi

BLOG_DIR="/var/www/ghost"
MYSQL_USER="ghost"
MYSQL_PWD="ghost_password"
MYSQL_DB="ghost_db"

echo "🚀 开始自动部署 Ghost 博客：$BLOG_DOMAIN"

# ===== Step 0: 判断内存并创建 swap（低于 2G 自动处理）=====
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

# ===== Step 1: 系统更新与依赖安装 =====
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx mysql-server curl unzip git ufw

# ===== Step 2: 安装 Node.js 18（清除旧版本）=====
sudo apt remove -y nodejs libnode-dev || true
sudo apt autoremove -y
sudo rm -rf /usr/include/node /usr/lib/node_modules /etc/apt/sources.list.d/nodesource.list
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node -v && npm -v

# ===== Step 3: 安装 ghost-cli =====
sudo npm install -g ghost-cli

# ===== Step 4: 创建数据库并授权 =====
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PWD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# ===== Step 5: 创建博客目录并进入 =====
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
  --no-prompt --start

# ===== Step 7: 配置防火墙 =====
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# ===== Step 8: 自动申请 SSL 证书 =====
echo "🔐 正在检查 SSL 证书状态..."
if ! sudo test -f "/etc/letsencrypt/live/$BLOG_DOMAIN/fullchain.pem"; then
  echo "⚠️ 未检测到证书，尝试通过 certbot 自动申请..."
  sudo apt install -y certbot python3-certbot-nginx
  sudo certbot --nginx -d $BLOG_DOMAIN --non-interactive --agree-tos -m admin@$BLOG_DOMAIN
  sudo systemctl reload nginx
else
  echo "✅ SSL 证书已存在"
fi

# ===== 结束提示 =====
echo
echo "🎉 Ghost 博客安装成功！请访问：https://$BLOG_DOMAIN"
echo
echo "📌 若想再次部署，请使用："
echo "curl -sSL https://raw.githubusercontent.com/WithZeng/ghost-auto-install/main/install-ghost.sh | bash"
