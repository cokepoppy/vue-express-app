# 🚀 完整部署指南 - Vercel + Supabase

## 📋 部署概览

这个指南将帮助你将 Vue3 + Express + Supabase 应用部署到云端，实现**完全免费**的在线服务。

**部署架构:**
```
前端 (Vue3) → Vercel Static Sites (免费)
后端 (API) → Vercel Functions (免费)
数据库 → Supabase PostgreSQL (500MB 免费)
缓存 → Upstash Redis (30MB 免费)
```

## 🎯 一键部署 (推荐)

```bash
# 1. 运行自动化部署脚本
./scripts/deploy.sh

# 或者分步执行
npm run check-env    # 检查环境变量
npm run deploy       # 开始部署
```

## 📝 详细部署步骤

### 步骤 1: 准备 GitHub 仓库

```bash
# 初始化 Git 仓库 (如果还没有)
git init

# 添加所有文件
git add .

# 提交代码
git commit -m "feat: Vue3 + Express + Supabase project ready for deployment"

# 创建 GitHub 仓库
# 访问 https://github.com/new 创建新仓库

# 连接远程仓库
git remote add origin https://github.com/yourusername/vue-express-app.git

# 推送代码
git push -u origin main
```

### 步骤 2: 创建 Supabase 项目

1. **访问 Supabase**
   - 打开 [https://supabase.com](https://supabase.com)
   - 使用 GitHub 账户登录

2. **创建新项目**
   - 点击 "New Project"
   - 选择你的 GitHub 组织
   - 设置项目信息:
     - **Project Name**: `vue-express-app`
     - **Database Password**: 设置强密码 (记录下来!)
     - **Region**: 选择离你最近的区域
   - 点击 "Create new project"

3. **等待项目创建** (约 1-2 分钟)

4. **获取连接信息**
   - 进入 Project Settings → Database
   - 复制 **Connection string**:
     ```
     postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
     ```
   - 进入 Project Settings → API
   - 复制 **Project URL**:
     ```
     https://[PROJECT-REF].supabase.co
     ```
   - 复制 **anon public** key:
     ```
     eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     ```

5. **初始化数据库**
   - 进入 SQL Editor
   - 点击 "New query"
   - 复制并粘贴 `scripts/init-supabase.sql` 的内容
   - 点击 "Run" 执行脚本

### 步骤 3: 创建 Upstash Redis (可选)

1. **访问 Upstash**
   - 打开 [https://upstash.com](https://upstash.com)
   - 使用 GitHub 账户登录

2. **创建 Redis 数据库**
   - 点击 "Create Redis Database"
   - 设置配置:
     - **Database Name**: `vue-express-cache`
     - **Region**: 选择与 Vercel 相同的区域
     - **Enable TLS**: ✅ 启用
   - 点击 "Create"

3. **获取连接信息**
   - 在数据库详情页面点击 "REST API"
   - 复制 **REST URL**:
     ```
     https://redis-12345.upstash.io
     ```
   - 复制 **REST Token**:
     ```
     redis-token-12345
     ```

### 步骤 4: 部署到 Vercel

#### 方式 A: 使用 Vercel CLI (推荐)

1. **安装 Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **登录 Vercel**
   ```bash
   vercel login
   ```

3. **检查环境变量**
   ```bash
   node scripts/check-env.js
   ```

4. **配置环境变量**
   ```bash
   # 必需的环境变量
   vercel env add DATABASE_URL
   # 粘贴 Supabase Connection string

   vercel env add SUPABASE_URL
   # 粘贴 Supabase Project URL

   vercel env add SUPABASE_ANON_KEY
   # 粘贴 Supabase anon key

   # 可选的环境变量
   vercel env add UPSTASH_REDIS_REST_URL
   # 粘贴 Upstash Redis URL

   vercel env add UPSTASH_REDIS_REST_TOKEN
   # 粘贴 Upstash Redis Token
   ```

5. **部署项目**
   ```bash
   ./scripts/deploy.sh
   ```

#### 方式 B: 使用 Vercel Web 界面

1. **连接 GitHub 仓库**
   - 访问 [https://vercel.com](https://vercel.com)
   - 点击 "New Project"
   - 导入你的 GitHub 仓库

2. **配置项目设置**
   - **Framework Preset**: Vite
   - **Root Directory**: `frontend`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`

3. **添加环境变量**
   - 在项目设置中点击 "Environment Variables"
   - 添加以下变量:
     ```
     DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
     SUPABASE_URL=https://[REF].supabase.co
     SUPABASE_ANON_KEY=[ANON_KEY]
     UPSTASH_REDIS_REST_URL=https://redis-xxx.upstash.io
     UPSTASH_REDIS_REST_TOKEN=[TOKEN]
     NODE_ENV=production
     ```

4. **部署**
   - 点击 "Deploy" 开始部署
   - 等待部署完成 (约 2-3 分钟)

### 步骤 5: 验证部署

1. **获取部署 URL**
   - 部署完成后，Vercel 会提供你的应用 URL
   - 通常格式为: `https://vue-express-app.vercel.app`

2. **测试应用功能**
   ```bash
   # 使用提供的检查脚本
   ./scripts/check-deployment.sh your-domain.vercel.app

   # 或手动测试
   curl https://your-domain.vercel.app/health
   curl https://your-domain.vercel.app/api
   curl https://your-domain.vercel.app/api/users
   ```

3. **检查前端页面**
   - 在浏览器中访问你的 URL
   - 测试 API 测试功能
   - 确认页面正常显示

## 🛠️ 常用部署命令

```bash
# 部署命令
npm run deploy:vercel          # 部署到生产环境
vercel --prod                  # 同上
vercel                         # 部署到预览环境

# 环境变量管理
vercel env ls                  # 列出环境变量
vercel env add VAR_NAME        # 添加环境变量
vercel env rm VAR_NAME         # 删除环境变量
vercel env pull                # 拉取环境变量到本地

# 部署管理
vercel ls                      # 列出部署历史
vercel logs                    # 查看部署日志
vercel --version               # 查看 CLI 版本
```

## 🔧 故障排除

### 常见问题

#### 1. 部署失败
```bash
# 查看详细日志
vercel logs

# 检查构建配置
cat vercel.json

# 本地测试构建
cd frontend && npm run build
```

#### 2. 环境变量问题
```bash
# 检查环境变量
vercel env ls

# 测试环境变量
vercel env pull
cat .env.production

# 重新添加环境变量
vercel env add DATABASE_URL
```

#### 3. API 连接问题
- 检查 Supabase 项目是否运行
- 验证连接字符串格式
- 确认 IP 白名单设置

#### 4. 数据库连接失败
```bash
# 测试数据库连接
psql "postgresql://postgres:password@db.ref.supabase.co:5432/postgres"

# 检查 Supabase 状态
# 登录 Supabase Dashboard 查看项目状态
```

#### 5. 前端页面空白
- 检查构建是否成功
- 验证路由配置
- 查看浏览器控制台错误

### 调试技巧

1. **本地测试**
   ```bash
   # 使用生产环境变量本地测试
   cp .env.production .env.local
   npm run dev
   ```

2. **分步部署**
   ```bash
   # 先部署后端 API
   vercel --prod api/index.ts

   # 再部署前端
   vercel --prod frontend/
   ```

3. **查看日志**
   ```bash
   # 实时查看日志
   vercel logs --follow

   # 查看特定部署日志
   vercel logs [deployment-id]
   ```

## 📊 监控和维护

### 使用量监控

1. **Vercel 使用量**
   - 访问 Vercel Dashboard → Usage
   - 监控带宽、函数调用次数

2. **Supabase 使用量**
   - 访问 Supabase Dashboard → Usage
   - 监控数据库存储、API 调用

3. **Upstash 使用量**
   - 访问 Upstash Console → Metrics
   - 监控内存使用、命令执行

### 性能优化

```bash
# 启用边缘函数
# 在 vercel.json 中添加 regions 配置

# 配置缓存策略
# 在 API 响应中添加 Cache-Control 头

# 优化数据库查询
# 在 Supabase 中添加适当的索引
```

## 🎉 部署完成！

### ✅ 成功标志
- [ ] 前端页面正常加载
- [ ] API 健康检查通过
- [ ] 数据库连接正常
- [ ] 缓存功能工作 (如果配置)
- [ ] 所有测试端点响应正常

### 🌟 访问你的应用
- **主页**: `https://your-domain.vercel.app`
- **API**: `https://your-domain.vercel.app/api`
- **健康检查**: `https://your-domain.vercel.app/health`

### 📝 下一步
1. 添加自定义域名
2. 设置 SSL 证书 (自动)
3. 配置错误监控
4. 设置备份策略
5. 优化性能

---

## 🆘 需要帮助？

如果在部署过程中遇到问题：

1. 查看 [故障排除](#-故障排除) 部分
2. 检查 [Vercel 文档](https://vercel.com/docs)
3. 参考 [Supabase 文档](https://supabase.com/docs)
4. 查看项目 Issues

**Happy Deploying! 🚀**