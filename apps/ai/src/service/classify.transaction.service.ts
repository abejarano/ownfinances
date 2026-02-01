import { DesquadraAI } from "./gemini.service.ts";
import { type Schema, SchemaType } from "@google/generative-ai";
import type { TransactionAI } from "@desquadra/queue";
import { MockResponseClassifyTransaciton } from "./mock";
import { env } from "../config";

export default async (params: {
  userName: string;
  userCountry: string;
  csv: string;
  categories: string;
}): Promise<TransactionAI[]> => {
  const { userName, csv, categories, userCountry } = params;

  if (env.MOCK_TEST_RESPONSE === "true") {
    return MockResponseClassifyTransaciton();
  }

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
          enum: ["income", "expense", "transfer"],
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

  try {
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
    -. Debes entender el contexto completo de la descripción para clasificar correctamente la transacción, de modo que no 
    te confundas con cosas por ej: "MERCADO PAGO" es una institución financiera y "MERCADO MERCADAÇO" que es un supermercado.
    - Si detectas patrones recurrentes (ej: mismo monto y descripción cada mes), asegúrate de clasificarlos igual.
    - Si una transacción es ambigua, usa tu mejor criterio basado en el contexto del país ${userCountry} (ej: BR (brasil) "Sonda", "Atacado", "Atacadista" es Supermercado).
    - Si absolutamente no puedes clasificarla, usa la categoría "Outros" (si existe) o déjala como null, pero intenta evitarlo.
    - Si en la descripción de la transacción se encuentra el nombre de la persona ${userName} debe ser clasificado como una 
    transferencia (transfer) y podrias colocar en el campo categoryId "transfer", ya que no existirá una categoría específica para ella. 

    DATOS DE ENTRADA:
    --- COMIENZO CATEGORÍAS ---
    ${categories}
    --- FIN CATEGORÍAS ---

    --- COMIENZO CSV ---
    ${csv}
    --- FIN CSV ---
  `;

    return await DesquadraAI.getInstance().exec(prompt, responseSchema);
  } catch (error: any) {
    return [];
  }
};
