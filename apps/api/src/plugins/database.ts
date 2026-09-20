import { Pool } from "pg";
import type { Env } from "../config/env.js";

export type DatabaseHealth = "connected" | "not_configured" | "unavailable";

export interface DatabaseDependency {
  health(): Promise<DatabaseHealth>;
  close(): Promise<void>;
}

export class DatabaseClient implements DatabaseDependency {
  private readonly pool?: Pool;

  constructor(env: Env) {
    if (env.DATABASE_URL) {
      this.pool = new Pool({ connectionString: env.DATABASE_URL, max: 4 });
    }
  }

  async health(): Promise<DatabaseHealth> {
    if (!this.pool) {
      return "not_configured";
    }

    try {
      await this.pool.query("select 1");
      return "connected";
    } catch {
      return "unavailable";
    }
  }

  async close(): Promise<void> {
    await this.pool?.end();
  }
}
