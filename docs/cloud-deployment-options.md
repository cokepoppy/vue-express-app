# 免费云部署平台推荐

## 1. Vercel ⭐⭐⭐⭐⭐
**最适合前端 + 无服务器函数**

- **免费额度**:
  - 100GB 带宽/月
  - 无限静态网站托管
  - Serverless Functions: 100万次调用/月
  - 支持 Node.js 18+

- **优势**:
  - 零配置部署
  - 自动 HTTPS
  - 全球 CDN
  - Git 集成
  - 支持前端和 API 路由

- **限制**:
  - 函数执行时间 10 秒
  - 内存限制 1GB
  - 不支持持久化数据库

## 2. Netlify ⭐⭐⭐⭐
**适合静态网站 + Functions**

- **免费额度**:
  - 100GB 带宽/月
  - 300分钟构建时间
  - Netlify Functions: 125,000次调用/月

- **优势**:
  - 优秀的 CI/CD
  - 表单处理
  - 边缘函数
  - 分支预览

## 3. Railway ⭐⭐⭐⭐⭐
**最适合全栈应用**

- **免费额度**:
  - $5/月 免费额度
  - 支持 Docker 容器
  - 自动部署
  - 支持数据库

- **优势**:
  - 支持完整栈 (前端 + 后端 + 数据库)
  - 简单的 Docker 部署
  - 内置 PostgreSQL
  - 环境变量管理

## 4. Render ⭐⭐⭐⭐
**适合生产级应用**

- **免费额度**:
  - Web Services: 750小时/月
  - PostgreSQL: 256MB RAM
  - Redis: 免费层级

- **优势**:
  - 支持多种语言
  - 自动 HTTPS
  - 私有数据库
  - 蓝绿部署

## 5. Fly.io ⭐⭐⭐⭐
**适合全球化部署**

- **免费额度**:
  - 160小时/月 共享 CPU
  - 3GB 持久存储
  - 全球多个地区

- **优势**:
  - 接近用户的部署
  - Docker 支持
  - 自定义域名

## 6. Heroku ⭐⭐⭐
**经典平台免费额度减少**

- **免费额度**:
  - 已取消免费层级 (2022年后)
  - 只有 Eco dynos ($5/月)

## 7. Supabase ⭐⭐⭐⭐⭐
**Firebase 替代品**

- **免费额度**:
  - 500MB 数据库
  - 50MB 文件存储
  - 2个 API 密钥
  - 60,000 月活用户

- **优势**:
  - PostgreSQL 数据库
  - 实时订阅
  - 身份验证
  - 边缘函数

## 8. PlanetScale ⭐⭐⭐⭐⭐
**专业 MySQL 数据库**

- **免费额度**:
  - 5GB 存储
  - 10亿行读取
  - 无限分支
  - 自动备份

## 9. MongoDB Atlas ⭐⭐⭐⭐⭐
**MongoDB 云数据库**

- **免费额度**:
  - 512MB 存储
  - 无限集群
  - 全网访问

## 10. Redis Cloud ⭐⭐⭐⭐
**Redis 云服务**

- **免费额度**:
  - 30MB 内存
  - 30,000 命令/天
  - 高可用性

## 推荐组合方案

### 方案一: Vercel + Supabase (推荐)
- **前端**: Vercel (Vue3)
- **后端**: Vercel Functions (Express)
- **数据库**: Supabase (PostgreSQL)
- **缓存**: 内置或 Upstash Redis
- **成本**: 完全免费

### 方案二: Railway (简单)
- **全栈**: Railway (Docker)
- **数据库**: Railway PostgreSQL
- **缓存**: Railway Redis
- **成本**: $5/月额度内免费

### 方案三: Render + 外部数据库
- **前端**: Render Static Site
- **后端**: Render Web Service
- **数据库**: MongoDB Atlas
- **缓存**: Redis Cloud
- **成本**: 基本免费

## 部署建议

1. **开发阶段**: 使用 Vercel + Supabase
2. **小规模项目**: Railway 一站式解决方案
3. **需要更多控制**: Render + 独立数据库服务
4. **企业级**: 考虑付费方案

## 注意事项

- 免费额度通常有使用限制
- 某些平台需要信用卡验证
- 注意数据安全和备份
- 监控使用量避免超额费用