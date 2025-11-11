import dotenv from "dotenv";
dotenv.config();

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`环境变量 ${name} 未配置`);
  return value;
}

export const config = {
  env: process.env.NODE_ENV || "development",
  port: parseInt(process.env.PORT || "3000", 10),
  dbUrl: requireEnv("DATABASE_URL"),
  apiKey: requireEnv("API_KEY"),
  apiEndpoint: requireEnv("API_ENDPOINT"),
  corsOrigin: process.env.CORS_ORIGIN || "*",
};