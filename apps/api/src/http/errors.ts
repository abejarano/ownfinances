export function badRequest(set: { status: number }, message: string) {
  set.status = 400;
  return { error: message };
}

export function notFound(set: { status: number }, message: string) {
  set.status = 404;
  return { error: message };
}

export function unauthorized(set: { status: number }, message: string) {
  set.status = 401;
  return { error: message };
}
