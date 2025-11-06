#!/bin/bash

# Xray VPN 一键部署脚本
# 支持 VLESS + Reality 协议
# 适用于 Ubuntu/Debian 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本必须以root权限运行"
        print_info "请使用: sudo bash install.sh"
        exit 1
    fi
}

# 检测系统
check_system() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    else
        print_error "不支持的操作系统"
        exit 1
    fi
    print_success "检测到系统: $release"
}

# 安装依赖
install_dependencies() {
    print_info "安装必要的依赖包..."

    if [[ "$release" == "ubuntu" ]] || [[ "$release" == "debian" ]]; then
        apt-get update -y
        apt-get install -y curl wget unzip tar openssl ufw
    elif [[ "$release" == "centos" ]]; then
        yum install -y curl wget unzip tar openssl firewalld
    fi

    print_success "依赖安装完成"
}

# 生成随机端口
generate_port() {
    local port
    while true; do
        port=$(shuf -i 10000-60000 -n 1)
        if ! netstat -tuln | grep -q ":$port "; then
            echo "$port"
            return
        fi
    done
}

# 安装 Xray
install_xray() {
    print_info "开始安装 Xray-core..."

    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install

    print_success "Xray-core 安装完成"
}

# 生成配置
generate_config() {
    print_info "生成配置文件..."

    # 生成 UUID
    UUID=$(xray uuid)
    print_info "生成 UUID: $UUID"

    # 生成 X25519 密钥对
    KEYS=$(xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | awk '{print $3}')
    print_info "生成密钥对"

    # 生成 Short ID
    SHORT_ID=$(openssl rand -hex 8)
    print_info "生成 Short ID: $SHORT_ID"

    # 获取服务器IP
    SERVER_IP=$(curl -s ifconfig.me)
    if [[ -z "$SERVER_IP" ]]; then
        SERVER_IP=$(curl -s ip.sb)
    fi
    print_info "服务器IP: $SERVER_IP"

    # 询问端口
    echo ""
    read -p "请输入监听端口 (留空则随机生成 10000-60000): " PORT
    if [[ -z "$PORT" ]]; then
        PORT=$(generate_port)
        print_info "随机生成端口: $PORT"
    fi

    # 询问域名
    echo ""
    read -p "请输入您的域名 (留空则使用IP): " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        DOMAIN="$SERVER_IP"
    fi
    print_info "使用地址: $DOMAIN"

    # 询问伪装站点
    echo ""
    print_info "选择伪装站点 (Reality 协议会伪装成访问此站点):"
    echo "1. www.microsoft.com (推荐)"
    echo "2. www.cloudflare.com"
    echo "3. www.apple.com"
    echo "4. 自定义"
    read -p "请选择 [1-4, 默认1]: " DEST_CHOICE

    case $DEST_CHOICE in
        2)
            DEST_SITE="www.cloudflare.com"
            ;;
        3)
            DEST_SITE="www.apple.com"
            ;;
        4)
            read -p "请输入自定义域名: " DEST_SITE
            ;;
        *)
            DEST_SITE="www.microsoft.com"
            ;;
    esac
    print_info "伪装站点: $DEST_SITE"

    # 创建配置文件
    cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$DEST_SITE:443",
          "xver": 0,
          "serverNames": [
            "$DEST_SITE"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "block"
      }
    ]
  }
}
EOF

    print_success "配置文件生成完成"
}

# 配置防火墙
configure_firewall() {
    print_info "配置防火墙..."

    if command -v ufw &> /dev/null; then
        # UFW (Ubuntu/Debian)
        ufw allow 22/tcp > /dev/null 2>&1
        ufw allow $PORT/tcp > /dev/null 2>&1
        echo "y" | ufw enable > /dev/null 2>&1
        print_success "UFW 防火墙配置完成"
    elif command -v firewall-cmd &> /dev/null; then
        # Firewalld (CentOS)
        firewall-cmd --permanent --add-port=22/tcp > /dev/null 2>&1
        firewall-cmd --permanent --add-port=$PORT/tcp > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
        print_success "Firewalld 防火墙配置完成"
    else
        print_warning "未检测到防火墙，跳过配置"
    fi
}

# 启动服务
start_service() {
    print_info "启动 Xray 服务..."

    systemctl restart xray
    systemctl enable xray

    sleep 2

    if systemctl is-active --quiet xray; then
        print_success "Xray 服务启动成功"
    else
        print_error "Xray 服务启动失败"
        print_info "查看日志: journalctl -u xray -n 50"
        exit 1
    fi
}

# 生成客户端配置
generate_client_config() {
    print_info "生成客户端配置..."

    # VLESS 分享链接
    VLESS_LINK="vless://$UUID@$DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$DEST_SITE&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#Xray-Reality-VPN"

    # 保存配置文件
    CONFIG_FILE="/root/xray-client-config.txt"

    cat > $CONFIG_FILE <<EOF
====================================
Xray VPN 客户端配置信息
====================================

协议: VLESS + XTLS-Reality
服务器地址: $DOMAIN
服务器IP: $SERVER_IP
端口: $PORT

UUID: $UUID
Flow: xtls-rprx-vision

Reality 配置:
- Public Key: $PUBLIC_KEY
- Short ID: $SHORT_ID
- SNI (Server Name): $DEST_SITE
- Fingerprint: chrome

====================================
VLESS 分享链接:
====================================
$VLESS_LINK

====================================
客户端软件推荐:
====================================

Android:
- v2rayNG: https://github.com/2dust/v2rayNG/releases
- NekoBox: https://github.com/MatsuriDayo/NekoBoxForAndroid/releases

iOS:
- Shadowrocket (App Store付费)
- Stash (App Store付费)

Windows:
- v2rayN: https://github.com/2dust/v2rayN/releases
- Clash Verge: https://github.com/clash-verge-rev/clash-verge-rev/releases

macOS:
- V2rayU: https://github.com/yanue/V2rayU/releases
- Clash Verge: https://github.com/clash-verge-rev/clash-verge-rev/releases

Linux:
- Qv2ray: https://github.com/Qv2ray/Qv2ray/releases

====================================
导入方法:
====================================

方法1: 复制分享链接
1. 复制上面的 VLESS 分享链接
2. 在客户端应用中选择"从剪贴板导入"

方法2: 手动配置
按照上面的配置信息手动填写各项参数

====================================
服务管理命令:
====================================

查看状态: systemctl status xray
重启服务: systemctl restart xray
停止服务: systemctl stop xray
查看日志: journalctl -u xray -f

配置文件: /usr/local/etc/xray/config.json
访问日志: /var/log/xray/access.log
错误日志: /var/log/xray/error.log

====================================
EOF

    print_success "客户端配置已保存到: $CONFIG_FILE"
}

# 显示配置信息
show_config() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Xray VPN 安装成功！${NC}"
    echo "=========================================="
    echo ""
    echo -e "${BLUE}服务器信息:${NC}"
    echo "  地址: $DOMAIN"
    echo "  端口: $PORT"
    echo "  协议: VLESS + Reality"
    echo ""
    echo -e "${BLUE}VLESS 分享链接:${NC}"
    echo -e "${YELLOW}$VLESS_LINK${NC}"
    echo ""
    echo -e "${BLUE}详细配置:${NC}"
    echo "  配置文件已保存到: /root/xray-client-config.txt"
    echo "  查看命令: cat /root/xray-client-config.txt"
    echo ""
    echo -e "${BLUE}管理命令:${NC}"
    echo "  查看状态: systemctl status xray"
    echo "  重启服务: systemctl restart xray"
    echo "  查看日志: journalctl -u xray -f"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    clear
    echo "=========================================="
    echo "       Xray VPN 一键部署脚本"
    echo "       VLESS + Reality 协议"
    echo "=========================================="
    echo ""

    check_root
    check_system
    install_dependencies
    install_xray
    generate_config
    configure_firewall
    start_service
    generate_client_config
    show_config

    print_success "部署完成！"
}

# 运行主函数
main
