import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";

export type RefreshTokenPrimitives = {
  id?: string;
  refreshTokenId: string;
  userId: string;
  tokenHash: string;
  createdAt: Date;
  expiresAt: Date;
  revokedAt?: Date | null;
  userAgent?: string | null;
  ip?: string | null;
};

export class RefreshToken extends AggregateRoot {
  constructor(private readonly props: RefreshTokenPrimitives) {
    super();
  }

  getId(): string {
    return this.props.id ?? this.props.refreshTokenId;
  }

  getRefreshTokenId(): string {
    return this.props.refreshTokenId;
  }

  toPrimitives(): RefreshTokenPrimitives {
    return this.props;
  }

  static fromPrimitives(primitives: RefreshTokenPrimitives): RefreshToken {
    return new RefreshToken(primitives);
  }
}
