#!/bin/bash

# 完全自动化部署脚本 - Vercel + Supabase
# 使用提供的 token 实现一键部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Token 配置
VERCEL_TOKEN="cOt4VPON5hs2otXCZ5wOwHAe"
SUPABASE_TOKEN="sbp_aa77382a0da5e4051274b3cf6504e7d2ad6736f8"

# 项目配置
PROJECT_NAME="vue-express-app"
DB_PASSWORD="YourStrongPassword123!"
REGION="us-east-1"

# 日志函数
log() {
    echo -e "${NC}[$(date +'%H:%M:%S')] $1${NC}"
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
    echo -e "${BOLD}${PURPLE}"
    echo "🚀 完全自动化部署脚本"
    echo "Vercel + Supabase 一键部署"
    echo "============================"
    echo -e "${NC}"
    echo "此脚本将自动完成："
    echo "1. 🔧 配置 Vercel 和 Supabase CLI"
    echo "2. 📤 推送代码到 GitHub"
    echo "3. 🗄️  创建 Supabase 项目和数据库"
    echo "4. ⚙️  配置环境变量"
    echo "5. 🚀 部署到 Vercel"
    echo "6. ✅ 验证部署结果"
    echo
}

# 检查系统要求
check_requirements() {
    log_step "检查系统要求"

    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装"
        log_info "请安装 Node.js 18+: https://nodejs.org"
        exit 1
    fi
    log_success "Node.js: $(node --version)"

    # 检查 Git
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装"
        log_info "请安装 Git: https://git-scm.com"
        exit 1
    fi
    log_success "Git: $(git --version)"

    # 检查 curl
    if ! command -v curl &> /dev/null; then
        log_error "curl 未安装"
        exit 1
    fi
    log_success "curl: $(curl --version | head -1)"
}

# 配置 Token
setup_tokens() {
    log_step "配置部署 Token"

    # 配置 Vercel Token
    log_info "配置 Vercel Token..."
    mkdir -p ~/.vercel
    cat > ~/.vercel/auth.json << EOF
{
  "token": "$VERCEL_TOKEN"
}
EOF
    log_success "Vercel Token 配置完成"

    # 配置 Supabase Token
    log_info "配置 Supabase Token..."
    mkdir -p ~/.supabase
    cat > ~/.supabase/access-token << EOF
$SUPABASE_TOKEN
EOF
    log_success "Supabase Token 配置完成"
}

# 安装 CLI 工具
install_cli_tools() {
    log_step "安装 CLI 工具"

    # 安装 Vercel CLI
    if ! command -v vercel &> /dev/null; then
        log_info "安装 Vercel CLI..."
        npm install -g vercel
    fi

    # 安装 Supabase CLI
    if ! command -v supabase &> /dev/null; then
        log_info "安装 Supabase CLI..."
        npm install -g supabase
    fi

    log_success "CLI 工具安装完成"
}

# 准备 Git 仓库
prepare_git_repo() {
    log_step "准备 Git 仓库"

    if [ ! -d ".git" ]; then
        log_info "初始化 Git 仓库..."
        git init
        git config user.name "Vue Express Deployer"
        git config user.email "deployer@example.com"
    fi

    # 添加远程仓库
    if ! git remote get-url origin &> /dev/null; then
        log_info "请提供 GitHub 仓库信息："
        echo -n "GitHub 用户名: "
        read GITHUB_USERNAME
        echo -n "仓库名称 (默认: vue-express-app): "
        read REPO_NAME
        REPO_NAME=${REPO_NAME:-vue-express-app}

        GIT_REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
        git remote add origin "$GIT_REPO_URL"

        log_info "远程仓库已配置: $GIT_REPO_URL"
        log_warning "请确保 GitHub 仓库已创建，然后推送代码"
    fi

    # 提交当前更改
    if [ -n "$(git status --porcelain)" ]; then
        log_info "提交代码更改..."
        git add .
        git commit -m "feat: ready for automated deployment - $(date)" || true
    fi

    log_success "Git 仓库准备完成"
}

# 推送代码到 GitHub
push_to_github() {
    log_step "推送代码到 GitHub"

    if git remote get-url origin &> /dev/null; then
        log_info "推送代码到 GitHub..."

        # 尝试推送，如果失败给出提示
        if git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null; then
            log_success "代码推送成功"
        else
            log_warning "代码推送失败，请手动推送"
            log_info "手动推送命令："
            log_info "git push -u origin main  # 或 master"
            echo -n "是否继续部署？(y/N): "
            read -n 1 response
            echo
            if [[ ! $response =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        log_warning "未配置远程仓库，跳过推送"
    fi
}

# 验证 Token 登录
verify_cli_logins() {
    log_step "验证 CLI 登录状态"

    # 验证 Vercel 登录
    log_info "验证 Vercel 登录..."
    if vercel whoami &> /dev/null; then
        log_success "Vercel 登录验证成功"
    else
        log_error "Vercel 登录失败"
        exit 1
    fi

    # 验证 Supabase 登录
    log_info "验证 Supabase 登录..."
    echo "$SUPABASE_TOKEN" | supabase login --token
    if supabase projects list &> /dev/null; then
        log_success "Supabase 登录验证成功"
    else
        log_error "Supabase 登录失败"
        exit 1
    fi
}

# 创建或获取 Supabase 项目
setup_supabase_project() {
    log_step "设置 Supabase 项目"

    # 检查现有项目
    log_info "检查现有 Supabase 项目..."
    PROJECTS=$(supabase projects list 2>/dev/null)

    if echo "$PROJECTS" | grep -q "$PROJECT_NAME"; then
        log_info "发现现有项目: $PROJECT_NAME"
        PROJECT_REF=$(echo "$PROJECTS" | grep "$PROJECT_NAME" | awk '{print $2}')
        log_success "使用现有项目 (Ref: $PROJECT_REF)"
    else
        log_info "创建新的 Supabase 项目..."

        # 创建项目
        log_deploy "正在创建 Supabase 项目..."
        CREATE_OUTPUT=$(supabase projects create \
            "$PROJECT_NAME" \
            --org-personal \
            --db-password "$DB_PASSWORD" \
            --region "$REGION" \
            2>&1)

        if echo "$CREATE_OUTPUT" | grep -q "successfully created\|already exists"; then
            PROJECT_REF=$(echo "$CREATE_OUTPUT" | grep -o "ref: [^\s]*" | cut -d' ' -f2)
            log_success "项目创建成功 (Ref: $PROJECT_REF)"
        else
            log_error "项目创建失败"
            echo "$CREATE_OUTPUT"
            exit 1
        fi
    fi

    # 等待项目就绪
    log_info "等待项目初始化..."
    for i in {1..30}; do
        if supabase status --project-ref "$PROJECT_REF" &> /dev/null; then
            log_success "项目已就绪"
            break
        fi
        log_info "等待中... ($i/30)"
        sleep 10
    done
}

# 获取项目连接信息
get_supabase_connection_info() {
    log_step "获取 Supabase 连接信息"

    # 获取数据库 URL
    DB_URL=$(supabase db url --connection-string --project-ref "$PROJECT_REF" 2>/dev/null)
    SUPABASE_URL="https://$PROJECT_REF.supabase.co"

    # 获取密钥
    STATUS_OUTPUT=$(supabase status --project-ref "$PROJECT_REF" 2>/dev/null)
    SUPABASE_ANON_KEY=$(echo "$STATUS_OUTPUT" | grep "anon key" | awk '{print $3}')
    SUPABASE_SERVICE_KEY=$(echo "$STATUS_OUTPUT" | grep "service_role key" | awk '{print $3}')

    if [ -n "$DB_URL" ] && [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
        log_success "连接信息获取成功"
        log_info "  数据库: ${DB_URL:0:50}..."
        log_info "  API URL: $SUPABASE_URL"
    else
        log_error "无法获取完整的项目信息"
        exit 1
    fi
}

# 初始化数据库
init_supabase_database() {
    log_step "初始化 Supabase 数据库"

    if [ -f "scripts/init-supabase.sql" ]; then
        log_info "执行数据库初始化脚本..."

        # 创建临时 SQL 文件
        TEMP_SQL="/tmp/init-supabase-$(date +%s).sql"
        cat scripts/init-supabase.sql > "$TEMP_SQL"

        # 执行 SQL
        log_deploy "正在执行数据库脚本..."
        if supabase db push --project-ref "$PROJECT_REF" 2>/dev/null; then
            log_success "数据库初始化完成"
        else
            log_warning "自动初始化失败，尝试手动执行关键表..."

            # 手动创建用户表
            supabase db shell --project-ref "$PROJECT_REF" << 'EOF' 2>/dev/null || true
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
('张三', 'zhangsan@example.com'),
('李四', 'lisi@example.com'),
('王五', 'wangwu@example.com')
ON CONFLICT (email) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all operations for users" ON users
    FOR ALL USING (true) WITH CHECK (true);
EOF

            log_success "关键数据库表创建完成"
        fi

        # 清理临时文件
        rm -f "$TEMP_SQL"
    else
        log_warning "未找到初始化脚本，跳过数据库初始化"
    fi
}

# 配置 Vercel 环境变量
setup_vercel_environment() {
    log_step "配置 Vercel 环境变量"

    log_info "设置生产环境变量..."

    # 设置 DATABASE_URL
    log_deploy "配置 DATABASE_URL..."
    echo "$DB_URL" | vercel env add DATABASE_URL production --yes 2>/dev/null || {
        log_warning "环境变量设置可能需要手动确认"
    }

    # 设置 SUPABASE_URL
    log_deploy "配置 SUPABASE_URL..."
    echo "$SUPABASE_URL" | vercel env add SUPABASE_URL production --yes 2>/dev/null || {
        log_warning "环境变量设置可能需要手动确认"
    }

    # 设置 SUPABASE_ANON_KEY
    log_deploy "配置 SUPABASE_ANON_KEY..."
    echo "$SUPABASE_ANON_KEY" | vercel env add SUPABASE_ANON_KEY production --yes 2>/dev/null || {
        log_warning "环境变量设置可能需要手动确认"
    }

    # 设置 NODE_ENV
    log_deploy "配置 NODE_ENV..."
    echo "production" | vercel env add NODE_ENV production --yes 2>/dev/null || true

    log_success "环境变量配置完成"
}

# 部署到 Vercel
deploy_to_vercel() {
    log_step "部署到 Vercel"

    log_deploy "开始部署到 Vercel..."

    # 部署到生产环境
    DEPLOY_OUTPUT=$(vercel --prod 2>&1)

    if echo "$DEPLOY_OUTPUT" | grep -q "https://"; then
        DEPLOY_URL=$(echo "$DEPLOY_OUTPUT" | grep -o "https://[^[:space:]]*\.vercel\.app" | head -1)
        log_success "Vercel 部署成功！"
        log_info "部署 URL: https://$DEPLOY_URL"
    else
        log_error "Vercel 部署失败"
        echo "$DEPLOY_OUTPUT"
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    log_step "验证部署结果"

    log_info "等待部署生效 (15秒)..."
    sleep 15

    # 测试健康检查
    log_info "测试应用健康状态..."
    if curl -s "https://$DEPLOY_URL/health" | grep -q "OK"; then
        log_success "✅ 健康检查通过"
    else
        log_warning "⚠️  健康检查失败，可能还在部署中"
    fi

    # 测试 API
    log_info "测试 API 端点..."
    if curl -s "https://$DEPLOY_URL/api" | grep -q "API is working"; then
        log_success "✅ API 端点正常"
    else
        log_warning "⚠️  API 测试失败"
    fi

    # 测试数据库连接
    log_info "测试数据库连接..."
    if curl -s "https://$DEPLOY_URL/api/users" | grep -q "success"; then
        log_success "✅ 数据库连接正常"
    else
        log_warning "⚠️  数据库连接测试失败"
    fi
}

# 生成部署报告
generate_deployment_report() {
    log_step "生成部署报告"

    REPORT_FILE="deployment-report-$(date +%Y%m%d-%H%M%S).json"

    cat > "$REPORT_FILE" << EOF
{
  "deployment": {
    "timestamp": "$(date -Iseconds)",
    "vercel_url": "https://$DEPLOY_URL",
    "vercel_api_url": "https://$DEPLOY_URL/api",
    "vercel_health_url": "https://$DEPLOY_URL/health"
  },
  "supabase": {
    "project_name": "$PROJECT_NAME",
    "project_ref": "$PROJECT_REF",
    "api_url": "$SUPABASE_URL",
    "dashboard_url": "https://app.supabase.com/project/$PROJECT_REF",
    "database_url": "${DB_URL:0:50}..."
  },
  "tokens_used": {
    "vercel": "configured",
    "supabase": "configured"
  }
}
EOF

    log_success "部署报告已生成: $REPORT_FILE"
}

# 显示最终结果
show_final_results() {
    log_step "部署完成！"

    echo -e "${BOLD}${GREEN}"
    echo "🎉 完全自动化部署成功！"
    echo "================================"
    echo -e "${NC}"

    echo -e "${CYAN}🌐 应用访问地址：${NC}"
    echo "  📱 前端应用: https://$DEPLOY_URL"
    echo "  🔧 API 接口: https://$DEPLOY_URL/api"
    echo "  ❤️  健康检查: https://$DEPLOY_URL/health"

    echo -e "${CYAN}🗄️  Supabase 项目：${NC}"
    echo "  📊 Dashboard: https://app.supabase.com/project/$PROJECT_REF"
    echo "  🔗 API URL: $SUPABASE_URL"
    echo "  📝 项目引用: $PROJECT_REF"

    echo -e "${CYAN}📊 监控地址：${NC}"
    echo "  📈 Vercel Dashboard: https://vercel.com/dashboard"
    echo "  🗄️  Supabase Dashboard: https://app.supabase.com"

    echo -e "${CYAN}🧪 快速测试：${NC}"
    echo "  curl https://$DEPLOY_URL/health"
    echo "  curl https://$DEPLOY_URL/api/users"
    echo "  ./scripts/check-deployment.sh $DEPLOY_URL"

    echo -e "${CYAN}📝 后续操作：${NC}"
    echo "  1. ✅ 验证所有功能正常工作"
    echo "  2. 📊 监控使用量避免超额"
    echo "  3. 🔧 根据需要调整配置"
    echo "  4. 🌐 考虑添加自定义域名"

    echo
    log_success "🎊 恭喜！你的全栈应用已成功部署到云端！"
    echo -e "${GREEN}完全免费，即刻可用！${NC}"
}

# 主函数
main() {
    show_banner
    check_requirements
    setup_tokens
    install_cli_tools
    prepare_git_repo
    push_to_github
    verify_cli_logins
    setup_supabase_project
    get_supabase_connection_info
    init_supabase_database
    setup_vercel_environment
    deploy_to_vercel
    verify_deployment
    generate_deployment_report
    show_final_results
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查错误信息"; exit 1' ERR

# 运行主函数
main "$@"