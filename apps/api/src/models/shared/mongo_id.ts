import crypto from "node:crypto";

export function createMongoId(): string {
  return crypto.randomBytes(12).toString("hex");
}
