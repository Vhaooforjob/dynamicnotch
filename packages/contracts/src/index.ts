import { z } from "zod";

export const apiEnvelopeSchema = <T extends z.ZodType>(data: T) =>
  z.object({
    data,
    meta: z.record(z.string(), z.unknown()).default({})
  });

export const deviceInputSchema = z.object({
  deviceIdentifier: z.string().min(1),
  name: z.string().min(1),
  platform: z.enum(["macos", "ios", "web"]).default("macos"),
  appVersion: z.string().optional()
});

export const boardInputSchema = z.object({
  name: z.string().min(1).max(80),
  sortOrder: z.number().int().min(0).default(0)
});

export const settingsInputSchema = z.object({
  settings: z.record(z.string(), z.unknown())
});

export const syncPushSchema = z.object({
  deviceId: z.string().uuid(),
  mutations: z.array(
    z.object({
      entityType: z.string().min(1),
      entityId: z.string().uuid(),
      operation: z.enum(["create", "update", "delete"]),
      payload: z.record(z.string(), z.unknown()).default({})
    })
  )
});

export const syncPullSchema = z.object({
  deviceId: z.string().uuid(),
  sinceVersion: z.number().int().min(0).default(0)
});

export type DeviceInput = z.infer<typeof deviceInputSchema>;
export type BoardInput = z.infer<typeof boardInputSchema>;
