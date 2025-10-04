// MongoDB 初始化脚本
db = db.getSiblingDB('vue-express-app');

// 创建用户
db.createUser({
  user: 'app_user',
  pwd: 'app_password',
  roles: [
    {
      role: 'readWrite',
      db: 'vue-express-app'
    }
  ]
});

// 创建示例集合和插入初始数据
db.createCollection('users');

db.users.insertMany([
  {
    name: '张三',
    email: 'zhangsan@example.com',
    createdAt: new Date(),
    isActive: true
  },
  {
    name: '李四',
    email: 'lisi@example.com',
    createdAt: new Date(),
    isActive: true
  }
]);

// 创建索引
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ createdAt: -1 });

print('MongoDB 初始化完成');