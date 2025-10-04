-- Supabase 数据库初始化脚本

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建示例数据
INSERT INTO users (name, email) VALUES
('张三', 'zhangsan@example.com'),
('李四', 'lisi@example.com'),
('王五', 'wangwu@example.com')
ON CONFLICT (email) DO NOTHING;

-- 创建缓存表 (可选，用于持久化缓存)
CREATE TABLE IF NOT EXISTS cache (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT NOT NULL,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建触发器函数：更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为 users 表创建触发器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- 创建 RLS (Row Level Security) 策略
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 创建策略：允许所有操作（开发环境）
DROP POLICY IF EXISTS "Enable all operations for users" ON users;
CREATE POLICY "Enable all operations for users" ON users
    FOR ALL USING (true) WITH CHECK (true);

-- 插入数据库配置信息
INSERT INTO cache (key, value, expires_at)
VALUES ('db_initialized', 'true', NULL)
ON CONFLICT (key) DO UPDATE SET value = 'true';

-- 输出初始化完成信息
DO $$
BEGIN
    RAISE NOTICE '✅ Supabase 数据库初始化完成';
    RAISE NOTICE '✅ 用户表 users 已创建';
    RAISE NOTICE '✅ 示例数据已插入';
    RAISE NOTICE '✅ 索引和触发器已创建';
END $$;