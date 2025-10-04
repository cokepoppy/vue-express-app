#!/bin/bash

# 简化部署脚本 - Supabase 自动化 + Vercel 手动

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 显示横幅
show_banner() {
    echo -e "${PURPLE}"
    echo "🚀 Vue-Express 应用部署脚本"
    echo "Supabase 自动化 + Vercel 手动"
    echo "==============================="
    echo -e "${NC}"
}

# Supabase 配置
setup_supabase() {
    log_step "配置 Supabase"

    # 登录 Supabase
    log_info "登录 Supabase CLI..."
    supabase login --token sbp_aa77382a0da5e4051274b3cf6504e7d2ad6736f8

    # 检查现有项目
    log_info "检查现有项目..."
    PROJECTS=$(supabase projects list)

    if echo "$PROJECTS" | grep -q "zknwbnwkkfjslnkafsga"; then
        log_success "发现现有项目: zknwbnwkkfjslnkafsga"

        # 生成环境变量文件
        log_info "生成环境变量配置..."
        cat > .env.vercel << EOF
# Supabase 配置
SUPABASE_URL=https://zknwbnwkkfjslnkafsga.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inprbndibndra2Zqc2xua2Fmc2dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NTQxODksImV4cCI6MjA3NTEzMDE4OX0.DyOc4nI3VBLKS5I9vdZyB0LE0YlFZk9abXNzL8Nafkk

# 应用配置
NODE_ENV=production
PORT=5000
EOF

        log_success "环境变量文件已生成: .env.vercel"
    else
        log_info "未找到项目，请手动创建"
    fi
}

# Git 仓库准备
setup_git() {
    log_step "准备 Git 仓库"

    # 检查是否有远程仓库
    if ! git remote get-url origin &> /dev/null; then
        log_info "请创建 GitHub 仓库并连接:"
        echo "1. 访问 https://github.com/new"
        echo "2. 创建仓库: vue-express-app"
        echo "3. 运行: git remote add origin https://github.com/YOUR_USERNAME/vue-express-app.git"
        echo "4. 运行: git push -u origin main"
    else
        log_info "Git 远程仓库已配置"

        # 推送最新更改
        log_info "推送最新更改..."
        git add .
        git commit -m "chore: ready for deployment - $(date)" || true
        log_info "请手动推送: git push origin main"
    fi
}

# Vercel 部署指南
vercel_instructions() {
    log_step "Vercel 部署指南"

    echo -e "${YELLOW}Vercel 部署步骤:${NC}"
    echo "1. 访问 https://vercel.com"
    echo "2. 点击 'New Project'"
    echo "3. 连接 GitHub 仓库: vue-express-app"
    echo "4. 在环境变量中添加 .env.vercel 中的内容"
    echo "5. 点击 'Deploy'"
    echo

    echo -e "${YELLOW}环境变量配置:${NC}"
    cat .env.vercel
    echo

    echo -e "${YELLOW}部署完成后测试:${NC}"
    echo "curl https://your-app-name.vercel.app/health"
    echo "curl https://your-app-name.vercel.app/api/users"
}

# 主函数
main() {
    show_banner
    setup_supabase
    setup_git
    vercel_instructions

    log_success "🎉 部署准备完成！"
    echo -e "${GREEN}现在可以按照上述步骤部署到 Vercel 了！${NC}"
}

main "$@"