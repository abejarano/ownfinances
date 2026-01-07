import { t } from "elysia";
import { TypeCompiler } from "elysia/type-system";

export type AuthRegisterPayload = {
  email: string;
  password: string;
  name?: string;
};

export type AuthLoginPayload = {
  email: string;
  password: string;
};

export type AuthRefreshPayload = {
  refreshToken: string;
};

export type AuthLogoutPayload = {
  refreshToken: string;
};

const RegisterSchema = t.Object(
  {
    email: t.String({ minLength: 1 }),
    password: t.String({ minLength: 1 }),
    name: t.Optional(t.String({ minLength: 1 })),
  },
  { additionalProperties: false },
);

const LoginSchema = t.Object(
  {
    email: t.String({ minLength: 1 }),
    password: t.String({ minLength: 1 }),
  },
  { additionalProperties: false },
);

const RefreshSchema = t.Object(
  {
    refreshToken: t.String({ minLength: 1 }),
  },
  { additionalProperties: false },
);

const LogoutSchema = RefreshSchema;

const registerCompiler = TypeCompiler.Compile(RegisterSchema);
const loginCompiler = TypeCompiler.Compile(LoginSchema);
const refreshCompiler = TypeCompiler.Compile(RefreshSchema);
const logoutCompiler = TypeCompiler.Compile(LogoutSchema);

export function validateAuthRegisterPayload(
  payload: AuthRegisterPayload,
): string | null {
  if (registerCompiler.Check(payload)) return null;
  for (const error of registerCompiler.Errors(payload)) {
    if (error.path === "/email") return "Email requerido";
    if (error.path === "/password") return "Password requerido";
    if (error.path === "/name") return "Nombre invalido";
  }
  return "Payload invalido";
}

export function validateAuthLoginPayload(
  payload: AuthLoginPayload,
): string | null {
  if (loginCompiler.Check(payload)) return null;
  for (const error of loginCompiler.Errors(payload)) {
    if (error.path === "/email") return "Credenciales inválidas";
    if (error.path === "/password") return "Credenciales inválidas";
  }
  return "Payload invalido";
}

export function validateAuthRefreshPayload(
  payload: AuthRefreshPayload,
): string | null {
  if (refreshCompiler.Check(payload)) return null;
  for (const error of refreshCompiler.Errors(payload)) {
    if (error.path === "/refreshToken") return "Sesión expirada, entra de nuevo";
  }
  return "Payload invalido";
}

export function validateAuthLogoutPayload(
  payload: AuthLogoutPayload,
): string | null {
  if (logoutCompiler.Check(payload)) return null;
  for (const error of logoutCompiler.Errors(payload)) {
    if (error.path === "/refreshToken") return "Sesión expirada, entra de nuevo";
  }
  return "Payload invalido";
}
