# Supabase 快速启动指南

## 🚀 一键启动

```bash
# 方式一：使用自动化脚本 (推荐)
npm run setup:supabase

# 方式二：使用 Bash 脚本
./scripts/dev-setup.sh

# 方式三：手动步骤 (见下方)
```

## 📋 前置条件

- **Node.js** 18+
- **npm** 或 **yarn**
- **Docker** (可选，用于本地数据库)
- **Supabase CLI** (脚本会自动安装)

## 🛠️ 手动设置步骤

### 1. 安装依赖

```bash
# 安装所有依赖
npm run install:all

# 或分别安装
npm install
cd frontend && npm install
cd ../backend && npm install
```

### 2. 设置 Supabase

```bash
# 初始化 Supabase 项目
supabase init

# 启动本地 Supabase
supabase start

# 查看状态
supabase status
```

### 3. 配置环境变量

#### 后端配置 (`backend/.env.local`)
```bash
# Supabase 配置
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key-here

# Redis 配置
REDIS_URL=redis://localhost:6379

# 应用配置
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000
```

#### 前端配置 (`frontend/.env.local`)
```bash
VITE_API_BASE_URL=http://localhost:5000/api
VITE_SUPABASE_URL=http://localhost:54321
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. 启动开发服务器

```bash
# 启动所有服务 (推荐)
npm run dev

# 或分别启动
npm run dev:backend  # 后端 :5000
npm run dev:frontend # 前端 :3000
```

## 🌐 访问地址

启动成功后，你可以访问以下地址：

- **前端应用**: http://localhost:3000
- **后端 API**: http://localhost:5000
- **API 文档**: http://localhost:5000/api
- **Supabase Studio**: http://localhost:54323
- **数据库**: localhost:54322

## 🧪 测试连接

### 1. 健康检查
```bash
curl http://localhost:5000/health
```

### 2. 测试 API
```bash
# 获取用户列表
curl http://localhost:5000/api/users

# 测试缓存
curl http://localhost:5000/api/examples/cache-test

# 检查服务状态
curl http://localhost:5000/api/examples/status
```

### 3. 检查数据库
访问 http://localhost:54323 查看数据库表和数据。

## 🔧 常用命令

### Supabase 命令
```bash
# 启动服务
supabase start

# 停止服务
supabase stop

# 重置数据库
supabase db reset

# 打开 Studio
supabase db studio

# 查看状态
supabase status

# 推送迁移
supabase db push

# 链接云端项目
supabase link --project-ref YOUR_PROJECT_ID
```

### 项目命令
```bash
# 开发
npm run dev              # 启动前后端
npm run dev:frontend     # 仅启动前端
npm run dev:backend      # 仅启动后端

# 构建
npm run build            # 构建前后端

# Supabase
npm run setup:supabase   # 自动设置 Supabase
npm run dev:supabase     # 启动 Supabase
npm run studio           # 打开 Supabase Studio
npm run stop:supabase    # 停止 Supabase
npm run reset:supabase   # 重置 Supabase 数据库

# 部署
npm run deploy:vercel    # 部署到 Vercel
```

## 🔧 故障排除

### 常见问题

#### 1. Supabase 启动失败
```bash
# 检查 Docker 是否运行
docker --version
docker ps

# 重启 Docker
sudo systemctl restart docker

# 清理并重新启动
supabase stop
supabase start
```

#### 2. 端口冲突
```bash
# 查看端口占用
lsof -i :3000
lsof -i :5000
lsof -i :54321
lsof -i :54322
lsof -i :54323

# 停止占用进程
kill -9 <PID>
```

#### 3. 数据库连接失败
```bash
# 检查 Supabase 状态
supabase status

# 重置数据库
supabase db reset

# 检查环境变量
cat backend/.env.local
```

#### 4. 前端连接 API 失败
- 检查后端是否启动 (http://localhost:5000/health)
- 检查前端环境变量 (`frontend/.env.local`)
- 检查 CORS 配置

#### 5. Redis 连接失败
```bash
# 检查 Redis 是否运行
redis-cli ping

# 启动本地 Redis
docker run -d -p 6379:6379 redis:7.2-alpine
```

## 🔄 重置环境

如果遇到问题，可以完全重置开发环境：

```bash
# 停止 Supabase
supabase stop

# 删除 Supabase 目录
rm -rf supabase

# 清理环境变量
rm -f backend/.env.local
rm -f frontend/.env.local

# 清理 node_modules (可选)
rm -rf node_modules frontend/node_modules backend/node_modules

# 重新运行设置脚本
npm run setup:supabase
```

## 🌍 部署到云端

### 1. 创建云端 Supabase 项目
1. 访问 [supabase.com](https://supabase.com)
2. 创建新项目
3. 记录连接信息

### 2. 部署到 Vercel
```bash
# 安装 Vercel CLI
npm install -g vercel

# 部署
npm run deploy:vercel
```

### 3. 配置云端环境变量
在 Vercel 项目设置中添加：
- `DATABASE_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`

## 📚 更多资源

- [Supabase 官方文档](https://supabase.com/docs)
- [Vercel 部署指南](./VERCEL_SUPABASE_DEPLOYMENT.md)
- [项目架构说明](../README.md)
- [API 接口文档](../docs/api.md)

## 🎯 下一步

1. ✅ 完成本地开发环境设置
2. 🎨 修改前端页面和组件
3. 🔧 添加新的 API 端点
4. 📊 扩展数据库表结构
5. 🚀 部署到 Vercel + Supabase

---

## 🤝 需要帮助？

如果在设置过程中遇到问题，可以：

1. 检查 [故障排除](#-故障排除) 部分
2. 查看项目 Issues
3. 参考 [官方文档](https://supabase.com/docs)

Happy coding! 🎉