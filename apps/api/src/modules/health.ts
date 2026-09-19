import type { FastifyInstance } from "fastify";
import type { DatabaseClient } from "../plugins/database.js";
import { ok } from "../shared/response.js";

export async function registerHealthRoutes(app: FastifyInstance, database: DatabaseClient) {
  app.get("/", async () => ok({ service: "notchflow-api", status: "ok" }));

  app.get("/api/v1/health", async () => {
    const databaseStatus = await database.health();

    return ok({
      status: databaseStatus === "unavailable" ? "degraded" : "ok",
      database: databaseStatus
    });
  });
}
