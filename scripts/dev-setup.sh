#!/bin/bash

# 本地开发环境启动脚本
# Vue3 + Express + Supabase 本地开发环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖..."

    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js 未安装，请先安装 Node.js 18+"
        exit 1
    fi

    log_success "Node.js: $(node --version)"

    # 检查 npm
    if ! command -v npm &> /dev/null; then
        log_error "npm 未安装"
        exit 1
    fi

    log_success "npm: $(npm --version)"

    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_warning "Docker 未安装，将使用本地模式"
        DOCKER_AVAILABLE=false
    else
        log_success "Docker: $(docker --version)"
        DOCKER_AVAILABLE=true
    fi

    # 检查 Supabase CLI
    if ! command -v supabase &> /dev/null; then
        log_warning "Supabase CLI 未安装，正在安装..."
        npm install -g supabase
    fi

    log_success "Supabase CLI: $(supabase --version)"
}

# 安装项目依赖
install_dependencies() {
    log_step "安装项目依赖..."

    # 安装根目录依赖
    if [ -f "package.json" ]; then
        log_info "安装根目录依赖..."
        npm install
    fi

    # 安装前端依赖
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        log_info "安装前端依赖..."
        cd frontend
        npm install
        cd ..
    fi

    # 安装后端依赖
    if [ -d "backend" ] && [ -f "backend/package.json" ]; then
        log_info "安装后端依赖..."
        cd backend
        npm install
        cd ..
    fi

    log_success "依赖安装完成"
}

# 设置 Supabase
setup_supabase() {
    log_step "设置 Supabase 本地环境..."

    if [ -d "supabase" ]; then
        log_warning "Supabase 目录已存在"
        read -p "是否重新初始化 Supabase? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf supabase
        else
            log_info "跳过 Supabase 初始化"
            return
        fi
    fi

    # 初始化 Supabase
    log_info "初始化 Supabase 项目..."
    supabase init

    # 启动 Supabase
    log_info "启动 Supabase 本地服务..."
    supabase start

    log_success "Supabase 本地服务启动成功"

    # 显示连接信息
    show_supabase_info
}

# 显示 Supabase 连接信息
show_supabase_info() {
    log_info "Supabase 连接信息:"

    # 获取状态信息
    if command -v supabase &> /dev/null; then
        supabase status
    fi
}

# 生成环境变量
generate_env_files() {
    log_step "生成环境变量文件..."

    # 获取 Supabase 连接信息
    if command -v supabase &> /dev/null; then
        DB_URL=$(supabase status 2>/dev/null | grep "DB URL:" | cut -d' ' -f3)
        API_URL=$(supabase status 2>/dev/null | grep "API URL:" | cut -d' ' -f3)
        ANON_KEY=$(supabase status 2>/dev/null | grep "anon key:" | cut -d' ' -f3)

        # 后端环境变量
        cat > backend/.env.local << EOF
# Supabase 配置
DATABASE_URL=${DB_URL}
SUPABASE_URL=${API_URL}
SUPABASE_ANON_KEY=${ANON_KEY}

# Redis 配置
REDIS_URL=redis://localhost:6379

# 应用配置
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000
EOF

        # 前端环境变量
        cat > frontend/.env.local << EOF
VITE_API_BASE_URL=http://localhost:5000/api
VITE_SUPABASE_URL=${API_URL}
VITE_SUPABASE_ANON_KEY=${ANON_KEY}
EOF

        log_success "环境变量文件已生成"
    else
        log_warning "无法获取 Supabase 连接信息，请手动配置环境变量"
    fi
}

# 启动开发服务器
start_dev_servers() {
    log_step "启动开发服务器..."

    # 创建后台启动脚本
    cat > start_dev.sh << 'EOF'
#!/bin/bash

# 启动后端
echo "启动后端服务器..."
cd backend
npm run dev &
BACKEND_PID=$!
cd ..

# 等待后端启动
sleep 3

# 启动前端
echo "启动前端服务器..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

# 等待前端启动
sleep 3

echo "开发服务器启动完成!"
echo "前端: http://localhost:3000"
echo "后端: http://localhost:5000"
echo "Supabase Studio: http://localhost:54323"

# 等待用户中断
trap 'kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit' INT
wait
EOF

    chmod +x start_dev.sh
    log_info "运行 ./start_dev.sh 启动开发服务器"
}

# 主函数
main() {
    log "🚀 Vue3 + Express + Supabase 开发环境设置"
    log "=========================================="

    # 检查是否在项目根目录
    if [ ! -f "package.json" ] && [ ! -d "frontend" ] && [ ! -d "backend" ]; then
        log_error "请在项目根目录运行此脚本"
        exit 1
    fi

    check_dependencies
    install_dependencies
    setup_supabase
    generate_env_files
    start_dev_servers

    log_success "🎉 开发环境设置完成!"
    echo
    log_info "快速启动命令:"
    echo "  ./start_dev.sh                    # 启动开发服务器"
    echo "  npm run dev:supabase              # 启动 Supabase"
    echo "  npm run studio                     # 打开 Supabase Studio"
    echo "  npm run dev                        # 启动前后端服务"
    echo
    log_info "访问地址:"
    echo "  前端: http://localhost:3000"
    echo "  后端: http://localhost:5000"
    echo "  Supabase Studio: http://localhost:54323"
    echo
}

# 运行主函数
main "$@"