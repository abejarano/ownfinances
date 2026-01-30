const { MONGO_URI, MONGO_USER, MONGO_PASS, MONGO_SERVER, MONGO_DB } =
  process.env

const buildMongoUri = () => {
  if (MONGO_URI) return MONGO_URI

  if (!MONGO_USER || !MONGO_PASS || !MONGO_SERVER || !MONGO_DB) {
    throw new Error(
      "Missing MongoDB env vars. Provide MONGO_URI or MONGO_USER/MONGO_PASS/MONGO_SERVER/MONGO_DB."
    )
  }

  return `mongodb+srv://${MONGO_USER}:${MONGO_PASS}@${MONGO_SERVER}/${MONGO_DB}?retryWrites=true&w=majority`
}

if (!MONGO_DB) {
  throw new Error("Missing MONGO_DB environment variable.")
}

// In this file you can configure migrate-mongo

const config = {
  mongodb: {
    url: buildMongoUri(),
    databaseName: MONGO_DB,
    options: {
      ignoreUndefined: true,
    },
  },

  // The migrations dir, can be an relative or absolute path. Only edit this when really necessary.
  migrationsDir: "migrations",

  // The mongodb collection where the applied changes are stored. Only edit this when really necessary.
  changelogCollectionName: "changelog",

  // The mongodb collection where the lock will be created.
  lockCollectionName: "changelog_lock",

  // The value in seconds for the TTL index that will be used for the lock. Value of 0 will disable the feature.
  lockTtl: 0,

  // The file extension to create migrations and search for in migration dir
  migrationFileExtension: ".js",

  // Enable the algorithm to create a checksum of the file contents and use that in the comparison to determine
  // if the file should be run.  Requires that scripts are coded to be run multiple times.
  useFileHash: false,

  // Don't change this, unless you know what you're doing
  moduleSystem: "esm",
}

module.exports = config
