import { z } from "zod";
import { loadEnvFile } from "./loadEnv.js";

loadEnvFile();

const envSchema = z.object({
  APP_ENV: z.enum(["development", "test", "production"]).default("development"),
  API_HOST: z.string().default("127.0.0.1"),
  API_PORT: z.coerce.number().int().positive().default(4000),
  DATABASE_URL: z.string().optional(),
  JWT_SECRET: z.string().min(16).default("development-only-secret"),
  LOG_LEVEL: z.string().default("info")
});

export type Env = z.infer<typeof envSchema>;

export const env = envSchema.parse(process.env);
