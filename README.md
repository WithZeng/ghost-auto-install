# 🚀 Ghost 博客一键部署脚本
# 此脚本目前仍有很多bug尚未修复，谨慎使用！！！
这是一个适用于 Ubuntu 系统的 Ghost 博客一键安装脚本，支持自动处理安装过程中的常见问题，如 Node.js 冲突、内存不足、数据库配置、HTTPS 证书申请等。

> 项目作者：withzeng
> 博客地址：[https://boke.test12dad.store](https://boke.test12dad.store)

---

## 📌 脚本功能

* 自动安装系统依赖（Nginx、MySQL、Node.js、ghost-cli）
* 自动创建 MySQL 数据库和用户
* 自动安装 Ghost 并配置反向代理
* 自动添加 swap 避免内存不足错误
* 自动申请并配置 HTTPS（Let's Encrypt）
* 自动放行 80 / 443 防火墙端口

---

## 🛠 使用方法

```bash
curl -O https://raw.githubusercontent.com/WithZeng/ghost-auto-install/main/install-ghost.sh
chmod +x install-ghost.sh
sudo ./install-ghost.sh
```

> ⚠️ 请确保你的域名（如 `boke.test12dad.store`）已经正确解析到服务器公网 IP。

---

## ✅ 脚本适配环境

* 系统版本：Ubuntu 20.04 / 22.04
* 内存建议：最低 1G，推荐创建 2G swap（脚本已自动处理）
* 适用于全新 VPS / 云主机环境（含 Azure）

---

## 💡 错误修复支持

| 问题                | 处理方案               |
| ----------------- | ------------------ |
| Node.js 安装冲突      | 自动清除旧版本并安装 v18     |
| 内存不足导致 Ghost 安装中断 | 自动添加 2G swap       |
| Ghost CLI 报错      | 自动检测 + 目录权限修复      |
| Nginx 配置无效        | 自动生成配置文件并 reload   |
| 443 端口无法访问        | 自动安装 Certbot 并申请证书 |

---

## 📂 文件结构

```
├── install-ghost.sh    # 主安装脚本
├── README.md           # 中文说明文档
└── README_EN.md        # English readme
```

---

## 📮 联系作者

如果你在使用过程中遇到问题，欢迎通过 GitHub Issue 提交反馈，或访问博客与我联系：

👉 [https://boke.test12dad.store](https://boke.test12dad.store)

---

## 🪪 License

MIT License
Maintained by [WithZeng](https://github.com/WithZeng)
