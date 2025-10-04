# Vue3 + Express 全栈项目

## 项目结构
```
vue-express-app/
├── frontend/          # Vue3 前端项目
├── backend/           # Express 后端项目
├── docs/             # 项目文档
├── docker-compose.yml # Docker 编排文件
└── README.md         # 项目说明
```

## 技术栈
- **前端**: Vue 3 + TypeScript + Vite
- **后端**: Express + Node.js + TypeScript
- **数据库**: MongoDB/PostgreSQL
- **缓存**: Redis
- **部署**: Docker + 云平台

## 🚀 快速启动

### 方式一：一键设置 Supabase (推荐)
```bash
npm run setup:supabase
```

### 方式二：使用脚本设置
```bash
./scripts/dev-setup.sh
```

### 方式三：手动启动
```bash
# 1. 安装依赖
npm run install:all

# 2. 启动 Supabase
npm run dev:supabase

# 3. 启动开发服务器
npm run dev

# 或分别启动
cd frontend && npm run dev  # 前端 :3000
cd backend && npm run dev   # 后端 :5000
```

### 方式四：Docker 启动
```bash
docker-compose up -d
```

## 🌐 访问地址

- **前端应用**: http://localhost:3000
- **后端 API**: http://localhost:5000/api
- **Supabase Studio**: http://localhost:54323
- **健康检查**: http://localhost:5000/health