#!/bin/bash

# Xray VPN 卸载脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查是否为root
if [[ $EUID -ne 0 ]]; then
    print_error "此脚本必须以root权限运行"
    print_info "请使用: sudo bash uninstall.sh"
    exit 1
fi

clear
echo "=========================================="
echo "       Xray VPN 卸载脚本"
echo "=========================================="
echo ""
print_warning "此操作将完全删除 Xray 及其配置文件"
echo ""
read -p "确认要继续吗? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_info "已取消卸载"
    exit 0
fi

echo ""
print_info "开始卸载..."

# 停止服务
if systemctl is-active --quiet xray; then
    print_info "停止 Xray 服务..."
    systemctl stop xray
    systemctl disable xray
    print_success "服务已停止"
fi

# 卸载 Xray
if command -v xray &> /dev/null; then
    print_info "卸载 Xray-core..."
    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) remove --purge
    print_success "Xray-core 已卸载"
fi

# 删除配置文件
print_info "删除配置文件..."
rm -rf /usr/local/etc/xray
rm -rf /var/log/xray
rm -f /root/xray-client-config.txt
print_success "配置文件已删除"

# 删除防火墙规则（可选）
read -p "是否删除防火墙规则? (y/N): " remove_fw

if [[ "$remove_fw" =~ ^[Yy]$ ]]; then
    print_info "注意: 请手动删除相关端口的防火墙规则"
    print_info "UFW: ufw status numbered, then ufw delete <number>"
    print_info "Firewalld: firewall-cmd --list-ports"
fi

echo ""
print_success "卸载完成！"
echo "=========================================="
