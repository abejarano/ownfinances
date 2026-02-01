import { GoogleGenerativeAI, type Schema } from "@google/generative-ai";
import { env } from "../config";

export class DesquadraAI {
  private static _instance: DesquadraAI | null = null;
  private genAI: GoogleGenerativeAI;

  constructor() {
    this.genAI = new GoogleGenerativeAI(env.GEMINI_API_KEY);
  }

  static getInstance() {
    if (!this._instance) {
      this._instance = new DesquadraAI();
    }
    return this._instance;
  }

  async exec(prompt: string, responde: Schema) {
    try {
      const model = this.genAI.getGenerativeModel({
        model: "gemini-2.5-flash",
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: responde,
        },
      });

      console.log("🚀 Enviando datos a Gemini...");

      const result = await model.generateContent(prompt);
      const response = result.response;

      if (!response.candidates || response.candidates.length === 0) {
        console.error("⚠️ La IA no devolvió candidatos. Revisa tu cuota.");
      }

      return JSON.parse(response.text());
    } catch (error: any) {
      // Mejor manejo de errores para entender qué pasa
      console.error("\n❌ ERROR CONECTANDO CON GEMINI:");
      if (error.message) console.error("Mensaje:", error.message);
      if (error.status) console.error("Status Code:", error.status);
      if (error.status === 429 || error.status === 427) {
        console.error(
          "💡 PISTA: Has excedido tu cuota gratuita (Rate Limit). Espera un minuto o usa 'gemini-1.5-flash'.",
        );
      }

      throw error;
    }
  }
}
