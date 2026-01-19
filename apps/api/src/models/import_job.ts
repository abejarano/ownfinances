import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { BankType } from "./bank_type"
import { createMongoId } from "./shared/mongo_id"

export enum ImportJobStatus {
  Pending = "pending",
  Processing = "processing",
  Completed = "completed",
  Failed = "failed",
}

export type ImportJobPrimitives = {
  id?: string
  importJobId: string
  userId: string
  status: ImportJobStatus
  accountId: string
  bankType: BankType
  totalRows: number
  imported: number
  duplicates: number
  errors: number
  errorDetails: Array<{ row: number; error: string }>
  createdAt: Date
  completedAt?: Date | null
}

export type ImportJobCreateProps = {
  userId: string
  accountId: string
  bankType: BankType
  totalRows: number
}

export class ImportJob extends AggregateRoot {
  private readonly props: ImportJobPrimitives

  private constructor(props: ImportJobPrimitives) {
    super()
    this.props = props
  }

  static create(props: ImportJobCreateProps): ImportJob {
    const now = new Date()

    return new ImportJob({
      importJobId: createMongoId(),
      userId: props.userId,
      status: ImportJobStatus.Pending,
      accountId: props.accountId,
      bankType: props.bankType,
      totalRows: props.totalRows,
      imported: 0,
      duplicates: 0,
      errors: 0,
      errorDetails: [],
      createdAt: now,
      completedAt: null,
    })
  }

  getId(): string {
    return this.props.id ?? this.props.importJobId
  }

  getImportJobId(): string {
    return this.props.importJobId
  }

  toPrimitives(): ImportJobPrimitives {
    return this.props
  }

  static override fromPrimitives(primitives: ImportJobPrimitives): ImportJob {
    return new ImportJob(primitives)
  }
}
