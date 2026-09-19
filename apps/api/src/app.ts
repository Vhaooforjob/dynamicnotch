import Fastify from "fastify";
import { ZodError } from "zod";
import { env } from "./config/env.js";
import { DatabaseClient } from "./plugins/database.js";
import { registerSecurity } from "./plugins/security.js";
import { registerAuthRoutes } from "./modules/auth/routes.js";
import { registerBoardRoutes } from "./modules/boards/routes.js";
import { registerDeviceRoutes } from "./modules/devices/routes.js";
import { registerHealthRoutes } from "./modules/health.js";
import { registerSettingsRoutes } from "./modules/settings/routes.js";
import { registerSyncRoutes } from "./modules/sync/routes.js";
import { ApiError, sendError } from "./shared/errors.js";

export async function buildApp() {
  const app = Fastify({
    logger: { level: env.LOG_LEVEL },
    bodyLimit: 1024 * 256
  });
  const database = new DatabaseClient(env);

  await registerSecurity(app);
  await registerHealthRoutes(app, database);
  await registerAuthRoutes(app);
  await registerDeviceRoutes(app);
  await registerSettingsRoutes(app);
  await registerBoardRoutes(app);
  await registerSyncRoutes(app);

  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof ZodError) {
      return sendError(reply, new ApiError("VALIDATION_ERROR", "Invalid request", 400, { issues: error.issues }));
    }

    app.log.error(error);
    return sendError(reply, new ApiError("INTERNAL_ERROR", "Unexpected server error", 500));
  });

  app.addHook("onClose", async () => {
    await database.close();
  });

  return app;
}
