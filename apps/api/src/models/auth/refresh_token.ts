import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "../shared/mongo_id"

export type RefreshTokenPrimitives = {
  id?: string
  refreshTokenId: string
  userId: string
  tokenHash: string
  createdAt: Date
  expiresAt: Date
  revokedAt?: Date | null
  userAgent?: string | null
  ip?: string | null
}

export class RefreshToken extends AggregateRoot {
  private constructor(private readonly props: RefreshTokenPrimitives) {
    super()
  }

  static create(props: {
    userId: string
    tokenHash: string
    expiresAt: Date
    revokedAt?: Date | null
    userAgent?: string | null
    ip?: string | null
  }): RefreshToken {
    const now = new Date()

    return new RefreshToken({
      refreshTokenId: createMongoId(),
      userId: props.userId,
      tokenHash: props.tokenHash,
      createdAt: now,
      expiresAt: props.expiresAt,
      revokedAt: props.revokedAt ?? null,
      userAgent: props.userAgent ?? null,
      ip: props.ip ?? null,
    })
  }

  getId(): string {
    return this.props.id ?? this.props.refreshTokenId
  }

  getRefreshTokenId(): string {
    return this.props.refreshTokenId
  }

  toPrimitives(): RefreshTokenPrimitives {
    return this.props
  }

  static override fromPrimitives(
    primitives: RefreshTokenPrimitives
  ): RefreshToken {
    return new RefreshToken(primitives)
  }
}
