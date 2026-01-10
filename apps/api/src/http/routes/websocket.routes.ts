import { addConnection, removeConnection } from "../websocket/websocket_handler";

export function registerWebsocketRoutes(app: any) {
  app.ws("/ws", {
    async open() {
      // La autenticación se hará en el primer mensaje
    },
    async message(ws, message) {
      try {
        const data = typeof message === 'string' ? JSON.parse(message) : message;
        if (data.type === "auth" && data.token) {
          const jwt = (ws as any).data?.jwt;
          if (!jwt) {
            ws.send(JSON.stringify({ type: "error", message: "JWT não disponível" }));
            return;
          }

          const decoded = await jwt.verify(data.token);
          if (!decoded || typeof decoded !== "object" || !("sub" in decoded)) {
            ws.send(JSON.stringify({ type: "error", message: "Token inválido" }));
            return;
          }

          const userId = (decoded as { sub?: string }).sub;
          if (!userId) {
            ws.send(JSON.stringify({ type: "error", message: "Token inválido" }));
            return;
          }

          (ws as any).data = { ...(ws as any).data, userId };
          addConnection(userId, ws as any);
          ws.send(JSON.stringify({ type: "auth", status: "success" }));
        }
      } catch (error) {
        console.error("Erro ao processar mensagem WebSocket:", error);
        ws.send(JSON.stringify({ type: "error", message: "Erro ao processar mensagem" }));
      }
    },
    close(ws) {
      const userId = (ws as any).data?.userId;
      if (userId) {
        removeConnection(userId, ws as any);
      }
    },
  });
}
