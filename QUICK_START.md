# 快速开始指南

## 本地开发环境

### 1. 环境要求
- Node.js 18+
- MongoDB 7.0+
- Redis 7.2+
- Docker (可选)

### 2. 安装依赖

```bash
# 安装前端依赖
cd frontend
npm install

# 安装后端依赖
cd ../backend
npm install
```

### 3. 环境配置

```bash
# 复制环境变量文件
cp frontend/.env.example frontend/.env
cp backend/.env.example backend/.env

# 根据实际情况修改环境变量
```

### 4. 启动服务

#### 方式一: 直接启动
```bash
# 启动后端 (终端1)
cd backend
npm run dev

# 启动前端 (终端2)
cd frontend
npm run dev
```

#### 方式二: Docker 启动
```bash
# 在项目根目录
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 5. 访问应用
- 前端: http://localhost:3000
- 后端 API: http://localhost:5000/api
- 健康检查: http://localhost:5000/health

## 云部署

### Vercel 部署 (推荐)

1. **安装 Vercel CLI**
```bash
npm i -g vercel
```

2. **部署前端**
```bash
cd frontend
vercel --prod
```

3. **部署后端**
```bash
cd backend
vercel --prod
```

4. **配置环境变量**
在 Vercel 控制台添加：
- MONGODB_URI
- REDIS_URL
- NODE_ENV=production

### Railway 部署

1. **连接 GitHub 仓库**
2. **配置环境变量**
3. **自动部署**

### Render 部署

1. **连接 GitHub 仓库**
2. **使用 render.yaml 配置**
3. **自动部署**

## 开发指南

### API 端点

```
GET  /api             - API 信息
GET  /api/users       - 获取用户列表
POST /api/users       - 创建用户
GET  /api/users/:id   - 获取单个用户
GET  /api/examples/cache-test - Redis 缓存测试
GET  /api/examples/status    - 服务状态检查
GET  /health          - 健康检查
```

### 项目结构

```
vue-express-app/
├── frontend/              # Vue3 前端
│   ├── src/
│   │   ├── components/    # 组件
│   │   ├── views/         # 页面
│   │   ├── api/           # API 调用
│   │   └── router/        # 路由
│   ├── package.json
│   └── vite.config.ts
├── backend/               # Express 后端
│   ├── src/
│   │   ├── controllers/   # 控制器
│   │   ├── routes/        # 路由
│   │   ├── models/        # 数据模型
│   │   ├── middleware/    # 中间件
│   │   ├── config/        # 配置
│   │   └── utils/         # 工具函数
│   ├── package.json
│   └── tsconfig.json
├── docs/                  # 文档
├── scripts/               # 脚本
├── docker-compose.yml     # Docker 编排
└── README.md
```

## 故障排除

### 常见问题

1. **MongoDB 连接失败**
   - 检查 MongoDB 服务是否启动
   - 验证连接字符串是否正确

2. **Redis 连接失败**
   - 检查 Redis 服务是否启动
   - 确认端口配置

3. **端口冲突**
   - 修改 .env 文件中的端口配置
   - 或停止占用端口的其他服务

4. **依赖安装失败**
   - 清除 npm 缓存: `npm cache clean --force`
   - 删除 node_modules 重新安装

### 调试技巧

1. **查看日志**
```bash
# Docker 日志
docker-compose logs -f [service-name]

# 应用日志
tail -f logs/app.log
```

2. **测试连接**
```bash
# 测试 API
curl http://localhost:5000/health

# 测试数据库连接
mongosh mongodb://localhost:27017/vue-express-app

# 测试 Redis 连接
redis-cli ping
```

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

## 许可证

MIT License