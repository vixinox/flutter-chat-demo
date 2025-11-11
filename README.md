# AI Chat Flutter Demo

基于 **Flutter** 构建的 AI 对话 demo，支持流式传输响应（Server-Sent Events / SSE）。  

提供以下服务：
- 模型切换
- 创建和管理会话
- Markdown文本请求与响应
- 对话流式传输

## ⚠️ 完成度
- Demo 阶段，功能未完善
- 网络错误重试机制不足
- 可能需要手动热重载恢复

### 1. 安装依赖
```bash
flutter pub get
```

### 2. 创建 `.env` 文件
```env
# assets/.env
API_BASE_URL=http://10.0.2.2:3000
```

### 3. 初始化后端
```bash
cd backend
bun install
bunx prisma generate
```

### 4. 设置 ./backend/.env
```env
DATABASE_URL="postgresql://"
API_ENDPOINT="https://your.api/v1/chat/completions"
API_KEY="sk-"
```

### 5. 运行后端
```bash
bun run dev
```
