# Vercel + Supabase 完全免费部署指南

## 📋 部署概览

这个方案使用以下免费服务：

- **前端**: Vercel Static Sites (免费)
- **后端**: Vercel Functions (免费)
- **数据库**: Supabase (500MB PostgreSQL免费)
- **缓存**: Upstash Redis (30MB免费)
- **总成本**: 完全免费

## 🔧 前置条件

1. GitHub 账户
2. Vercel 账户
3. Supabase 账户
4. Upstash Redis 账户

## 🚀 第一步：部署 Supabase 数据库

### 1.1 创建 Supabase 项目

1. 访问 [https://supabase.com](https://supabase.com)
2. 点击 "Start your project"
3. 使用 GitHub 账户登录
4. 点击 "New Project"
5. 选择组织
6. 创建新项目：
   - **Project Name**: `vue-express-app`
   - **Database Password**: 设置强密码
   - **Region**: 选择最近的区域
   - 点击 "Create new project"

### 1.2 初始化数据库

1. 在项目仪表板中，点击 "SQL Editor"
2. 点击 "New query"
3. 复制并粘贴 `scripts/init-supabase.sql` 的内容
4. 点击 "Run" 执行脚本

### 1.3 获取数据库连接信息

1. 在项目设置中，点击 "Database"
2. 复制以下信息：
   - **Connection string**: `postgresql://postgres:[YOUR-PASSWORD]@[HOST]:5432/postgres`
   - **Project URL**: `https://[PROJECT-ID].supabase.co`
   - **API Key**: 在 "API" 部分找到 `anon` key

## 🔥 第二步：设置 Upstash Redis

### 2.1 创建 Upstash Redis 数据库

1. 访问 [https://upstash.com](https://upstash.com)
2. 使用 GitHub 账户登录
3. 点击 "Create Redis Database"
4. 配置：
   - **Database Name**: `vue-express-cache`
   - **Region**: 选择与 Vercel 相同的区域
   - **Enable TLS**: ✅ 启用
   - 点击 "Create"

### 2.2 获取 Redis 连接信息

1. 在数据库详情页面，点击 "REST API" 标签
2. 复制以下信息：
   - **UPSTASH_REDIS_REST_URL**: `https://[ID].upstash.io`
   - **UPSTASH_REDIS_REST_TOKEN**: Redis 密码

## ⚡ 第三步：部署到 Vercel

### 3.1 准备代码仓库

1. 将项目推送到 GitHub：
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/vue-express-app.git
git push -u origin main
```

### 3.2 部署到 Vercel

1. 访问 [https://vercel.com](https://vercel.com)
2. 使用 GitHub 账户登录
3. 点击 "Add New..." → "Project"
4. 选择你的 GitHub 仓库
5. 配置项目：
   - **Framework Preset**: Vite
   - **Root Directory**: `frontend`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`

### 3.3 配置环境变量

在 Vercel 项目设置中，添加以下环境变量：

```bash
# Supabase 配置
DATABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres
SUPABASE_URL=https://[PROJECT-ID].supabase.co
SUPABASE_ANON_KEY=[ANON_KEY]

# Upstash Redis 配置
UPSTASH_REDIS_REST_URL=https://[ID].upstash.io
UPSTASH_REDIS_REST_TOKEN=[TOKEN]

# 应用配置
NODE_ENV=production
```

### 3.4 重新部署

添加环境变量后，触发重新部署：
1. 在 Vercel 控制台点击 "Deployments"
2. 点击右上角的三个点
3. 选择 "Redeploy"

## 🔍 第四步：验证部署

### 4.1 检查前端

访问你的 Vercel 域名（如 `https://vue-express-app.vercel.app`），应该看到 Vue3 前端页面。

### 4.2 测试 API 端点

使用浏览器或 curl 测试 API：

```bash
# 健康检查
curl https://vue-express-app.vercel.app/api

# 用户列表
curl https://vue-express-app.vercel.app/api/users

# 缓存测试
curl https://vue-express-app.vercel.app/api/examples/cache-test

# 服务状态
curl https://vue-express-app.vercel.app/api/examples/status
```

### 4.3 检查数据库

1. 登录 Supabase 仪表板
2. 点击 "Table Editor"
3. 选择 `users` 表
4. 应该看到示例数据

### 4.4 检查缓存

1. 登录 Upstash 控制台
2. 点击 "Browser"
3. 查看缓存键值对

## 🛠️ 第五步：本地开发

### 5.1 设置本地环境

1. 复制环境变量文件：
```bash
cp frontend/.env.example frontend/.env
cp backend/.env.example backend/.env
```

2. 编辑 `.env` 文件，添加云服务的连接信息

### 5.2 本地开发启动

```bash
# 启动前端
cd frontend
npm install
npm run dev

# 启动后端 (在另一个终端)
cd backend
npm install
npm run dev
```

## 📊 免费额度限制

### Vercel 免费额度
- **带宽**: 100GB/月
- **函数调用**: 100万次/月
- **执行时间**: 10秒/次
- **内存**: 1GB

### Supabase 免费额度
- **数据库存储**: 500MB
- **带宽**: 2GB/月
- **API 调用**: 5万次/月
- **文件存储**: 50MB

### Upstash Redis 免费额度
- **内存**: 30MB
- **命令/天**: 3万次
- **连接**: 10个

## 🔧 故障排除

### 常见问题

1. **函数超时**
   - 检查 API 执行时间
   - 优化数据库查询
   - 减少外部 API 调用

2. **数据库连接失败**
   - 检查连接字符串
   - 确认密码正确
   - 检查 IP 白名单

3. **Redis 连接失败**
   - 验证 URL 和 Token
   - 检查网络配置
   - 确认 TLS 设置

4. **构建失败**
   - 检查依赖版本
   - 确认 Node.js 版本
   - 查看构建日志

### 监控使用量

1. **Vercel**: 在控制台查看 "Usage" 标签
2. **Supabase**: 在仪表板查看 "Usage"
3. **Upstash**: 在控制台查看 "Metrics"

## 🚀 升级方案

如果超出免费额度，可以考虑：

### 付费升级
- **Vercel Pro**: $20/月 (更多函数调用)
- **Supabase Pro**: $25/月 (更大数据库)
- **Upstash Pro**: $5/月 (更多内存)

### 备选方案
- **数据库**: PlanetScale (免费 5GB)
- **缓存**: Cloudflare KV (免费 10万次读取/天)
- **部署**: Railway ($5/月)

## 🎉 完成！

恭喜！你已经成功将 Vue3 + Express 应用部署到 Vercel + Supabase + Upstash 的完全免费架构中。

### 项目特性
✅ 前端 SSR 优化
✅ 全球 CDN 加速
✅ 自动 HTTPS
✅ 数据库备份
✅ Redis 缓存层
✅ 实时监控
✅ 零成本运维

### 下一步
- 添加自定义域名
- 设置 CDN 缓存策略
- 配置错误监控
- 添加 API 限流
- 设置数据库索引优化