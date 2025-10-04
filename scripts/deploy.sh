#!/bin/bash

# 自动化部署脚本 - Vercel + Supabase
# 这个脚本帮助你快速部署应用到云端

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${NC}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_deploy() {
    echo -e "${PURPLE}[DEPLOY]${NC} $1"
}

# 显示横幅
show_banner() {
    echo -e "${PURPLE}"
    echo "🚀 Vercel + Supabase 自动化部署脚本"
    echo "======================================"
    echo -e "${NC}"
}

# 检查部署前置条件
check_prerequisites() {
    log_step "检查部署前置条件..."

    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装"
        exit 1
    fi
    log_success "Node.js: $(node --version)"

    # 检查 git
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装"
        exit 1
    fi
    log_success "Git: $(git --version)"

    # 检查 Vercel CLI
    if ! command -v vercel &> /dev/null; then
        log_warning "Vercel CLI 未安装，正在安装..."
        npm install -g vercel
    fi
    log_success "Vercel CLI: $(vercel --version)"

    # 检查是否在 git 仓库中
    if [ ! -d ".git" ]; then
        log_warning "当前目录不是 Git 仓库，正在初始化..."
        git init
        git add .
        git commit -m "Initial commit: Vue3 + Express + Supabase project"
        log_info "请手动添加远程仓库："
        log_info "git remote add origin https://github.com/yourusername/vue-express-app.git"
        log_info "git push -u origin main"
        read -p "按回车键继续..."
    else
        # 检查是否有未提交的更改
        if [ -n "$(git status --porcelain)" ]; then
            log_warning "检测到未提交的更改，正在提交..."
            git add .
            git commit -m "Pre-deploy update: $(date)"
        fi
    fi
}

# 检查项目配置
check_project_config() {
    log_step "检查项目配置..."

    # 检查必要文件
    local required_files=(
        "vercel.json"
        "package.json"
        "frontend/package.json"
        "api/package.json"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "缺少必要文件: $file"
            exit 1
        fi
    done

    log_success "项目配置检查通过"
}

# 验证环境变量
validate_env_vars() {
    log_step "验证环境变量配置..."

    # 检查前端环境变量
    if [ -f "frontend/.env.production" ]; then
        log_success "前端生产环境变量文件存在"
    else
        log_warning "前端 .env.production 不存在，将使用默认配置"
    fi

    # 提示用户配置云端环境变量
    log_info "请确保在 Vercel 中配置以下环境变量："
    echo -e "${YELLOW}"
    echo "- DATABASE_URL (Supabase PostgreSQL 连接字符串)"
    echo "- SUPABASE_URL (Supabase API URL)"
    echo "- SUPABASE_ANON_KEY (Supabase 匿名密钥)"
    echo "- UPSTASH_REDIS_REST_URL (Upstash Redis URL)"
    echo "- UPSTASH_REDIS_REST_TOKEN (Upstash Redis 密钥)"
    echo "- NODE_ENV=production"
    echo -e "${NC}"
}

# 部署到 Vercel
deploy_to_vercel() {
    log_step "部署到 Vercel..."

    # 检查是否已登录 Vercel
    if ! vercel whoami &> /dev/null; then
        log_info "需要登录 Vercel..."
        vercel login
    fi

    # 部署
    log_deploy "开始部署到 Vercel..."
    vercel --prod

    log_success "Vercel 部署完成！"
}

# 验证部署
verify_deployment() {
    log_step "验证部署..."

    # 获取部署 URL
    DEPLOY_URL=$(vercel ls --scope $(vercel whoami | grep 'Email' | awk '{print $3}') 2>/dev/null | head -1 | awk '{print $2}' || echo "")

    if [ -z "$DEPLOY_URL" ]; then
        log_warning "无法获取部署 URL，请手动检查"
        return
    fi

    log_info "部署 URL: https://$DEPLOY_URL"

    # 等待部署生效
    log_info "等待部署生效 (10秒)..."
    sleep 10

    # 测试健康检查
    log_info "测试应用健康状态..."
    if curl -s "https://$DEPLOY_URL/health" > /dev/null; then
        log_success "✅ 应用部署成功！"
        log_info "前端: https://$DEPLOY_URL"
        log_info "API: https://$DEPLOY_URL/api"
    else
        log_warning "部署可能还在进行中，请稍后手动检查"
    fi
}

# 显示部署后信息
show_post_deploy_info() {
    log_step "部署后操作指南..."

    echo -e "${PURPLE}🎉 部署完成！${NC}"
    echo
    echo -e "${CYAN}接下来的步骤：${NC}"
    echo "1. ✅ 在 Vercel 控制台配置环境变量"
    echo "2. 🔄 重新部署以应用环境变量"
    echo "3. 🧪 测试 API 功能"
    echo "4. 📊 监控应用状态"
    echo
    echo -e "${CYAN}常用命令：${NC}"
    echo "- vercel --prod              # 重新部署"
    echo "- vercel logs                # 查看日志"
    echo "- vercel env ls              # 列出环境变量"
    echo "- vercel env add VAR_NAME    # 添加环境变量"
    echo
    echo -e "${CYAN}测试端点：${NC}"
    echo "- 健康检查: https://your-domain.vercel.app/health"
    echo "- API 根路径: https://your-domain.vercel.app/api"
    echo "- 用户 API: https://your-domain.vercel.app/api/users"
    echo "- 缓存测试: https://your-domain.vercel.app/api/examples/cache-test"
    echo
}

# 创建部署检查脚本
create_deploy_check_script() {
    log_step "创建部署检查脚本..."

    cat > scripts/check-deployment.sh << 'EOF'
#!/bin/bash

# 部署检查脚本

DEPLOY_URL=$1

if [ -z "$DEPLOY_URL" ]; then
    echo "使用方法: ./check-deployment.sh <your-domain.vercel.app>"
    exit 1
fi

echo "🔍 检查部署: https://$DEPLOY_URL"
echo "================================"

# 检查主页
echo -n "检查主页..."
if curl -s "https://$DEPLOY_URL" | grep -q "Vue3"; then
    echo " ✅ 成功"
else
    echo " ❌ 失败"
fi

# 检查健康检查
echo -n "检查健康检查..."
if curl -s "https://$DEPLOY_URL/health" | grep -q "OK"; then
    echo " ✅ 成功"
else
    echo " ❌ 失败"
fi

# 检查 API 根路径
echo -n "检查 API..."
if curl -s "https://$DEPLOY_URL/api" | grep -q "API is working"; then
    echo " ✅ 成功"
else
    echo " ❌ 失败"
fi

# 检查用户 API
echo -n "检查用户 API..."
if curl -s "https://$DEPLOY_URL/api/users" | grep -q "success"; then
    echo " ✅ 成功"
else
    echo " ❌ 失败"
fi

# 检查缓存 API
echo -n "检查缓存 API..."
if curl -s "https://$DEPLOY_URL/api/examples/cache-test" | grep -q "success"; then
    echo " ✅ 成功"
else
    echo " ❌ 失败"
fi

echo "================================"
echo "🎉 检查完成！"
EOF

    chmod +x scripts/check-deployment.sh
    log_success "部署检查脚本已创建: scripts/check-deployment.sh"
}

# 主函数
main() {
    show_banner

    log_info "开始自动化部署流程..."

    check_prerequisites
    check_project_config
    validate_env_vars
    deploy_to_vercel
    verify_deployment
    create_deploy_check_script
    show_post_deploy_info

    log_success "🎉 部署流程完成！"
}

# 运行主函数
main "$@"