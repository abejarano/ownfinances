import type { AppDeps } from "./deps";
import { getMongoClient } from "./mongo";

export async function ensureMongoIndexes(deps: AppDeps) {
  const client = await getMongoClient();
  const db = client.db();

  await deps.userRepo.ensureIndexes(db.collection(deps.userRepo.collectionName()));
  await deps.refreshTokenRepo.ensureIndexes(
    db.collection(deps.refreshTokenRepo.collectionName())
  );
  await deps.recurringRuleRepo.ensureIndexes(
    db.collection(deps.recurringRuleRepo.collectionName())
  );
  await deps.generatedInstanceRepo.ensureIndexes(
    db.collection(deps.generatedInstanceRepo.collectionName())
  );
  await deps.transactionRepo.ensureIndexes(
    db.collection(deps.transactionRepo.collectionName())
  );
}
