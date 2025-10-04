# 🚀 Vue-Express 应用部署配置

## ✅ 已确认的部署信息

### Supabase 项目信息
- **项目引用**: `zknwbnwkkfjslnkafsga`
- **项目名称**: c-m-ai-copilot's Project
- **区域**: `us-east-2`
- **API URL**: `https://zknwbnwkkfjslnkafsga.supabase.co`
- **Dashboard**: `https://app.supabase.com/project/zknwbnwkkfjslnkafsga`

### Supabase Keys
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inprbndibndra2Zqc2xua2Fmc2dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NTQxODksImV4cCI6MjA3NTEzMDE4OX0.DyOc4nI3VBLKS5I9vdZyB0LE0YlFZk9abXNzL8Nafkk`
- **CLI Token**: `sbp_aa77382a0da5e4051274b3cf6504e7d2ad6736f8`

### 项目状态
- ✅ Git 仓库已初始化
- ✅ 代码已提交
- ✅ TypeScript 编译通过
- ✅ 前端构建成功
- ✅ 后端构建成功
- ✅ Supabase 项目已存在

## 🎯 Vercel 部署配置

### 1. 环境变量配置
在 Vercel 项目设置中添加以下环境变量：

```bash
# Supabase 配置
SUPABASE_URL=https://zknwbnwkkfjslnkafsga.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inprbndibndra2Zqc2xua2Fmc2dhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NTQxODksImV4cCI6MjA3NTEzMDE4OX0.DyOc4nI3VBLKS5I9vdZyB0LE0YlFZk9abXNzL8Nafkk
DATABASE_URL=postgresql://postgres.YOUR_PASSWORD@aws-0-us-east-2.pooler.supabase.com:6543/postgres

# 应用配置
NODE_ENV=production
PORT=5000
```

### 2. Vercel 配置文件
项目已包含 `vercel.json` 配置：

```json
{
  "version": 2,
  "name": "vue-express-app",
  "builds": [
    {
      "src": "api/index.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "api/index.ts"
    },
    {
      "src": "/(.*)",
      "dest": "frontend/dist/$1"
    }
  ]
}
```

### 3. 构建设置
- **Root Directory**: `/`
- **Build Command**: `npm run build`
- **Output Directory**: `frontend/dist`
- **Install Command**: `npm run install:all`

## 📋 部署步骤

### 步骤 1: 推送代码到 GitHub
```bash
# 如果你还没有 GitHub 仓库，创建一个：
# 1. 访问 https://github.com/new
# 2. 创建仓库: vue-express-app
# 3. 连接并推送：
git remote add origin https://github.com/YOUR_USERNAME/vue-express-app.git
git branch -M main
git push -u origin main
```

### 步骤 2: 在 Vercel 中导入项目
1. 访问 https://vercel.com
2. 点击 "New Project"
3. 选择 GitHub 仓库 `vue-express-app`
4. Vercel 会自动检测项目类型

### 步骤 3: 配置环境变量
在 Vercel 项目设置中，添加上面列出的环境变量。

**重要**: 你需要从 Supabase Dashboard 获取数据库密码：
1. 访问 https://app.supabase.com/project/zknwbnwkkfjslnkafsga
2. Settings → Database → Connection string
3. 复制数据库连接信息

### 步骤 4: 部署
点击 "Deploy" 按钮，Vercel 会自动构建和部署。

## 🧪 部署验证

部署完成后，测试以下端点：

```bash
# 替换为你的实际 Vercel URL
APP_URL="your-app-name.vercel.app"

# 测试前端
curl https://$APP_URL

# 测试健康检查
curl https://$APP_URL/health

# 测试 API
curl https://$APP_URL/api

# 测试数据库连接
curl https://$APP_URL/api/users
```

## 🗄️ 数据库初始化

如果需要创建用户表，在 Supabase Dashboard → SQL Editor 中执行：

```sql
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
```

## 💡 成功后的访问地址

- **应用**: `https://vue-express-app.vercel.app`
- **API**: `https://vue-express-app.vercel.app/api`
- **Supabase**: `https://app.supabase.com/project/zknwbnwkkfjslnkafsga`

## 🎉 部署完成！

按照以上步骤，你将拥有一个完全功能的 Vue3 + Express 应用，部署在 Vercel + Supabase 上，完全免费！