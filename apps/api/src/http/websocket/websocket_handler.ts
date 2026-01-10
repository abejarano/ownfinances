import type { ServerWebSocket } from "bun";

type WebSocketData = {
  userId: string;
};

const connections = new Map<string, Set<ServerWebSocket<WebSocketData>>>();

export function addConnection(userId: string, ws: ServerWebSocket<WebSocketData>) {
  if (!connections.has(userId)) {
    connections.set(userId, new Set());
  }
  connections.get(userId)!.add(ws);
}

export function removeConnection(userId: string, ws: ServerWebSocket<WebSocketData>) {
  const userConnections = connections.get(userId);
  if (userConnections) {
    userConnections.delete(ws);
    if (userConnections.size === 0) {
      connections.delete(userId);
    }
  }
}

export function notifyImportCompleted(
  userId: string,
  jobId: string,
  status: string,
  result: {
    imported: number;
    duplicates: number;
    errors: number;
  }
) {
  const userConnections = connections.get(userId);
  if (!userConnections) return;

  const message = JSON.stringify({
    type: "import:completed",
    jobId,
    status,
    result,
  });

  for (const ws of userConnections) {
    try {
      ws.send(message);
    } catch (error) {
      console.error("Erro ao enviar notificação WebSocket:", error);
    }
  }
}
