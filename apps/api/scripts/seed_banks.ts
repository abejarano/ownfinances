
import { MongoClient } from "mongodb";
import { createMongoId } from "../src/models/shared/mongo_id";
import { MongoClientFactory } from "@abejarano/ts-mongodb-criteria";


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
];

async function seed() {
  
  const client = await MongoClientFactory.createClient()
  
  try {
    
    const db = client.db(process.env.MONGO_DB);
    const col = db.collection("banks");

    console.log("Clearing existing banks...");
    await col.deleteMany({});

    console.log("Inserting banks...");
    const docs = banks.map(b => ({
        bankId: createMongoId(),
        ...b,
        isActive: true,
        logoUrl: null,
        createdAt: new Date(),
        updatedAt: new Date(),
    }));

    await col.insertMany(docs);
    console.log(`Inserted ${docs.length} banks.`);

    // Indexes
    await col.createIndex({ country: 1 });
    await col.createIndex({ code: 1, country: 1 }, { unique: true });

  } catch (e) {
    console.error(e);
  } finally {
    await client.close();
  }
}

seed();
