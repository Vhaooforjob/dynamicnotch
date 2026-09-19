FROM node:24-alpine AS base
WORKDIR /app
COPY package.json pnpm-workspace.yaml ./
COPY apps/api/package.json apps/api/package.json
COPY packages/contracts/package.json packages/contracts/package.json
RUN corepack enable
RUN pnpm install --frozen-lockfile=false
COPY . .
RUN pnpm --filter @notchflow/api build
CMD ["node", "apps/api/dist/server.js"]
