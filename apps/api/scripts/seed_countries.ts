import { MongoClientFactory } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "../src/models/shared/mongo_id"

const countries = [
  { name: "Brasil", code: "BR" },
  { name: "Argentina", code: "AR" },
  { name: "Venezuela", code: "VE" },
  { name: "Colombia", code: "CO" },
]

async function seed() {
  const client = await MongoClientFactory.createClient()

  try {
    const db = client.db(process.env.MONGO_DB)
    const col = db.collection("countries")

    console.log("Clearing existing countries...")
    await col.deleteMany({})

    console.log("Inserting countries...")
    const docs = countries.map((c) => ({
      countryId: createMongoId(),
      ...c,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    }))

    await col.insertMany(docs)
    console.log(`Inserted ${docs.length} countries.`)

    await col.createIndex({ code: 1 }, { unique: true })
    await col.createIndex({ isActive: 1 })
  } catch (e) {
    console.error(e)
  } finally {
    await client.close()
  }
}

seed()
