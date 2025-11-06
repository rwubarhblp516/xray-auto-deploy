# Xray VPN 一键部署脚本

一键部署 Xray VPN，支持 VLESS + Reality 协议，专为中国用户优化。

## 特性

- 🚀 一键安装，简单快捷
- 🔒 使用最新的 VLESS + Reality 协议
- 🎯 自动生成随机端口，避免被针对性封锁
- 🛡️ 自动配置防火墙规则
- 📱 支持所有主流客户端
- 🌍 适用于 Ubuntu、Debian、CentOS 系统

## 系统要求

- **操作系统**: Ubuntu 18.04+, Debian 10+, CentOS 7+
- **权限**: Root 权限
- **网络**: 服务器需要能访问外网
- **架构**: x86_64 / ARM64

## 快速开始

### 方式一：在线安装

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/rwubarhblp516/xray-auto-deploy/main/install.sh)"
```

或者使用 wget：

```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/rwubarhblp516/xray-auto-deploy/main/install.sh)"
```

### 方式二：下载后安装

```bash
# 下载脚本
wget https://raw.githubusercontent.com/rwubarhblp516/xray-auto-deploy/main/install.sh

# 添加执行权限
chmod +x install.sh

# 运行脚本
sudo bash install.sh
```

## 安装过程

脚本会引导您完成以下配置：

1. **端口选择**: 可以自定义端口或自动生成随机端口（推荐）
2. **域名配置**: 可以使用域名或直接使用IP地址
3. **伪装站点**: 选择伪装的目标网站（默认 www.microsoft.com）

整个过程大约需要 2-5 分钟。

## 安装完成后

安装成功后，脚本会显示：

- ✅ VLESS 分享链接
- ✅ 服务器信息
- ✅ 客户端配置方法

详细配置信息保存在：`/root/xray-client-config.txt`

查看配置：
```bash
cat /root/xray-client-config.txt
```

## 客户端推荐

### Android
- [v2rayNG](https://github.com/2dust/v2rayNG/releases) - 免费开源，强烈推荐
- [NekoBox](https://github.com/MatsuriDayo/NekoBoxForAndroid/releases) - 界面美观

### iOS
- Shadowrocket - App Store付费应用
- Stash - App Store付费应用

### Windows
- [v2rayN](https://github.com/2dust/v2rayN/releases) - 功能强大
- [Clash Verge](https://github.com/clash-verge-rev/clash-verge-rev/releases) - 界面现代

### macOS
- [V2rayU](https://github.com/yanue/V2rayU/releases) - 简单易用
- [Clash Verge](https://github.com/clash-verge-rev/clash-verge-rev/releases) - 跨平台

### Linux
- [Qv2ray](https://github.com/Qv2ray/Qv2ray/releases) - 图形界面
- Xray-core - 命令行版本

## 导入配置

### 方法一：使用分享链接（推荐）

1. 复制安装后显示的 VLESS 分享链接
2. 在客户端应用中选择 "从剪贴板导入" 或 "扫描二维码"
3. 连接即可使用

### 方法二：手动配置

按照 `/root/xray-client-config.txt` 中的详细信息手动填写配置。

## 服务管理

```bash
# 查看服务状态
systemctl status xray

# 启动服务
systemctl start xray

# 停止服务
systemctl stop xray

# 重启服务
systemctl restart xray

# 查看日志
journalctl -u xray -f

# 查看最近50条日志
journalctl -u xray -n 50
```

## 配置文件位置

- **服务端配置**: `/usr/local/etc/xray/config.json`
- **客户端配置**: `/root/xray-client-config.txt`
- **访问日志**: `/var/log/xray/access.log`
- **错误日志**: `/var/log/xray/error.log`

## 防火墙配置

### 云服务器额外配置

如果使用云服务器（如 Google Cloud、AWS、阿里云等），需要在云控制台配置安全组/防火墙规则：

**开放端口**: 安装时选择的端口（例如 37794）
**协议**: TCP
**源地址**: 0.0.0.0/0（允许所有IP）

#### Google Cloud Platform (GCP)
1. 进入 VPC网络 > 防火墙规则
2. 创建防火墙规则
3. 允许 TCP 端口入站流量

#### AWS
1. 进入 EC2 > 安全组
2. 编辑入站规则
3. 添加自定义 TCP 规则

#### 阿里云
1. 进入 云服务器ECS > 安全组
2. 配置规则 > 添加安全组规则
3. 允许自定义端口访问

## 卸载

```bash
# 停止服务
systemctl stop xray
systemctl disable xray

# 卸载 Xray
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) remove

# 删除配置文件
rm -rf /usr/local/etc/xray
rm -rf /var/log/xray
rm -f /root/xray-client-config.txt
```

## 常见问题

### 1. 无法连接

**检查步骤**：
- ✓ 确认云服务器防火墙规则已正确配置
- ✓ 确认服务器本地防火墙允许端口通过
- ✓ 检查客户端时间与服务器时间误差不超过90秒
- ✓ 查看服务日志：`journalctl -u xray -n 50`

### 2. 连接慢或不稳定

**解决方案**：
- 尝试更换端口（重新运行安装脚本）
- 考虑启用 BBR 加速
- 更换伪装站点

### 3. 端口被占用

运行脚本时选择"随机生成端口"，脚本会自动选择未被占用的端口。

### 4. 如何更新 Xray

```bash
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install
systemctl restart xray
```

## 安全建议

1. **定期更换端口和UUID**: 提高安全性
2. **使用强随机端口**: 避免使用常见端口如 443、8443
3. **限制访问**: 如果只有固定IP使用，可以在防火墙限制源IP
4. **保密配置**: 不要在公开场合分享配置信息
5. **监控日志**: 定期检查访问日志，发现异常及时处理

## 性能优化

### 启用 BBR 加速（可选）

BBR 可以显著提升网络性能，特别是高延迟网络环境。

```bash
# 检查内核版本（需要 4.9+）
uname -r

# 启用 BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 验证
sysctl net.ipv4.tcp_congestion_control
# 应该显示: net.ipv4.tcp_congestion_control = bbr
```

## 技术原理

### VLESS + Reality 协议

- **VLESS**: 轻量级代理协议，性能优秀
- **Reality**: 最新的流量伪装技术，无需TLS证书
- **特点**: 流量特征接近真实HTTPS，抗检测能力强

### 伪装原理

Reality 协议通过伪装成访问指定网站（如 microsoft.com）的HTTPS流量，使代理流量看起来像正常的网页访问，从而避免被识别和封锁。

## 更新日志

### v1.0.0 (2025-11-06)
- 初始版本发布
- 支持 VLESS + Reality 协议
- 自动配置防火墙
- 交互式配置向导

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 免责声明

本项目仅供学习和研究使用，请遵守当地法律法规。使用本脚本所产生的任何后果由使用者自行承担。

## 致谢

- [Xray-core](https://github.com/XTLS/Xray-core) - 核心项目
- [Xray-install](https://github.com/XTLS/Xray-install) - 安装脚本

## 联系方式

如有问题，请提交 [Issue](https://github.com/rwubarhblp516/xray-auto-deploy/issues)。
