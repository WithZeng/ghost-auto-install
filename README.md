# 🚀 Ghost 一键安装脚本 | Ghost Auto-Install Script

这是一个适用于 Ubuntu 20.04 / 22.04 的 Shell 安装脚本，可在服务器上一键部署 Ghost 博客平台。  
This is a Shell script that automatically installs the Ghost blog platform on Ubuntu 20.04 / 22.04 servers.

## ✅ 一键安装命令 | One-command Installation

```bash
curl -sSL https://raw.githubusercontent.com/WithZeng/ghost-auto-install/main/install-ghost.sh | bash
```

## ✨ 功能 Features

- 自动安装 Node.js、MySQL、Nginx
- 自动创建数据库和用户
- 自动安装 Ghost，配置 Systemd 启动
- 自动配置 Nginx + SSL (Let's Encrypt)
- 脚本交互式填写域名、数据库密码，流程自动无人工干预

## 📦 GitHub 克隆方式 | Clone from GitHub

```bash
git clone https://github.com/WithZeng/ghost-auto-install.git
cd ghost-auto-install
bash install-ghost.sh
```

## ⚠ 注意事项 Notes

- 确保域名已解析到服务器 IP
- 防火墙开放 80 和 443 端口
- 建议使用非 root 用户运行脚本

## 🪪 License

MIT License  
Maintained by [WithZeng](https://github.com/WithZeng)
