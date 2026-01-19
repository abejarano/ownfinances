import type { ServerRequest } from "bun-platform-kit"

export type AuthenticatedRequest = ServerRequest & { userId?: string }
