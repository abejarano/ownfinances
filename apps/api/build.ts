// build.ts
await Bun.build({
  entrypoints: ["./src/index.ts"],
  outdir: "./dist",
  compile: {
    outfile: "./desquadra",
    bytecode: true,
  },
  minify: true,
  sourcemap: "linked",
  external: ["mock-aws-s3", "aws-sdk", "nock"],
});
