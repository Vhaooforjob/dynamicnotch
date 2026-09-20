import { randomUUID } from "node:crypto";
import { boardInputSchema } from "@dynamicnotch/contracts";
import type { FastifyInstance } from "fastify";
import { ok } from "../../shared/response.js";

type Board = {
  id: string;
  name: string;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

const boards = new Map<string, Board>();

export async function registerBoardRoutes(app: FastifyInstance) {
  app.get("/api/v1/boards", async () => ok([...boards.values()].sort((a, b) => a.sortOrder - b.sortOrder)));

  app.post("/api/v1/boards", async (request, reply) => {
    const input = boardInputSchema.parse(request.body);
    const now = new Date().toISOString();
    const board: Board = { id: randomUUID(), ...input, createdAt: now, updatedAt: now };
    boards.set(board.id, board);
    return reply.status(201).send(ok(board));
  });

  app.patch("/api/v1/boards/:id", async (request) => {
    const { id } = request.params as { id: string };
    const current = boards.get(id);
    const input = boardInputSchema.partial().parse(request.body);
    const updated = {
      id,
      name: input.name ?? current?.name ?? "Untitled",
      sortOrder: input.sortOrder ?? current?.sortOrder ?? 0,
      createdAt: current?.createdAt ?? new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    boards.set(id, updated);
    return ok(updated);
  });

  app.delete("/api/v1/boards/:id", async (request) => {
    const { id } = request.params as { id: string };
    boards.delete(id);
    return ok({ deleted: true });
  });
}
