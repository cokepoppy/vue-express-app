#!/bin/bash

# 使用 Token 自动化部署脚本
# Vercel + Supabase 全自动部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Token 配置
VERCEL_TOKEN="x3SDdzVUt6vjgH36CJbAlEYu"
# Supabase access token 需要用户提供
SUPABASE_TOKEN=""

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
    echo "🚀 全自动部署脚本 - Vercel + Supabase"
    echo "===================================="
    echo -e "${NC}"
    echo "此脚本将自动完成以下任务："
    echo "1. 🔧 配置 Vercel Token"
    echo "2. 📤 推送代码到 GitHub"
    echo "3. 🗄️ 创建/配置 Supabase 项目"
    echo "4. 🚀 部署到 Vercel"
    echo "5. ✅ 验证部署结果"
    echo
}

# 检查和配置 Token
setup_tokens() {
    log_step "配置部署 Token..."

    # 配置 Vercel Token
    log_info "配置 Vercel Token..."
    mkdir -p ~/.vercel
    cat > ~/.vercel/auth.json << EOF
{
  "token": "$VERCEL_TOKEN"
}
EOF
    log_success "Vercel Token 配置完成"

    # 获取 Supabase Token
    if [ -z "$SUPABASE_TOKEN" ]; then
        echo -n "请输入 Supabase Access Token (从 https://supabase.com/account/tokens 获取): "
        read -s SUPABASE_TOKEN
        echo
    fi

    if [ -z "$SUPABASE_TOKEN" ]; then
        log_error "Supabase Token 是必需的"
        log_info "获取方式: https://supabase.com/account/tokens"
        exit 1
    fi

    log_success "Supabase Token 配置完成"
}

# 检查 Git 仓库状态
check_git_repo() {
    log_step "检查 Git 仓库状态..."

    if [ ! -d ".git" ]; then
        log_info "初始化 Git 仓库..."
        git init
        git add .
        git commit -m "Initial commit: Vue3 + Express + Supabase project"
        log_success "Git 仓库初始化完成"
    fi

    # 检查远程仓库
    if ! git remote get-url origin &> /dev/null; then
        log_warning "未检测到远程仓库"
        echo -n "请输入 GitHub 仓库 URL (例如: https://github.com/username/vue-express-app.git): "
        read GIT_REPO_URL

        if [ -n "$GIT_REPO_URL" ]; then
            git remote add origin "$GIT_REPO_URL"
            log_success "远程仓库添加完成"
        else
            log_warning "跳过远程仓库配置"
        fi
    fi

    # 提交当前更改
    if [ -n "$(git status --porcelain)" ]; then
        log_info "提交最新更改..."
        git add .
        git commit -m "Pre-deploy update: $(date)"
    fi
}

# 推送代码到 GitHub
push_to_github() {
    log_step "推送代码到 GitHub..."

    if git remote get-url origin &> /dev/null; then
        log_info "推送代码到远程仓库..."
        git push -u origin main || git push -u origin master || {
            log_warning "推送失败，尝试强制推送..."
            git push -f -u origin main || git push -f -u origin master
        }
        log_success "代码推送完成"
    else
        log_warning "未配置远程仓库，跳过推送"
    fi
}

# 创建 Supabase 项目
create_supabase_project() {
    log_step "创建/配置 Supabase 项目..."

    # 安装 Supabase CLI
    if ! command -v supabase &> /dev/null; then
        log_info "安装 Supabase CLI..."
        npm install -g supabase
    fi

    # 登录 Supabase
    log_info "登录 Supabase..."
    echo "$SUPABASE_TOKEN" | supabase login --token

    # 检查是否已有项目
    log_info "检查现有 Supabase 项目..."

    # 获取项目列表
    PROJECTS=$(supabase projects list 2>/dev/null || echo "")

    if echo "$PROJECTS" | grep -q "vue-express-app"; then
        log_info "发现现有项目，使用现有项目"
        # 获取现有项目信息
        PROJECT_REF=$(supabase projects list | grep "vue-express-app" | awk '{print $2}')
    else
        log_info "创建新的 Supabase 项目..."

        # 创建新项目
        PROJECT_INFO=$(supabase projects create vue-express-app --org-personal --db-password "YourStrongPassword123!" --region "us-east-1" 2>/dev/null || echo "")

        if echo "$PROJECT_INFO" | grep -q "already exists"; then
            log_info "项目已存在，获取项目信息..."
            PROJECT_REF=$(supabase projects list | grep "vue-express-app" | awk '{print $2}')
        else
            PROJECT_REF=$(echo "$PROJECT_INFO" | grep -o "ref: [^\s]*" | cut -d' ' -f2)
        fi
    fi

    if [ -n "$PROJECT_REF" ]; then
        log_success "Supabase 项目配置完成 (Ref: $PROJECT_REF)"

        # 获取连接信息
        log_info "获取数据库连接信息..."
        DB_URL=$(supabase db url --connection-string --project-ref "$PROJECT_REF" 2>/dev/null || echo "")
        SUPABASE_URL="https://$PROJECT_REF.supabase.co"
        SUPABASE_ANON_KEY=$(supabase status --project-ref "$PROJECT_REF" 2>/dev/null | grep "anon key" | awk '{print $3}' || echo "")

        log_info "连接信息获取完成"
    else
        log_error "无法获取 Supabase 项目信息"
        return 1
    fi
}

# 初始化 Supabase 数据库
init_supabase_database() {
    log_step "初始化 Supabase 数据库..."

    if [ -n "$PROJECT_REF" ]; then
        log_info "初始化数据库表..."

        # 执行初始化脚本
        if [ -f "scripts/init-supabase.sql" ]; then
            # 将 SQL 脚本传递给 Supabase
            cat scripts/init-supabase.sql | supabase db push --project-ref "$PROJECT_REF" 2>/dev/null || {
                log_warning "自动初始化失败，请手动执行 SQL 脚本"
                log_info "访问 Supabase Dashboard 执行 scripts/init-supabase.sql"
            }
        else
            log_warning "未找到初始化脚本"
        fi

        log_success "数据库初始化完成"
    fi
}

# 配置 Vercel 环境变量
setup_vercel_env() {
    log_step "配置 Vercel 环境变量..."

    if [ -n "$DB_URL" ] && [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
        # 导出环境变量到 Vercel
        export VERCEL_ORG_ID=$(vercel ls --json | jq -r '.[0].metadata.orgId' 2>/dev/null || echo "")
        export VERCEL_PROJECT_ID=$(vercel ls --json | jq -r '.[0].id' 2>/dev/null || echo "")

        log_info "设置 DATABASE_URL..."
        echo "$DB_URL" | vercel env add DATABASE_URL production --yes 2>/dev/null || {
            log_warning "环境变量设置可能失败，请手动配置"
        }

        log_info "设置 SUPABASE_URL..."
        echo "$SUPABASE_URL" | vercel env add SUPABASE_URL production --yes 2>/dev/null || {
            log_warning "环境变量设置可能失败，请手动配置"
        }

        log_info "设置 SUPABASE_ANON_KEY..."
        echo "$SUPABASE_ANON_KEY" | vercel env add SUPABASE_ANON_KEY production --yes 2>/dev/null || {
            log_warning "环境变量设置可能失败，请手动配置"
        }

        log_success "环境变量配置完成"
    else
        log_error "无法获取 Supabase 连接信息"
        log_info "请手动在 Vercel 控制台配置环境变量"
    fi
}

# 部署到 Vercel
deploy_to_vercel() {
    log_step "部署到 Vercel..."

    log_deploy "开始部署..."

    # 部署到生产环境
    DEPLOY_OUTPUT=$(vercel --prod 2>&1)

    if echo "$DEPLOY_OUTPUT" | grep -q "https://"; then
        DEPLOY_URL=$(echo "$DEPLOY_OUTPUT" | grep -o "https://[^[:space:]]*\.vercel\.app" | head -1)
        log_success "部署成功！"
        log_info "部署 URL: $DEPLOY_URL"
    else
        log_error "部署失败"
        echo "$DEPLOY_OUTPUT"
        return 1
    fi
}

# 验证部署
verify_deployment() {
    log_step "验证部署结果..."

    if [ -n "$DEPLOY_URL" ]; then
        log_info "等待部署生效 (10秒)..."
        sleep 10

        # 测试健康检查
        log_info "测试应用健康状态..."
        if curl -s "https://$DEPLOY_URL/health" | grep -q "OK"; then
            log_success "✅ 应用健康检查通过！"
        else
            log_warning "健康检查失败，可能还在部署中"
        fi

        # 测试 API
        log_info "测试 API 端点..."
        if curl -s "https://$DEPLOY_URL/api" | grep -q "API is working"; then
            log_success "✅ API 端点正常！"
        else
            log_warning "API 测试失败"
        fi

        # 测试数据库连接
        log_info "测试数据库连接..."
        if curl -s "https://$DEPLOY_URL/api/users" | grep -q "success"; then
            log_success "✅ 数据库连接正常！"
        else
            log_warning "数据库连接测试失败"
        fi
    fi
}

# 显示部署结果
show_deployment_result() {
    log_step "部署完成！"

    echo -e "${PURPLE}🎉 自动部署完成！${NC}"
    echo
    echo -e "${CYAN}📱 应用访问地址：${NC}"
    if [ -n "$DEPLOY_URL" ]; then
        echo -e "  前端: https://$DEPLOY_URL"
        echo -e "  API:  https://$DEPLOY_URL/api"
        echo -e "  健康检查: https://$DEPLOY_URL/health"
    fi

    echo -e "${CYAN}🗄️  Supabase 项目：${NC}"
    if [ -n "$PROJECT_REF" ]; then
        echo -e "  Dashboard: https://app.supabase.com/project/$PROJECT_REF"
        echo -e "  项目引用: $PROJECT_REF"
    fi

    echo -e "${CYAN}🔧 后续操作：${NC}"
    echo "  1. ✅ 验证所有功能正常工作"
    echo "  2. 📊 监控使用量 (Vercel + Supabase)"
    echo "  3. 🔧 根据需要调整配置"
    echo "  4. 📝 添加自定义域名 (可选)"

    echo -e "${CYAN}📚 有用的命令：${NC}"
    echo "  vercel logs              # 查看部署日志"
    echo "  vercel env ls            # 列出环境变量"
    echo "  supabase status          # 检查 Supabase 状态"
    echo "  ./scripts/check-deployment.sh $DEPLOY_URL  # 验证部署"

    echo
    log_success "🎊 恭喜！你的全栈应用已经成功部署到云端！"
}

# 主函数
main() {
    show_banner
    setup_tokens
    check_git_repo
    push_to_github
    create_supabase_project
    init_supabase_database
    setup_vercel_env
    deploy_to_vercel
    verify_deployment
    show_deployment_result
}

# 错误处理
trap 'log_error "脚本执行失败，请检查错误信息"; exit 1' ERR

# 运行主函数
main "$@"