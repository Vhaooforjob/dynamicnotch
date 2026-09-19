import { syncPullSchema, syncPushSchema } from "@notchflow/contracts";
import type { FastifyInstance } from "fastify";
import { ok } from "../../shared/response.js";

let version = 0;

export async function registerSyncRoutes(app: FastifyInstance) {
  app.post("/api/v1/sync/push", async (request) => {
    const input = syncPushSchema.parse(request.body);
    version += input.mutations.length;
    return ok({ accepted: input.mutations.length, version });
  });

  app.post("/api/v1/sync/pull", async (request) => {
    const input = syncPullSchema.parse(request.body);
    return ok({ deviceId: input.deviceId, sinceVersion: input.sinceVersion, records: [], cursor: version });
  });
}
