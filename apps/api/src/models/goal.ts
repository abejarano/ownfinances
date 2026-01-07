import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";
import { createMongoId } from "./shared/mongo_id";

export type GoalPrimitives = {
  id?: string;
  goalId: string;
  userId: string;
  name: string;
  targetAmount: number;
  currency: string;
  startDate: Date;
  targetDate?: Date;
  monthlyContribution?: number;
  linkedAccountId?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt?: Date;
};

export type GoalCreateProps = {
  userId: string;
  name: string;
  targetAmount: number;
  currency?: string;
  startDate: Date;
  targetDate?: Date;
  monthlyContribution?: number;
  linkedAccountId?: string;
  isActive?: boolean;
};

export class Goal extends AggregateRoot {
  private readonly props: GoalPrimitives;

  private constructor(props: GoalPrimitives) {
    super();
    this.props = props;
  }

  static create(props: GoalCreateProps): Goal {
    const now = new Date();
    return new Goal({
      goalId: createMongoId(),
      userId: props.userId,
      name: props.name,
      targetAmount: props.targetAmount,
      currency: props.currency ?? "BRL",
      startDate: props.startDate,
      targetDate: props.targetDate,
      monthlyContribution: props.monthlyContribution,
      linkedAccountId: props.linkedAccountId,
      isActive: props.isActive ?? true,
      createdAt: now,
      updatedAt: now,
    });
  }

  static fromPrimitives(primitives: GoalPrimitives): Goal {
    return new Goal(primitives);
  }

  toPrimitives(): GoalPrimitives {
    return this.props;
  }

  getId(): string {
    return this.props.id ?? this.props.goalId;
  }

  getGoalId(): string {
    return this.props.goalId;
  }
}
