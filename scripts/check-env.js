#!/usr/bin/env node

/**
 * 环境变量检查脚本
 * 用于验证部署所需的环境变量是否配置正确
 */

const fs = require('fs');
const { execSync } = require('child_process');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logInfo(message) {
  log(`ℹ️  ${message}`, 'blue');
}

// 必需的环境变量
const requiredEnvVars = [
  {
    name: 'DATABASE_URL',
    description: 'Supabase PostgreSQL 连接字符串',
    example: 'postgresql://postgres:password@db.project.supabase.co:5432/postgres'
  },
  {
    name: 'SUPABASE_URL',
    description: 'Supabase API URL',
    example: 'https://project.supabase.co'
  },
  {
    name: 'SUPABASE_ANON_KEY',
    description: 'Supabase 匿名访问密钥',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  }
];

// 可选的环境变量
const optionalEnvVars = [
  {
    name: 'UPSTASH_REDIS_REST_URL',
    description: 'Upstash Redis REST API URL',
    example: 'https://redis-12345.upstash.io'
  },
  {
    name: 'UPSTASH_REDIS_REST_TOKEN',
    description: 'Upstash Redis REST API Token',
    example: 'redis-token-12345'
  },
  {
    name: 'REDIS_URL',
    description: '备用 Redis 连接 URL',
    example: 'redis://localhost:6379'
  },
  {
    name: 'JWT_SECRET',
    description: 'JWT 签名密钥',
    example: 'your-super-secret-jwt-key'
  }
];

// 检查本地环境变量
function checkLocalEnv() {
  logInfo('检查本地环境变量...');

  const envFiles = ['.env', '.env.local', '.env.production'];
  let hasEnvFile = false;

  for (const file of envFiles) {
    if (fs.existsSync(file)) {
      logInfo(`找到环境变量文件: ${file}`);
      hasEnvFile = true;
    }
  }

  if (!hasEnvFile) {
    logWarning('未找到本地环境变量文件');
  }

  return hasEnvFile;
}

// 检查 Vercel 环境变量
function checkVercelEnv() {
  logInfo('检查 Vercel 环境变量...');

  try {
    const output = execSync('vercel env ls', { encoding: 'utf8' });
    logSuccess('Vercel CLI 已登录');

    const envVars = output.split('\n')
      .filter(line => line.trim())
      .map(line => line.split(/\s+/)[0]);

    if (envVars.length === 0) {
      logWarning('Vercel 中未配置任何环境变量');
      return false;
    }

    logSuccess(`Vercel 中已配置 ${envVars.length} 个环境变量`);

    // 检查必需变量
    let missingRequired = [];
    let configuredRequired = [];

    requiredEnvVars.forEach(envVar => {
      if (envVars.includes(envVar.name)) {
        configuredRequired.push(envVar.name);
      } else {
        missingRequired.push(envVar.name);
      }
    });

    if (configuredRequired.length > 0) {
      logSuccess(`已配置必需变量: ${configuredRequired.join(', ')}`);
    }

    if (missingRequired.length > 0) {
      logError(`缺少必需变量: ${missingRequired.join(', ')}`);
      logInfo('请运行以下命令添加环境变量:');
      missingRequired.forEach(varName => {
        const envVar = requiredEnvVars.find(v => v.name === varName);
        logInfo(`vercel env add ${varName}`);
        logInfo(`  # ${envVar.description}`);
        logInfo(`  # 示例: ${envVar.example}`);
      });
    }

    return missingRequired.length === 0;

  } catch (error) {
    logError('无法检查 Vercel 环境变量');
    logInfo('请确保: 1) 已安装 Vercel CLI 2) 已登录 Vercel');
    return false;
  }
}

// 生成环境变量配置指南
function generateEnvGuide() {
  logInfo('\n📋 环境变量配置指南:');
  logInfo('================================');

  logInfo('\n🔐 必需配置 (3个):');
  requiredEnvVars.forEach((envVar, index) => {
    logInfo(`${index + 1}. ${envVar.name}`);
    logInfo(`   描述: ${envVar.description}`);
    logInfo(`   示例: ${envVar.example}`);
  });

  logInfo('\n🔧 可选配置:');
  optionalEnvVars.forEach((envVar, index) => {
    logInfo(`${index + 1}. ${envVar.name}`);
    logInfo(`   描述: ${envVar.description}`);
    logInfo(`   示例: ${envVar.example}`);
  });

  logInfo('\n📝 配置步骤:');
  logInfo('1. 在 Vercel 项目设置中添加环境变量');
  logInfo('2. 或者使用 CLI: vercel env add VAR_NAME');
  logInfo('3. 配置完成后重新部署项目');
}

// 创建环境变量检查脚本
function createCheckScript() {
  const scriptContent = `#!/bin/bash

# 简单的环境变量检查脚本

echo "🔍 检查部署环境变量"
echo "===================="

# 检查 Vercel 登录状态
if ! vercel whoami &> /dev/null; then
    echo "❌ 未登录 Vercel，请先运行: vercel login"
    exit 1
fi

echo "✅ Vercel 登录状态正常"

# 检查环境变量
echo ""
echo "📋 检查必需的环境变量:"

required_vars=("DATABASE_URL" "SUPABASE_URL" "SUPABASE_ANON_KEY")
missing_vars=()

for var in "${required_vars[@]}"; do
    if vercel env ls | grep -q "$var"; then
        echo "✅ $var"
    else
        echo "❌ $var (未配置)"
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -eq 0 ]; then
    echo ""
    echo "🎉 所有必需的环境变量已配置完成！"
    echo "可以运行: ./scripts/deploy.sh"
else
    echo ""
    echo "⚠️  请配置缺少的环境变量:"
    for var in "${missing_vars[@]}"; do
        echo "   vercel env add $var"
    done
fi
`;

  fs.writeFileSync('scripts/check-env.sh', scriptContent);
  fs.chmodSync('scripts/check-env.sh', '755');
  logSuccess('环境变量检查脚本已创建: scripts/check-env.sh');
}

// 主函数
function main() {
  log('🌍 Vercel 部署环境变量检查工具', 'blue');
  log('==================================', 'blue');

  // 检查本地环境
  const hasLocalEnv = checkLocalEnv();

  // 检查 Vercel 环境
  const hasRequiredVars = checkVercelEnv();

  // 生成配置指南
  generateEnvGuide();

  // 创建检查脚本
  createCheckScript();

  // 总结
  log('\n📊 检查总结:');
  log(`本地环境文件: ${hasLocalEnv ? '✅' : '❌'}`);
  log(`Vercel 必需变量: ${hasRequiredVars ? '✅' : '❌'}`);

  if (hasRequiredVars) {
    logSuccess('环境变量配置完成，可以开始部署！');
    logInfo('运行: ./scripts/deploy.sh 开始部署');
  } else {
    logWarning('请先配置环境变量，然后再部署');
    logInfo('运行: scripts/check-env.sh 快速检查');
  }
}

// 运行主函数
if (require.main === module) {
  main();
}

module.exports = { main, checkVercelEnv, generateEnvGuide };