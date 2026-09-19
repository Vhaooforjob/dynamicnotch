import type { FastifyReply } from "fastify";

export type ApiErrorCode =
  | "VALIDATION_ERROR"
  | "NOT_FOUND"
  | "UNAUTHORIZED"
  | "DATABASE_UNAVAILABLE"
  | "INTERNAL_ERROR";

export class ApiError extends Error {
  constructor(
    public readonly code: ApiErrorCode,
    message: string,
    public readonly statusCode = 400,
    public readonly details: Record<string, unknown> = {}
  ) {
    super(message);
  }
}

export function sendError(reply: FastifyReply, error: ApiError) {
  return reply.status(error.statusCode).send({
    error: {
      code: error.code,
      message: error.message,
      details: error.details
    }
  });
}
