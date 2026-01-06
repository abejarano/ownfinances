import { Category } from "../domain/category";
import { Account } from "../domain/account";
import type { CategoryMongoRepository } from "../repositories/category_repository";
import type { AccountMongoRepository } from "../repositories/account_repository";
import { Criteria, Filters, Operator, Order } from "@abejarano/ts-mongodb-criteria";
import { ObjectId } from "mongodb";

export async function seedDevData(
  userId: string,
  categoryRepo: CategoryMongoRepository,
  accountRepo: AccountMongoRepository,
) {
  await seedCategoriesIfEmpty(userId, categoryRepo);
  await seedAccountsIfEmpty(userId, accountRepo);
}

async function seedCategoriesIfEmpty(
  userId: string,
  categoryRepo: CategoryMongoRepository,
) {
  const list = await categoryRepo.list(
    new Criteria(
      Filters.fromValues([
        new Map([
          ["field", "userId"],
          ["operator", Operator.EQUAL],
          ["value", userId],
        ]),
      ]),
      Order.none(),
      1,
      1,
    ),
  );

  if (list.count > 0) {
    return;
  }

  const now = new Date();
  const categorySeedId1 = new ObjectId().toHexString();
  await categoryRepo.upsert(
    new Category({
      id: categorySeedId1,
      categoryId: categorySeedId1,
      userId,
      name: "Salario",
      kind: "income",
      isActive: true,
      color: "#10B981",
      icon: "salary",
      createdAt: now,
      updatedAt: now,
    }),
  );
  const categorySeedId2 = new ObjectId().toHexString();
  await categoryRepo.upsert(
    new Category({
      id: categorySeedId2,
      categoryId: categorySeedId2,
      userId,
      name: "Freelance",
      kind: "income",
      isActive: true,
      color: "#22C55E",
      icon: "briefcase",
      createdAt: now,
      updatedAt: now,
    }),
  );
  const categorySeedId3 = new ObjectId().toHexString();
  await categoryRepo.upsert(
    new Category({
      id: categorySeedId3,
      categoryId: categorySeedId3,
      userId,
      name: "Alimentacion",
      kind: "expense",
      isActive: true,
      color: "#F97316",
      icon: "food",
      createdAt: now,
      updatedAt: now,
    }),
  );
  const categorySeedId4 = new ObjectId().toHexString();
  await categoryRepo.upsert(
    new Category({
      id: categorySeedId4,
      categoryId: categorySeedId4,
      userId,
      name: "Transporte",
      kind: "expense",
      isActive: true,
      color: "#0EA5E9",
      icon: "transport",
      createdAt: now,
      updatedAt: now,
    }),
  );
}

async function seedAccountsIfEmpty(
  userId: string,
  accountRepo: AccountMongoRepository,
) {
  const list = await accountRepo.list(
    new Criteria(
      Filters.fromValues([
        new Map([
          ["field", "userId"],
          ["operator", Operator.EQUAL],
          ["value", userId],
        ]),
      ]),
      Order.none(),
      1,
      1,
    ),
  );

  if (list.count > 0) {
    return;
  }

  const now = new Date();
  const accountSeedId1 = new ObjectId().toHexString();
  await accountRepo.upsert(
    new Account({
      id: accountSeedId1,
      accountId: accountSeedId1,
      userId,
      name: "Nubank",
      type: "bank",
      currency: "BRL",
      isActive: true,
      createdAt: now,
      updatedAt: now,
    }),
  );
  const accountSeedId2 = new ObjectId().toHexString();
  await accountRepo.upsert(
    new Account({
      id: accountSeedId2,
      accountId: accountSeedId2,
      userId,
      name: "Wallet",
      type: "cash",
      currency: "BRL",
      isActive: true,
      createdAt: now,
      updatedAt: now,
    }),
  );
}
