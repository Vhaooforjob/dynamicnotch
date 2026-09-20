import { settingsInputSchema } from "@dynamicnotch/contracts";
import type { FastifyInstance } from "fastify";
import { ok } from "../../shared/response.js";

let settings: Record<string, unknown> = {};

export async function registerSettingsRoutes(app: FastifyInstance) {
  app.get("/api/v1/settings", async () => ok({ settings }));

  app.put("/api/v1/settings", async (request) => {
    const input = settingsInputSchema.parse(request.body);
    settings = input.settings;
    return ok({ settings, updatedAt: new Date().toISOString() });
  });
}
