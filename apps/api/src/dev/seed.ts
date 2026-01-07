import { Category } from "../models/category";
import { Account, AccountType } from "../models/account";
import type { CategoryMongoRepository } from "../repositories/category_repository";
import type { AccountMongoRepository } from "../repositories/account_repository";
import {
  Criteria,
  Filters,
  Operator,
  Order,
} from "@abejarano/ts-mongodb-criteria";

export async function seedDevData(
  userId: string,
  categoryRepo: CategoryMongoRepository,
  accountRepo: AccountMongoRepository
) {
  await seedCategoriesIfEmpty(userId, categoryRepo);
  await seedAccountsIfEmpty(userId, accountRepo);
}

async function seedCategoriesIfEmpty(
  userId: string,
  categoryRepo: CategoryMongoRepository
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
      1
    )
  );

  if (list.count > 0) {
    return;
  }

  await categoryRepo.upsert(
    Category.create({
      userId,
      name: "Salario",
      kind: "income",
      isActive: true,
      color: "#10B981",
      icon: "salary",
    })
  );
  await categoryRepo.upsert(
    Category.create({
      userId,
      name: "Freelance",
      kind: "income",
      isActive: true,
      color: "#22C55E",
      icon: "briefcase",
    })
  );
  await categoryRepo.upsert(
    Category.create({
      userId,
      name: "Alimentacion",
      kind: "expense",
      isActive: true,
      color: "#F97316",
      icon: "food",
    })
  );
  await categoryRepo.upsert(
    Category.create({
      userId,
      name: "Transporte",
      kind: "expense",
      isActive: true,
      color: "#0EA5E9",
      icon: "transport",
    })
  );
}

async function seedAccountsIfEmpty(
  userId: string,
  accountRepo: AccountMongoRepository
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
      1
    )
  );

  if (list.count > 0) {
    return;
  }

  await accountRepo.upsert(
    Account.create({
      userId,
      name: "Nubank",
      type: AccountType.Bank,
      currency: "BRL",
      isActive: true,
    })
  );
  await accountRepo.upsert(
    Account.create({
      userId,
      name: "Wallet",
      type: AccountType.Cash,
      currency: "BRL",
      isActive: true,
    })
  );
}
