import {
  GoogleGenerativeAI,
  SchemaType,
  type Schema,
} from "@google/generative-ai";
import * as fs from "fs";

// ⚠️ Asegúrate de tener tu API KEY en el archivo .env o pegada aquí para probar
const genAI = new GoogleGenerativeAI(
  process.env.GEMINI_API_KEY || "TU_API_KEY_AQUI",
);

const responseSchema: Schema = {
  description: "Lista de transacciones clasificadas",
  type: SchemaType.ARRAY,
  items: {
    type: SchemaType.OBJECT,
    properties: {
      originalDate: { type: SchemaType.STRING },
      originalDescription: { type: SchemaType.STRING },
      amount: { type: SchemaType.NUMBER },
      categoryId: { type: SchemaType.STRING },
      categoryName: { type: SchemaType.STRING },
      type: {
        type: SchemaType.STRING,
        enum: ["income", "expense"],
        format: "enum" as const,
      },
      reasoning: { type: SchemaType.STRING },
    },
    required: [
      "originalDate",
      "originalDescription",
      "amount",
      "categoryId",
      "categoryName",
      "type",
    ],
  },
};

export async function categorizeCsvWithGemini(
  csvContent: string,
  categoriesContent: string,
) {
  try {
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: responseSchema,
      },
    });

    const prompt = `
    Actúa como un experto analista financiero (Fintech AI Agent).
    
    TU OBJETIVO:
    Analizar un archivo CSV de transacciones bancarias y clasificar CADA fila utilizando EXCLUSIVAMENTE la lista de categorías proporcionada.

    ARCHIVOS ADJUNTOS:
    1. Lista de Categorías (JSON): Utiliza los campos 'categoryId', 'name' y 'kind' (income/expense) para la clasificación.
    2. Transacciones (CSV): Contiene fechas, descripciones y montos.

    REGLAS DE NEGOCIO:
    - Analiza el signo del monto: Negativo es 'expense' (Gasto), Positivo es 'income' (Ingreso).
    - Mapea descripciones sucias (ej: "PG * UBER") a categorías lógicas (ej: "Transporte").
    - Si detectas patrones recurrentes (ej: mismo monto y descripción cada mes), asegúrate de clasificarlos igual.
    - Si una transacción es ambigua, usa tu mejor criterio basado en el contexto brasileño (ej: "Sonda" es Supermercado).
    - Si absolutamente no puedes clasificarla, usa la categoría "Outros" (si existe) o déjala como null, pero intenta evitarlo.

    DATOS DE ENTRADA:
    --- COMIENZO CATEGORÍAS ---
    ${categoriesContent}
    --- FIN CATEGORÍAS ---

    --- COMIENZO CSV ---
    ${csvContent}
    --- FIN CSV ---
  `;

    console.log("🚀 Enviando datos a Gemini 1.5 Flash...");

    const result = await model.generateContent(prompt);
    const response = result.response;

    // Verificamos si la respuesta es válida
    if (!response.candidates || response.candidates.length === 0) {
      console.error("⚠️ La IA no devolvió candidatos. Revisa tu cuota.");
      return [];
    }

    const text = response.text();
    const transactions = JSON.parse(text);

    console.log(
      `✅ Clasificadas ${transactions.length} transacciones con éxito.`,
    );
    return transactions;
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
    return [];
  }
}
