import { BunKitServer, CorsModule, SecurityModule } from "bun-platform-kit"
import { controllersModule } from "./bootstrap/controllers"
import { env } from "./shared/env"

const server = new BunKitServer(Number(env.PORT))

server.addModules([
  new CorsModule({
    allowedHeaders: ["content-type", "authorization"],
  }),
  new SecurityModule(),
  controllersModule(),
])

server.start()
