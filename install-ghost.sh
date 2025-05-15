#!/bin/bash

# ----------------------------------------

# Ghost 一键自动化安装脚本 v2.1
# 含稳定 swap 创建逻辑，适配低内存 VPS
# 作者：withzeng 项目记录：boke.test12dad.store
=======
# Ghost 一键自动化安装脚本（包含错误修复和说明）
# 作者：withzeng 项目记录：boke.test12dad.store
# 适用于 Ubuntu 20.04 / 22.04，全新系统推荐使用
>>>>>>> 4e03c31905e3e18683c691c00fd171d0495bab47
# ----------------------------------------

# ===== 用户可配置参数 =====
BLOG_DOMAIN="boke.test12dad.store"
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

=======

# ===== Step 1: 系统更新与依赖安装 =====
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx mysql-server curl unzip git ufw

<<<<<<< HEAD
# ===== Step 2: 移除旧 Node.js 并安装 Node.js 18 =====
=======
# ===== Step 2: 移除旧 Node.js 并安装官方推荐的 Node.js 18 =====
>>>>>>> 4e03c31905e3e18683c691c00fd171d0495bab47
sudo apt remove -y nodejs libnode-dev || true
sudo apt autoremove -y
sudo rm -rf /usr/include/node /usr/lib/node_modules /etc/apt/sources.list.d/nodesource.list
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node -v && npm -v

# ===== Step 3: 安装 ghost-cli =====
sudo npm install -g ghost-cli


# ===== Step 4: 创建数据库并授权 =====
=======
# ===== Step 4: 添加 swap 避免内存不足导致安装失败（推荐2G）=====
if ! grep -q swap /etc/fstab; then
  echo "🧠 创建 2G swap 以防止内存不足..."
  sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
else
  echo "✅ swap 已存在，跳过创建"
fi

# ===== Step 5: 创建数据库并授权 =====

sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PWD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF


# ===== Step 5: 创建博客目录并进入 =====
=======
# ===== Step 6: 创建目录并进入 =====

sudo mkdir -p $BLOG_DIR
sudo chown $USER:$USER $BLOG_DIR
cd $BLOG_DIR


# ===== Step 6: 安装 Ghost 博客（自动模式）=====
=======
# ===== Step 7: 安装 Ghost（非交互自动化）=====

ghost install --db mysql \
  --dbhost localhost \
  --dbuser $MYSQL_USER \
  --dbpass $MYSQL_PWD \
  --dbname $MYSQL_DB \
  --url https://$BLOG_DOMAIN \
  --no-prompt --start


# ===== Step 7: 防火墙配置（确保端口开放）=====
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# ===== Step 8: 自动修复 SSL（若缺失）=====
=======
# ===== Step 8: 防火墙设置（确保 Nginx 端口可访问）=====
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# ===== Step 9: 自动修复 HTTPS（如果未配置证书）=====

echo "🔐 检查 SSL 证书配置状态..."
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
<<<<<<< HEAD
echo "✅ 若想再次运行，请使用："
=======
echo "✅ 若想再次运行，请使用以下命令："

echo "curl -sSL https://raw.githubusercontent.com/WithZeng/ghost-auto-install/main/install-ghost.sh | bash"
