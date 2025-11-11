import express from "express";
import cors from "cors";
import { config } from "./config";
import conversationRoutes from "./routes/conversations";
import messageRoutes from "./routes/messages";
import modelRoutes from "./routes/models";
import chatRoutes from "./routes/chat";

const app = express();

app.use((req, res, next) => {
  const start = Date.now();
  console.log('🟢 [请求日志]');
  console.log('方法:', req.method);
  console.log('路径:', req.originalUrl);
  console.log('时间:', new Date().toISOString());
  console.log('来源 IP:', req.ip);
  console.log('请求头:', JSON.stringify(req.headers, null, 2));
  if (Object.keys(req.params).length) console.log('路径参数:', req.params);
  if (Object.keys(req.query).length) console.log('Query参数:', req.query);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('请求Body:', JSON.stringify(req.body, null, 2));
  }

  const oldJson = res.json.bind(res);
  res.json = (data) => {
    const duration = Date.now() - start;
    console.log(`🔵 [响应日志] 状态码: ${res.statusCode} 耗时: ${duration}ms`);
    console.log('返回数据:', JSON.stringify(data, null, 2));
    console.log('-----------------------------');
    return oldJson(data);
  };

  next();
});

app.use(cors({
  origin: config.corsOrigin,
  credentials: true
}));
app.use(express.json({ limit: "10mb" }));

app.use("/conversations", conversationRoutes);
app.use("/messages", messageRoutes);
app.use("/models", modelRoutes);
app.use("/chat", chatRoutes);

app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('🚨 [全局错误]');
  console.error('方法:', req.method);
  console.error('路径:', req.originalUrl);
  console.error('params:', req.params);
  console.error('query:', req.query);
  console.error('body:', req.body);
  console.error('错误信息:', err.message);
  console.error('堆栈:', err.stack);
  res.status(err.status || 500).json({ error: err.message || "服务器内部错误" });
});

export default app;