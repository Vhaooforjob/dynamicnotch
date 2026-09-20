import { randomUUID } from "node:crypto";
import { deviceInputSchema } from "@dynamicnotch/contracts";
import type { FastifyInstance } from "fastify";
import { ok } from "../../shared/response.js";

type Device = {
  id: string;
  deviceIdentifier: string;
  name: string;
  platform: string;
  appVersion?: string;
  createdAt: string;
};

const devices = new Map<string, Device>();

export async function registerDeviceRoutes(app: FastifyInstance) {
  app.get("/api/v1/devices", async () => ok([...devices.values()]));

  app.post("/api/v1/devices", async (request, reply) => {
    const input = deviceInputSchema.parse(request.body);
    const device: Device = {
      id: randomUUID(),
      ...input,
      createdAt: new Date().toISOString()
    };
    devices.set(device.id, device);
    return reply.status(201).send(ok(device));
  });

  app.delete("/api/v1/devices/:id", async (request) => {
    const { id } = request.params as { id: string };
    devices.delete(id);
    return ok({ deleted: true });
  });
}
