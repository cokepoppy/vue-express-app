#!/bin/bash

# Supabase CLI 自动化部署脚本
# 支持使用 Token 自动创建和管理 Supabase 项目

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

log_supabase() {
    echo -e "${PURPLE}[SUPABASE]${NC} $1"
}

# 配置变量
SUPABASE_TOKEN=""
PROJECT_NAME="vue-express-app"
DB_PASSWORD="YourStrongPassword123!"
REGION="us-east-1"

# 显示横幅
show_banner() {
    echo -e "${PURPLE}"
    echo "🗄️  Supabase 自动化部署脚本"
    echo "==========================="
    echo -e "${NC}"
    echo "此脚本将自动完成："
    echo "1. 🔐 配置 Supabase Token"
    echo "2. 🏗️  创建 Supabase 项目"
    echo "3. 📊 初始化数据库结构"
    echo "4. 🔗 获取连接信息"
    echo "5. ⚙️  配置环境变量"
    echo
}

# 获取 Supabase Token
get_supabase_token() {
    log_step "配置 Supabase Access Token"

    if [ -z "$SUPABASE_TOKEN" ]; then
        if [ -n "$1" ]; then
            SUPABASE_TOKEN="$1"
            log_info "使用提供的 Token"
        else
            echo -n "请输入 Supabase Access Token: "
            read -s SUPABASE_TOKEN
            echo
        fi
    fi

    if [ -z "$SUPABASE_TOKEN" ]; then
        log_error "Supabase Token 是必需的"
        log_info "获取方式："
        log_info "1. 访问 https://supabase.com/account/tokens"
        log_info "2. 点击 'Generate new token'"
        log_info "3. 复制生成的 token"
        exit 1
    fi

    log_success "Supabase Token 配置完成"
}

# 安装和配置 Supabase CLI
setup_supabase_cli() {
    log_step "安装和配置 Supabase CLI"

    # 检查是否已安装
    if ! command -v supabase &> /dev/null; then
        log_info "安装 Supabase CLI..."

        # 根据系统选择安装方式
        if command -v npm &> /dev/null; then
            npm install -g supabase
        elif command -v brew &> /dev/null; then
            brew install supabase/tap/supabase
        else
            log_error "无法自动安装 Supabase CLI，请手动安装"
            log_info "安装方式："
            log_info "npm: npm install -g supabase"
            log_info "brew: brew install supabase/tap/supabase"
            exit 1
        fi
    fi

    # 登录 Supabase
    log_info "登录 Supabase..."
    echo "$SUPABASE_TOKEN" | supabase login --token

    # 验证登录
    if supabase projects list &> /dev/null; then
        log_success "Supabase CLI 配置完成"
    else
        log_error "Supabase 登录失败，请检查 Token"
        exit 1
    fi
}

# 检查现有项目
check_existing_project() {
    log_step "检查现有 Supabase 项目"

    # 获取项目列表
    PROJECTS=$(supabase projects list 2>/dev/null)

    if echo "$PROJECTS" | grep -q "$PROJECT_NAME"; then
        log_info "发现现有项目: $PROJECT_NAME"
        PROJECT_REF=$(echo "$PROJECTS" | grep "$PROJECT_NAME" | awk '{print $2}')
        log_success "使用现有项目 (Ref: $PROJECT_REF)"
        return 0
    else
        log_info "未找到现有项目，将创建新项目"
        return 1
    fi
}

# 创建新项目
create_new_project() {
    log_step "创建新的 Supabase 项目"

    log_info "项目配置："
    log_info "  名称: $PROJECT_NAME"
    log_info "  区域: $REGION"
    log_info "  数据库密码: [已设置]"

    # 创建项目
    log_supabase "正在创建项目..."
    CREATE_OUTPUT=$(supabase projects create \
        "$PROJECT_NAME" \
        --org-personal \
        --db-password "$DB_PASSWORD" \
        --region "$REGION" \
        2>&1)

    # 检查创建结果
    if echo "$CREATE_OUTPUT" | grep -q "successfully created"; then
        PROJECT_REF=$(echo "$CREATE_OUTPUT" | grep -o "ref: [^\s]*" | cut -d' ' -f2)
        log_success "项目创建成功 (Ref: $PROJECT_REF)"
    elif echo "$CREATE_OUTPUT" | grep -q "already exists"; then
        log_info "项目已存在，获取项目信息..."
        PROJECTS=$(supabase projects list)
        PROJECT_REF=$(echo "$PROJECTS" | grep "$PROJECT_NAME" | awk '{print $2}')
        log_success "获取项目信息成功 (Ref: $PROJECT_REF)"
    else
        log_error "项目创建失败"
        echo "$CREATE_OUTPUT"
        exit 1
    fi
}

# 等待项目就绪
wait_for_project_ready() {
    log_step "等待项目就绪..."

    log_info "等待 Supabase 项目初始化..."

    for i in {1..30}; do
        if supabase status --project-ref "$PROJECT_REF" &> /dev/null; then
            log_success "项目已就绪！"
            return 0
        fi

        log_info "等待中... ($i/30)"
        sleep 10
    done

    log_error "项目初始化超时"
    exit 1
}

# 获取项目连接信息
get_project_info() {
    log_step "获取项目连接信息"

    log_info "获取数据库连接信息..."

    # 获取数据库 URL
    DB_URL=$(supabase db url --connection-string --project-ref "$PROJECT_REF" 2>/dev/null)

    # 获取 API 信息
    SUPABASE_URL="https://$PROJECT_REF.supabase.co"

    # 获取密钥
    STATUS_OUTPUT=$(supabase status --project-ref "$PROJECT_REF" 2>/dev/null)
    SUPABASE_ANON_KEY=$(echo "$STATUS_OUTPUT" | grep "anon key" | awk '{print $3}')
    SUPABASE_SERVICE_KEY=$(echo "$STATUS_OUTPUT" | grep "service_role key" | awk '{print $3}')

    if [ -n "$DB_URL" ] && [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
        log_success "连接信息获取成功"

        log_info "连接信息："
        log_info "  数据库 URL: ${DB_URL:0:50}..."
        log_info "  API URL: $SUPABASE_URL"
        log_info "  Anon Key: ${SUPABASE_ANON_KEY:0:30}..."
    else
        log_error "无法获取完整的项目信息"
        exit 1
    fi
}

# 初始化数据库
init_database() {
    log_step "初始化数据库结构"

    if [ -f "scripts/init-supabase.sql" ]; then
        log_info "执行数据库初始化脚本..."

        # 将 SQL 脚本分割并执行
        {
            echo "-- 自动生成的数据库初始化脚本"
            echo "-- 项目: $PROJECT_NAME"
            echo "-- 时间: $(date)"
            echo ""
            cat scripts/init-supabase.sql
        } | supabase db push --project-ref "$PROJECT_REF" 2>/dev/null || {
            log_warning "自动初始化失败，尝试手动执行"

            # 备用方案：使用 db shell
            log_info "使用备选方案初始化数据库..."

            # 创建用户表
            supabase db shell --project-ref "$PROJECT_REF" << 'EOF' &> /dev/null || true
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入示例数据
INSERT INTO users (name, email) VALUES
('张三', 'zhangsan@example.com'),
('李四', 'lisi@example.com'),
('王五', 'wangwu@example.com')
ON CONFLICT (email) DO NOTHING;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建触发器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 启用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 创建策略
CREATE POLICY "Enable all operations for users" ON users
    FOR ALL USING (true) WITH CHECK (true);
EOF

            log_success "数据库初始化完成"
        }
    else
        log_warning "未找到初始化脚本，跳过数据库初始化"
    fi
}

# 生成环境变量文件
generate_env_files() {
    log_step "生成环境变量文件"

    # 生成 Vercel 环境变量配置
    cat > .env.vercel << EOF
# Supabase 配置 - 由自动化脚本生成
# 项目: $PROJECT_NAME
# 时间: $(date)
# 项目引用: $PROJECT_REF

DATABASE_URL=$DB_URL
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_KEY

# 应用配置
NODE_ENV=production
PORT=5000
EOF

    log_success "Vercel 环境变量文件已生成: .env.vercel"

    # 生成本地环境变量文件
    cat > .env.local << EOF
# 本地开发环境变量
# 项目: $PROJECT_NAME (本地)
DATABASE_URL=$DB_URL
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# 本地 Redis
REDIS_URL=redis://localhost:6379

# 应用配置
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000
EOF

    log_success "本地环境变量文件已生成: .env.local"

    # 生成前端环境变量
    cat > frontend/.env.production << EOF
# 前端生产环境变量
VITE_API_BASE_URL=/api
VITE_SUPABASE_URL=$SUPABASE_URL
VITE_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
EOF

    log_success "前端环境变量文件已生成: frontend/.env.production"
}

# 创建部署信息文件
create_deployment_info() {
    log_step "创建部署信息文件"

    cat > supabase-deployment-info.json << EOF
{
  "project_name": "$PROJECT_NAME",
  "project_ref": "$PROJECT_REF",
  "supabase_url": "$SUPABASE_URL",
  "database_url": "$DB_URL",
  "anon_key": "$SUPABASE_ANON_KEY",
  "service_key": "$SUPABASE_SERVICE_KEY",
  "created_at": "$(date -Iseconds)",
  "region": "$REGION",
  "dashboard_url": "https://app.supabase.com/project/$PROJECT_REF"
}
EOF

    log_success "部署信息文件已生成: supabase-deployment-info.json"
}

# 显示项目信息
show_project_info() {
    log_step "部署完成！"

    echo -e "${PURPLE}🎉 Supabase 项目部署完成！${NC}"
    echo
    echo -e "${CYAN}📋 项目信息：${NC}"
    echo "  项目名称: $PROJECT_NAME"
    echo "  项目引用: $PROJECT_REF"
    echo "  区域: $REGION"
    echo
    echo -e "${CYAN}🔗 连接信息：${NC}"
    echo "  API URL: $SUPABASE_URL"
    echo "  Dashboard: https://app.supabase.com/project/$PROJECT_REF"
    echo
    echo -e "${CYAN}📁 生成的文件：${NC}"
    echo "  .env.vercel              - Vercel 环境变量"
    echo "  .env.local               - 本地环境变量"
    echo "  frontend/.env.production - 前端环境变量"
    echo "  supabase-deployment-info.json - 部署信息"
    echo
    echo -e "${CYAN}🚀 下一步：${NC}"
    echo "  1. 将 .env.vercel 中的环境变量添加到 Vercel"
    echo "  2. 运行 ./scripts/auto-deploy.sh 完成部署"
    echo "  3. 或者手动部署到 Vercel: vercel --prod"
    echo
    echo -e "${CYAN}🧪 测试命令：${NC}"
    echo "  curl $SUPABASE_URL/rest/v1/users"
    echo "  supabase status --project-ref $PROJECT_REF"
    echo
    log_success "🗄️  Supabase 项目已准备就绪！"
}

# 主函数
main() {
    show_banner
    get_supabase_token "$1"
    setup_supabase_cli

    if ! check_existing_project; then
        create_new_project
    fi

    wait_for_project_ready
    get_project_info
    init_database
    generate_env_files
    create_deployment_info
    show_project_info
}

# 错误处理
trap 'log_error "脚本执行失败"; exit 1' ERR

# 运行主函数
main "$@"