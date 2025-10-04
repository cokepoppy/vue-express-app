#!/bin/bash

# 部署验证脚本
# 用于检查 Vercel + Supabase 部署是否成功

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认域名
DOMAIN=""

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

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# 显示使用说明
show_usage() {
    echo "使用方法: $0 [domain]"
    echo "示例: $0 vue-express-app.vercel.app"
    echo "或者: $0 https://vue-express-app.vercel.app"
    echo ""
    echo "如果不提供域名，脚本会尝试从 Vercel 获取最新部署"
}

# 获取 Vercel 最新部署域名
get_vercel_domain() {
    log_info "获取 Vercel 最新部署域名..."

    if command -v vercel &> /dev/null; then
        if vercel whoami &> /dev/null; then
            # 获取最新部署的域名
            DOMAIN=$(vercel ls --json 2>/dev/null | jq -r '.[0].targets.production?.url' 2>/dev/null || echo "")

            if [ -z "$DOMAIN" ]; then
                # 备选方案：从 vercel ls 获取
                DOMAIN=$(vercel ls 2>/dev/null | head -1 | awk '{print $2}' || echo "")
            fi

            if [ -n "$DOMAIN" ]; then
                log_success "获取到部署域名: $DOMAIN"
                return 0
            fi
        fi
    fi

    log_warning "无法自动获取 Vercel 域名"
    return 1
}

# 规范化域名
normalize_domain() {
    local domain="$1"

    # 移除协议前缀
    domain=$(echo "$domain" | sed 's|^https://||' | sed 's|^http://||')

    # 移除尾部斜杠
    domain=$(echo "$domain" | sed 's|/$||')

    echo "$domain"
}

# 测试 HTTP 端点
test_endpoint() {
    local url="$1"
    local name="$2"
    local expected_pattern="$3"

    log_test "测试 $name: $url"

    # 发送请求
    local response=$(curl -s -m 10 "$url" 2>/dev/null || echo "")
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$url" 2>/dev/null || echo "000")

    if [ "$status_code" = "200" ]; then
        if [ -n "$expected_pattern" ]; then
            if echo "$response" | grep -q "$expected_pattern"; then
                log_success "✅ $name - 响应正常"
                return 0
            else
                log_warning "⚠️  $name - 响应格式异常"
                echo "   期望包含: $expected_pattern"
                echo "   实际响应: ${response:0:100}..."
                return 1
            fi
        else
            log_success "✅ $name - 响应正常"
            return 0
        fi
    else
        log_error "❌ $name - HTTP $status_code"
        return 1
    fi
}

# 测试 JSON API 端点
test_json_endpoint() {
    local url="$1"
    local name="$2"
    local expected_field="$3"

    log_test "测试 $name: $url"

    # 发送请求
    local response=$(curl -s -m 10 "$url" 2>/dev/null || echo "")
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$url" 2>/dev/null || echo "000")

    if [ "$status_code" = "200" ]; then
        # 检查是否为有效 JSON
        if echo "$response" | jq empty 2>/dev/null; then
            if [ -n "$expected_field" ]; then
                if echo "$response" | jq -e ".$expected_field" &> /dev/null; then
                    log_success "✅ $name - JSON 响应正常"
                    echo "   包含字段: $expected_field"
                    return 0
                else
                    log_warning "⚠️  $name - 缺少期望字段: $expected_field"
                    echo "   响应: ${response:0:200}..."
                    return 1
                fi
            else
                log_success "✅ $name - JSON 响应正常"
                return 0
            fi
        else
            log_error "❌ $name - 无效 JSON 响应"
            echo "   响应: ${response:0:200}..."
            return 1
        fi
    else
        log_error "❌ $name - HTTP $status_code"
        return 1
    fi
}

# 运行完整测试套件
run_tests() {
    local base_url="https://$DOMAIN"

    log_info "开始测试部署: $base_url"
    echo "================================"

    local total_tests=0
    local passed_tests=0

    # 测试 1: 前端主页
    ((total_tests++))
    if test_endpoint "$base_url" "前端主页" "Vue3"; then
        ((passed_tests++))
    fi

    # 测试 2: 健康检查
    ((total_tests++))
    if test_endpoint "$base_url/health" "健康检查" "OK"; then
        ((passed_tests++))
    fi

    # 测试 3: API 根路径
    ((total_tests++))
    if test_json_endpoint "$base_url/api" "API 根路径" "message"; then
        ((passed_tests++))
    fi

    # 测试 4: 用户 API
    ((total_tests++))
    if test_json_endpoint "$base_url/api/users" "用户 API" "success"; then
        ((passed_tests++))
    fi

    # 测试 5: 缓存 API
    ((total_tests++))
    if test_json_endpoint "$base_url/api/examples/cache-test" "缓存 API" "success"; then
        ((passed_tests++))
    fi

    # 测试 6: 服务状态 API
    ((total_tests++))
    if test_json_endpoint "$base_url/api/examples/status" "服务状态" "services"; then
        ((passed_tests++))
    fi

    # 测试 7: 缓存统计 API
    ((total_tests++))
    if test_json_endpoint "$base_url/api/examples/cache-stats" "缓存统计" "stats"; then
        ((passed_tests++))
    fi

    echo "================================"
    log_info "测试结果: $passed_tests/$total_tests 通过"

    if [ $passed_tests -eq $total_tests ]; then
        log_success "🎉 所有测试通过！部署成功！"
        return 0
    else
        log_warning "⚠️  部分测试失败，请检查部署"
        return 1
    fi
}

# 测试数据库连接
test_database_connection() {
    log_info "测试数据库连接..."

    # 通过 API 测试数据库
    local response=$(curl -s "https://$DOMAIN/api/users" 2>/dev/null || echo "")

    if echo "$response" | grep -q "success" && echo "$response" | grep -q "data"; then
        log_success "✅ 数据库连接正常"

        # 尝试解析用户数据
        local user_count=$(echo "$response" | jq -r '.count // 0' 2>/dev/null || echo "0")
        log_info "   数据库中的用户数量: $user_count"

        return 0
    else
        log_error "❌ 数据库连接失败"
        return 1
    fi
}

# 测试缓存系统
test_cache_system() {
    log_info "测试缓存系统..."

    # 第一次请求 (应该从 API 获取)
    local response1=$(curl -s "https://$DOMAIN/api/examples/cache-test" 2>/dev/null || echo "")

    # 等待一秒
    sleep 1

    # 第二次请求 (可能从缓存获取)
    local response2=$(curl -s "https://$DOMAIN/api/examples/cache-test" 2>/dev/null || echo "")

    if echo "$response1" | grep -q "success" && echo "$response2" | grep -q "success"; then
        log_success "✅ 缓存系统正常"

        # 检查缓存来源
        if echo "$response2" | grep -q "upstash_redis"; then
            log_info "   使用 Upstash Redis 缓存"
        elif echo "$response2" | grep -q "fallback_redis"; then
            log_info "   使用备用 Redis 缓存"
        else
            log_info "   缓存来源: API"
        fi

        return 0
    else
        log_warning "⚠️  缓存系统可能未配置或工作异常"
        return 1
    fi
}

# 检查响应时间
check_response_times() {
    log_info "检查响应时间..."

    local endpoints=(
        "https://$DOMAIN/health"
        "https://$DOMAIN/api"
        "https://$DOMAIN/api/users"
    )

    for endpoint in "${endpoints[@]}"; do
        local start_time=$(date +%s%3N)
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$endpoint" 2>/dev/null || echo "000")
        local end_time=$(date +%s%3N)
        local response_time=$((end_time - start_time))

        if [ "$status_code" = "200" ]; then
            if [ $response_time -lt 1000 ]; then
                log_success "✅ ${endpoint##*/} - ${response_time}ms"
            elif [ $response_time -lt 3000 ]; then
                log_warning "⚠️  ${endpoint##*/} - ${response_time}ms (较慢)"
            else
                log_error "❌ ${endpoint##*/} - ${response_time}ms (太慢)"
            fi
        else
            log_error "❌ ${endpoint##*/} - HTTP $status_code"
        fi
    done
}

# 生成测试报告
generate_report() {
    local report_file="deployment-report-$(date +%Y%m%d-%H%M%S).json"

    log_info "生成测试报告: $report_file"

    cat > "$report_file" << EOF
{
  "domain": "$DOMAIN",
  "timestamp": "$(date -Iseconds)",
  "tests": {
    "frontend": {
      "url": "https://$DOMAIN",
      "status": "tested"
    },
    "health_check": {
      "url": "https://$DOMAIN/health",
      "status": "tested"
    },
    "api_root": {
      "url": "https://$DOMAIN/api",
      "status": "tested"
    },
    "users_api": {
      "url": "https://$DOMAIN/api/users",
      "status": "tested"
    },
    "cache_api": {
      "url": "https://$DOMAIN/api/examples/cache-test",
      "status": "tested"
    }
  }
}
EOF

    log_success "测试报告已生成: $report_file"
}

# 显示使用建议
show_recommendations() {
    echo
    echo -e "${CYAN}📋 部署建议：${NC}"
    echo "1. ✅ 确保所有测试通过"
    echo "2. 📊 监控 Vercel 使用量 (Dashboard → Usage)"
    echo "3. 🗄️  监控 Supabase 使用量 (Dashboard → Usage)"
    echo "4. 🔧 定期检查环境变量配置"
    echo "5. 🚀 考虑添加自定义域名"
    echo
    echo -e "${CYAN}🔗 有用的链接：${NC}"
    echo "  Vercel Dashboard: https://vercel.com/dashboard"
    echo "  Supabase Dashboard: https://app.supabase.com"
    echo "  应用地址: https://$DOMAIN"
    echo "  API 地址: https://$DOMAIN/api"
    echo
}

# 主函数
main() {
    echo "🔍 Vercel + Supabase 部署验证工具"
    echo "=================================="
    echo

    # 处理参数
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    # 获取域名
    if [ -n "$1" ]; then
        DOMAIN=$(normalize_domain "$1")
        log_info "使用提供的域名: $DOMAIN"
    else
        if ! get_vercel_domain; then
            echo
            log_error "无法获取部署域名"
            echo "请提供域名作为参数，例如："
            echo "  $0 vue-express-app.vercel.app"
            echo "  $0 https://vue-express-app.vercel.app"
            echo
            echo "或者确保："
            echo "1. 已安装 Vercel CLI"
            echo "2. 已登录 Vercel (vercel login)"
            echo "3. 项目已部署到 Vercel"
            exit 1
        fi
    fi

    echo
    log_info "开始验证部署: https://$DOMAIN"
    echo

    # 运行测试
    if run_tests; then
        # 额外测试
        test_database_connection
        test_cache_system
        check_response_times

        # 生成报告
        generate_report

        echo
        log_success "🎉 部署验证完成！"
        show_recommendations
    else
        echo
        log_error "❌ 部署验证失败"
        echo
        echo -e "${CYAN}故障排除建议：${NC}"
        echo "1. 检查 Vercel 部署状态 (vercel logs)"
        echo "2. 验证环境变量配置 (vercel env ls)"
        echo "3. 检查 Supabase 项目状态"
        echo "4. 确认代码已正确推送"
        echo
        exit 1
    fi
}

# 检查依赖
if ! command -v curl &> /dev/null; then
    log_error "curl 未安装，请先安装 curl"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_warning "jq 未安装，某些功能可能受限"
    echo "安装方式: brew install jq 或 apt-get install jq"
fi

# 运行主函数
main "$@"