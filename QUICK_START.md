# 快速开始指南

本文档帮助您在 5 分钟内完成 Xray VPN 的部署。

## 📋 部署前准备

### 服务器要求

- ✅ 系统: Ubuntu 18.04+, Debian 10+, CentOS 7+
- ✅ 权限: Root 或 sudo 权限
- ✅ 网络: 可以访问外网
- ✅ 内存: 建议 512MB 以上

### 推荐云服务商

- Google Cloud Platform (GCP) - 首年送 $300 额度
- AWS - 首年免费套餐
- Vultr - 按小时计费，可随时删除
- DigitalOcean - 界面友好，适合新手

## 🚀 一键部署

### 方法一：在线安装（推荐）

复制以下命令到服务器执行：

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/rwubarhblp516/xray-auto-deploy/main/install.sh)"
```

### 方法二：下载后安装

```bash
wget https://raw.githubusercontent.com/rwubarhblp516/xray-auto-deploy/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 📝 安装过程

脚本会询问以下配置（可以直接回车使用默认值）：

1. **监听端口**
   - 直接回车：自动生成随机端口（推荐）
   - 或输入自定义端口（10000-60000）

2. **域名**
   - 如果有域名，输入域名（如 `vpn.example.com`）
   - 没有域名，直接回车使用服务器IP

3. **伪装站点**
   - 选择 1（默认）：microsoft.com
   - 其他选项或自定义

## ⚙️ 云服务器防火墙配置

**重要**: 必须配置云控制台的防火墙规则，否则无法连接！

### Google Cloud Platform

```bash
# 方法一：使用 gcloud 命令（推荐）
gcloud compute firewall-rules create allow-xray \
    --allow tcp:37794 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow Xray VPN"

# 注意：将 37794 替换为您实际选择的端口
```

或在控制台操作：

1. 进入 [VPC 网络 > 防火墙规则](https://console.cloud.google.com/networking/firewalls/list)
2. 创建防火墙规则
3. 配置：
   - 名称: `allow-xray`
   - 流量方向: 入站
   - 目标: 网络中的所有实例
   - 源 IP 范围: `0.0.0.0/0`
   - 协议和端口: `tcp:您的端口`

### AWS EC2

1. 进入 EC2 控制台
2. 左侧菜单 > 网络与安全 > 安全组
3. 选择实例的安全组
4. 入站规则 > 编辑入站规则
5. 添加规则：
   - 类型: 自定义 TCP
   - 端口: 您的端口
   - 源: `0.0.0.0/0`

### 其他云服务商

类似的，在安全组/防火墙规则中开放您选择的 TCP 端口。

## 📱 客户端配置

### 1. 下载客户端

**Android**
- [v2rayNG](https://github.com/2dust/v2rayNG/releases) ⭐推荐

**iOS**
- Shadowrocket (App Store, 付费)

**Windows**
- [v2rayN](https://github.com/2dust/v2rayN/releases)

**macOS**
- [V2rayU](https://github.com/yanue/V2rayU/releases)

### 2. 导入配置

安装完成后，会显示 VLESS 分享链接，类似：

```
vless://uuid@domain:port?...
```

**导入步骤**：

1. 复制整个 VLESS 链接
2. 打开客户端应用
3. 点击 "+" 或 "添加配置"
4. 选择 "从剪贴板导入"
5. 连接

### 3. 查看配置信息

如果忘记了配置信息，在服务器上执行：

```bash
cat /root/xray-client-config.txt
```

## ✅ 测试连接

1. 在客户端连接 VPN
2. 访问 https://ip.sb 查看IP是否变成服务器IP
3. 访问 Google 测试是否能正常访问

## 🔧 常用管理命令

```bash
# 查看服务状态
systemctl status xray

# 重启服务
systemctl restart xray

# 查看实时日志
journalctl -u xray -f

# 查看配置信息
cat /root/xray-client-config.txt
```

## ❗ 常见问题

### 无法连接

1. **检查云防火墙** - 最常见的问题！
   ```bash
   # 在服务器上测试端口是否开放
   sudo netstat -tlnp | grep xray
   ```

2. **检查服务状态**
   ```bash
   sudo systemctl status xray
   ```

3. **检查时间同步**
   ```bash
   # 客户端和服务器时间误差不能超过90秒
   date
   ```

4. **查看日志**
   ```bash
   sudo journalctl -u xray -n 50
   ```

### 连接慢

1. 尝试更换端口重新部署
2. 考虑启用 BBR 加速：
   ```bash
   echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
   echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

### 更换端口或配置

重新运行安装脚本即可：

```bash
sudo bash install.sh
```

脚本会自动覆盖旧配置。

## 🔐 安全建议

1. ✅ 使用随机高端口（脚本默认）
2. ✅ 定期更换端口和 UUID
3. ✅ 不要在公开场合分享配置
4. ✅ 定期查看日志，发现异常及时处理
5. ✅ 如果只有固定 IP 使用，可以在防火墙限制源 IP

## 📊 性能优化

### 启用 BBR（推荐）

```bash
# 检查内核版本（需要 4.9+）
uname -r

# 启用 BBR
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 验证
sysctl net.ipv4.tcp_congestion_control
# 应该输出: net.ipv4.tcp_congestion_control = bbr
```

### 优化系统参数

```bash
# 增加文件描述符限制
echo "* soft nofile 51200" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 51200" | sudo tee -a /etc/security/limits.conf

# 重启生效
sudo reboot
```

## 🗑️ 卸载

如果需要卸载：

```bash
# 下载卸载脚本
wget https://raw.githubusercontent.com/rwubarhblp516/xray-auto-deploy/main/uninstall.sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```

## 💡 小贴士

1. **多服务器**: 可以在多台服务器部署，客户端配置多个节点自动切换
2. **备份配置**: 建议保存 `/root/xray-client-config.txt` 到本地
3. **监控流量**: 使用 `vnstat` 监控流量使用情况
4. **域名解析**: 如果使用域名，确保 DNS 解析正确指向服务器 IP

## 📞 获取帮助

- 查看完整文档: [README.md](README.md)
- 提交问题: [GitHub Issues](https://github.com/rwubarhblp516/xray-auto-deploy/issues)
- Xray 官方文档: https://xtls.github.io/

## 🎉 完成

恭喜！您已经成功部署了 Xray VPN。

享受自由的互联网吧！🚀
