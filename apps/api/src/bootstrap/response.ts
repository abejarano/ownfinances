import type { ServerResponse } from "bun-platform-kit"

export type Result<T = unknown> = {
  error?: string
  status: number
  value?: T
}

export const HttpResponse = (response: ServerResponse, result: Result) => {
  if (result.error) {
    return response.status(result.status).json({ error: result.error })
  }

  return response.status(result.status).send(result.value)
}
