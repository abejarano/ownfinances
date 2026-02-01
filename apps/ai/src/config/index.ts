export const env = {
  NODE_ENV: Bun.env.NODE_ENV ?? "development",

  BULL_USER: Bun.env.BULL_USER ?? "user",
  BULL_PASSWORD: Bun.env.BULL_PASSWORD ?? "password",

  GEMINI_API_KEY: Bun.env.GEMINI_API_KEY ?? "your_gemini_api_key",

  MOCK_TEST_RESPONSE: Bun.env.MOCK_TEST_RESPONSE ?? "true",
};
