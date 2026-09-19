import type { FastifyInstance } from "fastify";
import { ok } from "../../shared/response.js";

export async function registerAuthRoutes(app: FastifyInstance) {
  app.post("/api/v1/auth/session", async () => ok({ mode: "anonymous", token: null }));
  app.delete("/api/v1/auth/session", async () => ok({ deleted: true }));
  app.get("/api/v1/me", async () => ok({ user: null, mode: "anonymous" }));
}
