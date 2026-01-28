import crypto from "node:crypto"

const countries = [
  { name: "Brasil", code: "BR" },
  { name: "Argentina", code: "AR" },
  { name: "Venezuela", code: "VE" },
  { name: "Colombia", code: "CO" },
]

/**
 * @param db {import('mongodb').Db}
 * @param client {import('mongodb').MongoClient}
 * @returns {Promise<void>}
 */
export const up = async (db, client) => {
  // TODO write your migration here.
  // See https://github.com/seppevs/migrate-mongo/#creating-a-new-migration-script
  // Example:
  // await db.collection('albums').updateOne({artist: 'The Beatles'}, {$set: {blacklisted: true}});

  const col = db.collection("countries")

  console.log("Clearing existing countries...")
  await col.deleteMany({})

  console.log("Inserting countries...")
  const docs = countries.map((c) => ({
    countryId: crypto.randomBytes(12).toString("hex"),
    ...c,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  }))

  await col.insertMany(docs)
  console.log(`Inserted ${docs.length} countries.`)

  await col.createIndex({ code: 1 }, { unique: true })
  await col.createIndex({ isActive: 1 })
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
