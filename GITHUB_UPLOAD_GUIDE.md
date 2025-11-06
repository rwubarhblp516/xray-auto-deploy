# GitHub 上传指南

本文档介绍如何将此项目上传到 GitHub。

## 前提条件

1. 拥有 GitHub 账号
2. 服务器上已安装 git

## 步骤

### 1. 安装 Git（如果未安装）

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y git

# CentOS
sudo yum install -y git
```

### 2. 配置 Git

```bash
# 配置用户名和邮箱
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. 在 GitHub 创建仓库

1. 登录 [GitHub](https://github.com)
2. 点击右上角 "+" 号，选择 "New repository"
3. 填写仓库信息:
   - Repository name: `xray-auto-deploy`
   - Description: `一键部署 Xray VPN (VLESS + Reality)`
   - 选择 **Public** (公开) 或 **Private** (私有)
   - **不要**勾选 "Add a README file"（我们已经有了）
4. 点击 "Create repository"

### 4. 初始化本地仓库

```bash
# 进入项目目录
cd ~/xray-auto-deploy

# 初始化 git 仓库
git init

# 添加所有文件
git add .

# 提交到本地仓库
git commit -m "Initial commit: Xray VPN auto deploy script"
```

### 5. 连接到 GitHub 远程仓库

将 `rwubarhblp516` 替换为您的 GitHub 用户名：

```bash
# 添加远程仓库
git remote add origin https://github.com/rwubarhblp516/xray-auto-deploy.git

# 或使用 SSH（推荐，需要先配置 SSH key）
git remote add origin git@github.com:rwubarhblp516/xray-auto-deploy.git
```

### 6. 推送到 GitHub

```bash
# 推送到远程仓库
git branch -M main
git push -u origin main
```

如果使用 HTTPS 方式，需要输入 GitHub 用户名和密码（或 Personal Access Token）。

## 配置 SSH Key（推荐）

使用 SSH 可以避免每次推送都输入密码。

### 1. 生成 SSH Key

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

一路回车，使用默认设置。

### 2. 查看公钥

```bash
cat ~/.ssh/id_ed25519.pub
```

复制输出的内容。

### 3. 添加到 GitHub

1. 登录 GitHub
2. 点击右上角头像 > Settings
3. 左侧菜单选择 "SSH and GPG keys"
4. 点击 "New SSH key"
5. Title: 随意填写（如 "My Server"）
6. Key: 粘贴刚才复制的公钥
7. 点击 "Add SSH key"

### 4. 测试连接

```bash
ssh -T git@github.com
```

看到 "Hi username! You've successfully authenticated..." 表示成功。

## 更新 README 中的链接

编辑 `README.md`，将所有 `rwubarhblp516` 替换为您的 GitHub 用户名：

```bash
cd ~/xray-auto-deploy
sed -i 's/rwubarhblp516/你的GitHub用户名/g' README.md
git add README.md
git commit -m "Update GitHub username in README"
git push
```

## 后续更新

当您修改了脚本或文档后，使用以下命令更新到 GitHub：

```bash
cd ~/xray-auto-deploy

# 查看修改的文件
git status

# 添加修改的文件
git add .

# 提交修改
git commit -m "描述你的修改"

# 推送到 GitHub
git push
```

## 使用 Personal Access Token

如果使用 HTTPS 方式，GitHub 现在要求使用 Personal Access Token 而非密码。

### 创建 Token

1. 登录 GitHub
2. Settings > Developer settings > Personal access tokens > Tokens (classic)
3. Generate new token (classic)
4. 勾选 `repo` 权限
5. 生成并复制 token（注意保存，只显示一次）

### 使用 Token

推送时，用户名输入 GitHub 用户名，密码处输入 token。

或者配置 credential helper：

```bash
git config --global credential.helper store
```

第一次输入 token 后会保存，以后不用再输入。

## 常见问题

### 1. 推送被拒绝

```bash
# 如果远程仓库有更新，先拉取
git pull origin main --rebase

# 然后再推送
git push
```

### 2. 删除远程仓库重新上传

```bash
# 删除远程连接
git remote remove origin

# 重新添加
git remote add origin https://github.com/rwubarhblp516/xray-auto-deploy.git

# 强制推送（谨慎使用）
git push -u origin main --force
```

### 3. 忽略某些文件

编辑 `.gitignore` 文件，添加要忽略的文件或目录。

## 完成

现在您的项目已经在 GitHub 上了！

访问地址: `https://github.com/rwubarhblp516/xray-auto-deploy`

其他人可以使用以下命令快速部署：

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/rwubarhblp516/xray-auto-deploy/main/install.sh)"
```

## 进阶：添加 GitHub Actions（可选）

您可以添加 CI/CD 流程，自动检查脚本语法等。创建 `.github/workflows/test.yml`：

```yaml
name: Test Script

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check shell scripts
        run: |
          sudo apt-get install -y shellcheck
          shellcheck install.sh uninstall.sh
```

这会在每次推送时自动检查脚本语法。
