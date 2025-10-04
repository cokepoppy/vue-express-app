#!/usr/bin/env node

/**
 * Supabase 自动化设置脚本
 * 这个脚本帮助你快速设置 Supabase 项目
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logStep(step, message) {
  log(`\n[步骤 ${step}] ${message}`, 'cyan');
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function logInfo(message) {
  log(`ℹ️  ${message}`, 'blue');
}

function logCode(code) {
  log(`\n${code}`, 'magenta');
}

// 检查依赖
function checkDependencies() {
  logStep(1, '检查依赖');

  try {
    execSync('supabase --version', { stdio: 'pipe' });
    logSuccess('Supabase CLI 已安装');
  } catch (error) {
    logError('Supabase CLI 未安装');
    logInfo('请先安装 Supabase CLI:');
    logCode('npm install -g supabase');
    logCode('# 或');
    logCode('brew install supabase/tap/supabase');
    process.exit(1);
  }

  try {
    execSync('node --version', { stdio: 'pipe' });
    logSuccess('Node.js 已安装');
  } catch (error) {
    logError('Node.js 未安装');
    process.exit(1);
  }
}

// 初始化 Supabase 项目
function initSupabase() {
  logStep(2, '初始化 Supabase 项目');

  if (fs.existsSync('supabase')) {
    logWarning('Supabase 目录已存在');
    const answer = require('readline-sync').question('是否重新初始化? (y/N): ');
    if (answer.toLowerCase() !== 'y') {
      logInfo('跳过初始化');
      return;
    }
  }

  try {
    logInfo('正在初始化 Supabase 项目...');
    execSync('supabase init', { stdio: 'inherit' });
    logSuccess('Supabase 项目初始化完成');
  } catch (error) {
    logError('Supabase 初始化失败');
    process.exit(1);
  }
}

// 创建数据库迁移
function createMigrations() {
  logStep(3, '创建数据库迁移');

  const migrationsDir = path.join('supabase', 'migrations');

  if (!fs.existsSync(migrationsDir)) {
    fs.mkdirSync(migrationsDir, { recursive: true });
  }

  // 读取 SQL 脚本
  const sqlScript = fs.readFileSync(path.join('scripts', 'init-supabase.sql'), 'utf8');

  // 创建迁移文件
  const timestamp = new Date().toISOString().replace(/[-:]/g, '').split('.')[0];
  const migrationFile = path.join(migrationsDir, `${timestamp}_init_database.sql`);

  fs.writeFileSync(migrationFile, sqlScript);
  logSuccess(`迁移文件已创建: ${migrationFile}`);
}

// 启动本地 Supabase
function startLocalSupabase() {
  logStep(4, '启动本地 Supabase');

  try {
    logInfo('正在启动 Supabase 本地服务...');
    execSync('supabase start', { stdio: 'inherit' });
    logSuccess('Supabase 本地服务启动成功');
  } catch (error) {
    logError('Supabase 启动失败');
    logInfo('请检查 Docker 是否运行');
    process.exit(1);
  }
}

// 获取连接信息
function getConnectionInfo() {
  logStep(5, '获取连接信息');

  try {
    const output = execSync('supabase status', { encoding: 'utf8' });
    logInfo('本地 Supabase 状态:');
    console.log(output);

    // 解析连接信息
    const lines = output.split('\n');
    const info = {};

    lines.forEach(line => {
      if (line.includes('API URL:')) {
        info.apiUrl = line.split('API URL:')[1].trim();
      } else if (line.includes('DB URL:')) {
        info.dbUrl = line.split('DB URL:')[1].trim();
      } else if (line.includes('Studio URL:')) {
        info.studioUrl = line.split('Studio URL:')[1].trim();
      } else if (line.includes('anon key:')) {
        info.anonKey = line.split('anon key:')[1].trim();
      }
    });

    logSuccess('连接信息获取成功');
    return info;
  } catch (error) {
    logError('获取连接信息失败');
    return null;
  }
}

// 生成环境变量文件
function generateEnvFile(info) {
  logStep(6, '生成环境变量文件');

  if (!info) {
    logError('无法生成环境变量文件');
    return;
  }

  const envContent = `# Supabase 配置
DATABASE_URL=${info.dbUrl}
SUPABASE_URL=${info.apiUrl}
SUPABASE_ANON_KEY=${info.anonKey}

# Upstash Redis 配置 (需要手动添加)
UPSTASH_REDIS_REST_URL=your-upstash-redis-url
UPSTASH_REDIS_REST_TOKEN=your-upstash-redis-token

# 应用配置
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
`;

  // 写入后端环境变量
  const backendEnvPath = path.join('backend', '.env.local');
  fs.writeFileSync(backendEnvPath, envContent);
  logSuccess(`后端环境变量已写入: ${backendEnvPath}`);

  // 写入前端环境变量
  const frontendEnvContent = `VITE_API_BASE_URL=http://localhost:5000/api
VITE_SUPABASE_URL=${info.apiUrl}
VITE_SUPABASE_ANON_KEY=${info.anonKey}
`;

  const frontendEnvPath = path.join('frontend', '.env.local');
  fs.writeFileSync(frontendEnvPath, frontendEnvContent);
  logSuccess(`前端环境变量已写入: ${frontendEnvPath}`);
}

// 显示后续步骤
function showNextSteps(info) {
  logStep(7, '后续步骤');

  logInfo('本地 Supabase 已设置完成！');
  logInfo('请按以下步骤操作:');

  console.log('\n1. 🗄️ 访问 Supabase Studio:');
  logCode(info?.studioUrl || 'http://localhost:54323');

  console.log('\n2. 🚀 启动本地开发服务:');
  logCode('# 启动后端 (新终端)');
  logCode('cd backend');
  logCode('npm install');
  logCode('npm run dev');

  logCode('\n# 启动前端 (新终端)');
  logCode('cd frontend');
  logCode('npm install');
  logCode('npm run dev');

  console.log('\n3. 🔗 设置 Upstash Redis (可选):');
  logCode('1. 访问 https://upstash.com');
  logCode('2. 创建 Redis 数据库');
  logCode('3. 更新环境变量中的 UPSTASH_REDIS_* 配置');

  console.log('\n4. 🌍 部署到云端:');
  logCode('1. 在 Vercel 中连接 GitHub 仓库');
  logCode('2. 配置环境变量');
  logCode('3. 自动部署');
}

// 主函数
function main() {
  log('🚀 Supabase 自动化设置脚本', 'bright');
  log('=====================================', 'bright');

  try {
    // 检查是否在项目根目录
    if (!fs.existsSync('package.json') && !fs.existsSync('frontend/package.json')) {
      logError('请在项目根目录运行此脚本');
      process.exit(1);
    }

    checkDependencies();
    initSupabase();
    createMigrations();
    startLocalSupabase();
    const info = getConnectionInfo();
    generateEnvFile(info);
    showNextSteps(info);

    log('\n🎉 Supabase 设置完成！', 'green');
    log('现在你可以开始开发了！', 'green');

  } catch (error) {
    logError(`脚本执行失败: ${error.message}`);
    process.exit(1);
  }
}

// 如果直接运行此脚本
if (require.main === module) {
  main();
}

module.exports = {
  main,
  checkDependencies,
  initSupabase,
  createMigrations,
  startLocalSupabase,
  getConnectionInfo,
  generateEnvFile
};