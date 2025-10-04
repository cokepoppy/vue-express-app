# 🚀 手动部署指南

由于 CLI Token 认证问题，我们提供手动部署步骤。这种方式更可靠且能更好地理解部署过程。

## 📋 部署准备

### ✅ 已完成
- ✅ Vue3 + Express 项目代码已准备就绪
- ✅ TypeScript 编译错误已修复
- ✅ 前端和后端都能成功构建
- ✅ Git 仓库已初始化并提交代码

### 🎯 部署架构
```
Frontend (Vue3) → Vercel Static Sites
Backend (Express) → Vercel Functions
Database → Supabase PostgreSQL
Cache → Upstash Redis (可选)
```

## 🔧 手动部署步骤

### 1. 创建 GitHub 仓库
```bash
# 1. 访问 https://github.com/new
# 2. 创建新仓库: vue-express-app
# 3. 连接本地仓库:
git remote add origin https://github.com/YOUR_USERNAME/vue-express-app.git
git branch -M main
git push -u origin main
```

### 2. 部署 Supabase 数据库

#### 2.1 创建 Supabase 项目
1. 访问 https://supabase.com
2. 点击 "Start your project"
3. 使用 GitHub 账号登录
4. 创建新项目: `vue-express-app`
5. 选择区域: `East US (North Virginia)` 或最近的区域
6. 设置数据库密码: `YourStrongPassword123!`
7. 等待项目创建完成 (约2-3分钟)

#### 2.2 初始化数据库
1. 进入 Supabase Dashboard → SQL Editor
2. 执行以下 SQL 脚本:

```sql
-- 创建用户表
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

-- 启用 RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 创建策略
CREATE POLICY "Enable all operations for users" ON users
    FOR ALL USING (true) WITH CHECK (true);
```

#### 2.3 获取 Supabase 连接信息
在 Supabase Dashboard → Settings → API 中获取:
- **Project URL**: `https://[project-ref].supabase.co`
- **anon public key**: `eyJ...`
- **service_role key**: `eyJ...`
- **Database URL**: 在 Database settings 中查看

### 3. 部署到 Vercel

#### 3.1 导入项目到 Vercel
1. 访问 https://vercel.com
2. 点击 "New Project"
3. 导入 GitHub 仓库: `vue-express-app`
4. Vercel 会自动检测项目配置

#### 3.2 配置环境变量
在 Vercel 项目设置中添加以下环境变量:

```bash
# Supabase 配置
DATABASE_URL=postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_ANON_KEY=eyJ[anon-key]
SUPABASE_SERVICE_ROLE_KEY=eyJ[service-role-key]

# 应用配置
NODE_ENV=production
PORT=5000
```

#### 3.3 构建设置
Vercel 会自动使用以下配置:
- **Root Directory**: `/`
- **Build Command**: `npm run build`
- **Output Directory**: `frontend/dist`
- **Install Command**: `npm run install:all`

### 4. 验证部署

#### 4.1 自动验证
部署完成后，运行验证脚本:
```bash
# 替换为你的实际域名
./scripts/check-deployment.sh your-app-name.vercel.app
```

#### 4.2 手动测试
```bash
# 测试前端
curl https://your-app-name.vercel.app

# 测试健康检查
curl https://your-app-name.vercel.app/health

# 测试 API
curl https://your-app-name.vercel.app/api

# 测试数据库连接
curl https://your-app-name.vercel.app/api/users
```

## 🎯 部署成功后的访问地址

### 应用地址
- **前端应用**: `https://vue-express-app.vercel.app`
- **API 接口**: `https://vue-express-app.vercel.app/api`
- **健康检查**: `https://vue-express-app.vercel.app/health`

### 管理地址
- **Vercel Dashboard**: `https://vercel.com/dashboard`
- **Supabase Dashboard**: `https://app.supabase.com`

## 🔧 可选配置

### 添加 Upstash Redis 缓存
1. 访问 https://upstash.com
2. 创建免费 Redis 数据库
3. 在 Vercel 环境变量中添加:
   ```bash
   UPSTASH_REDIS_REST_URL=https://your-redis-url.upstash.io
   UPSTASH_REDIS_REST_TOKEN=your-redis-token
   ```

### 自定义域名
1. 在 Vercel 项目设置中添加自定义域名
2. 配置 DNS 记录指向 Vercel

## 🆘 故障排除

### 常见问题
1. **构建失败**: 检查 Node.js 版本和依赖安装
2. **数据库连接失败**: 验证 Supabase 连接字符串
3. **API 404 错误**: 检查 `vercel.json` 路由配置
4. **环境变量未生效**: 确认在 Vercel 中正确设置

### 调试命令
```bash
# 查看 Vercel 部署日志
vercel logs

# 本地预览
npm run dev

# 构建测试
npm run build
```

## 💡 部署提示

- ✅ 确保所有环境变量都已正确配置
- ✅ 代码已推送到 GitHub 仓库
- ✅ Supabase 项目已创建并初始化
- ✅ Vercel 已连接到正确的仓库
- ✅ 构建设置符合项目结构

## 🎉 完成！

按照以上步骤完成后，你将拥有一个完全功能的全栈应用:
- Vue3 前端部署在 Vercel Static Sites
- Express 后端部署在 Vercel Functions
- PostgreSQL 数据库在 Supabase
- 可选的 Redis 缓存在 Upstash

全部使用免费套餐，零成本部署！