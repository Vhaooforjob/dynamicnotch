export function ok<T>(data: T, meta: Record<string, unknown> = {}) {
  return { data, meta };
}
