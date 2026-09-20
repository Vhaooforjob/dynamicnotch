import type { FastifyInstance } from "fastify";
import type { DatabaseDependency } from "../plugins/database.js";
import { ok } from "../shared/response.js";

export async function registerHealthRoutes(app: FastifyInstance, database: DatabaseDependency) {
  app.get("/", async () => ok({ service: "dynamicnotch-api", status: "ok" }));

  app.get("/api/v1/health", async () => {
    const databaseStatus = await database.health();

    return ok({
      status: databaseStatus === "unavailable" ? "degraded" : "ok",
      database: databaseStatus
    });
  });
}
