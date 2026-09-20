import { describe, expect, it } from "vitest";
import { buildApp } from "../src/app.js";

describe("health", () => {
  it("returns api status", async () => {
    const app = await buildApp({
      database: {
        health: async () => "connected",
        close: async () => {}
      }
    });
    const response = await app.inject({ method: "GET", url: "/api/v1/health" });
    expect(response.statusCode).toBe(200);
    expect(response.json().data.status).toBe("ok");
    await app.close();
  });
});
