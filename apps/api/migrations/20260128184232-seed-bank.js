/**
 * @param db {import('mongodb').Db}
 * @param client {import('mongodb').MongoClient}
 * @returns {Promise<void>}
 */

import crypto from "node:crypto"

const banks = [
  // BR
  { name: "Nubank", code: "260", country: "BR" },
  { name: "Banco do Brasil", code: "001", country: "BR" },
  { name: "Bradesco", code: "237", country: "BR" },
  { name: "Caixa Econômica", code: "104", country: "BR" },
  { name: "Itaú", code: "341", country: "BR" },
  { name: "Santander", code: "033", country: "BR" },
  { name: "Inter", code: "077", country: "BR" },
  { name: "BTG Pactual", code: "208", country: "BR" },
  { name: "C6 Bank", code: "336", country: "BR" },
  { name: "Neon", code: "655", country: "BR" },
  { name: "Original", code: "212", country: "BR" },
  { name: "Mercado Pago", code: "323", country: "BR" },
  { name: "PicPay", code: "380", country: "BR" },
  { name: "Banco Safra", code: "422", country: "BR" },
  { name: "Banco Pan", code: "623", country: "BR" },
  { name: "PagSeguro", code: "290", country: "BR" },
  { name: "Sicoob", code: "756", country: "BR" },
  { name: "Sicredi", code: "748", country: "BR" },
  { name: "Banco do Nordeste", code: "004", country: "BR" },
  { name: "Banrisul", code: "041", country: "BR" },
  { name: "XP Investimentos", code: "102", country: "BR" },
  { name: "Banco Daycoval", code: "707", country: "BR" },
  // US
  { name: "JPMorgan Chase", code: "US01", country: "US" },
  { name: "Bank of America", code: "US02", country: "US" },
  { name: "Wells Fargo", code: "US03", country: "US" },
  { name: "Citibank", code: "US04", country: "US" },
  { name: "Goldman Sachs", code: "US05", country: "US" },
  // VE
  { name: "Banesco", code: "VE01", country: "VE" },
  { name: "Banco de Venezuela", code: "VE02", country: "VE" },
  { name: "BBVA Provincial", code: "VE03", country: "VE" },
  { name: "Banco Mercantil", code: "VE04", country: "VE" },
  { name: "BNC", code: "VE05", country: "VE" },
  // AR
  { name: "Banco Galicia", code: "AR01", country: "AR" },
  { name: "Banco Santander Rio", code: "AR02", country: "AR" },
  { name: "BBVA Argentina", code: "AR03", country: "AR" },
  { name: "Banco Macro", code: "AR04", country: "AR" },
  { name: "Banco de la Nación", code: "AR05", country: "AR" },
  // CO
  { name: "Bancolombia", code: "CO01", country: "CO" },
  { name: "Banco de Bogotá", code: "CO02", country: "CO" },
  { name: "Davivienda", code: "CO03", country: "CO" },
  { name: "BBVA Colombia", code: "CO04", country: "CO" },
  { name: "Banco de Occidente", code: "CO05", country: "CO" },
]

export const up = async (db, client) => {
  // TODO write your migration here.
  // See https://github.com/seppevs/migrate-mongo/#creating-a-new-migration-script
  // Example:
  // await db.collection('albums').updateOne({artist: 'The Beatles'}, {$set: {blacklisted: true}});

  const col = db.collection("banks")

  console.log("Clearing existing banks...")
  await col.deleteMany({})

  console.log("Inserting banks...")
  const docs = banks.map((b) => ({
    bankId: crypto.randomBytes(12).toString("hex"),
    ...b,
    isActive: true,
    logoUrl: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  }))

  await col.insertMany(docs)
  console.log(`Inserted ${docs.length} banks.`)

  // Indexes
  await col.createIndex({ country: 1 })
  await col.createIndex({ code: 1, country: 1 }, { unique: true })
}

/**
 * @param db {import('mongodb').Db}
 * @param client {import('mongodb').MongoClient}
 * @returns {Promise<void>}
 */
export const down = async (db, client) => {
  // TODO write the statements to rollback your migration (if possible)
  // Example:
  // await db.collection('albums').updateOne({artist: 'The Beatles'}, {$set: {blacklisted: false}});
}
