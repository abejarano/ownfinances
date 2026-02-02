import { DesquadraAI } from "./gemini.service.ts";
import { type Schema, SchemaType } from "@google/generative-ai";
import type { TransactionAI } from "@desquadra/queue";
import { MockResponseClassifyTransactions } from "./mock";
import { env } from "../config";

export default async (params: {
  userName: string;
  userCountry: string;
  csv: string;
  categories: string;
  accounts: string;
}): Promise<TransactionAI[]> => {
  const { userName, csv, categories, userCountry, accounts } = params;

  if (env.MOCK_TEST_RESPONSE === "true") {
    return MockResponseClassifyTransactions();
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
        toAccount: { type: SchemaType.STRING, nullable: true },
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
        "toAccount",
      ],
    },
  };

  try {
    const prompt = `
    Actúa como un experto analista financiero (Fintech AI Agent).
    
    TU OBJETIVO:
    Analizar un archivo CSV de transacciones bancarias y clasificar CADA fila utilizando EXCLUSIVAMENTE la lista de 
    categorías proporcionada.

    ARCHIVOS ADJUNTOS:
    1. Lista de Categorías (JSON): Utiliza los campos 'categoryId', 'name' y 'kind' (income/expense) para la clasificación.
    2. Transacciones (CSV): Contiene fechas, descripciones y montos.

    REGLAS DE NEGOCIO:
    - Analiza el signo del monto: Negativo es 'expense' (Gasto), Positivo es 'income' (Ingreso).
    - Mapea descripciones sucias (ej: "PG * UBER") a categorías lógicas (ej: "Transporte").
    - Debes entender el contexto completo de la descripción para clasificar correctamente la transacción, de modo que no 
    te confundas con cosas por ej: "MERCADO PAGO" es una institución financiera y "MERCADO MERCADAÇO" que es un supermercado.
    - Si detectas patrones recurrentes (ej: mismo monto y descripción cada mes), asegúrate de clasificarlos igual.
    - Si una transacción es ambigua, usa tu mejor criterio basado en el contexto del país ${userCountry} (ej: BR (brasil) "Sonda", "Atacado", "Atacadista" es Supermercado).
    - Si absolutamente no puedes clasificarla, usa la categoría "Outros" (si existe) o déjala como null, pero intenta evitarlo.
    - Para identificar income es importante que evalues que el monto debe ser positivo, y si el nombre nombre de la persona ${userName} no esta en la descripción
    entonces estamos frente a un income, tambien debes evaluar si hay palabras y/o sinómino de income.
    - Si en la descripción de la transacción se encuentra el nombre de la persona ${userName} debe ser clasificado como una transferencia (transfer). 
    Es muy importante que busques en el listado de cuentas cual cuenta concuerda como la cuenta destino, para ello debes identificar el nombre de la institución
    financiera en la transacción especifica y comparar con el campo bankType y/o name del listado de cuentas. Si hay un 90% de concordancia
    necesito que coloques el accountId en el campo toAccount y en el campo categoryId puedes dejarlo vacio.

    DATOS DE ENTRADA:
    --- COMIENZO CATEGORÍAS ---
    ${categories}
    --- FIN CATEGORÍAS ---
    
    --- COMIENZO CUENTAS ---
    ${accounts}
    --- FIN CUENTAS ---
    
    --- COMIENZO CSV ---
    ${csv}
    --- FIN CSV ---
  `;

    return await DesquadraAI.getInstance().exec(prompt, responseSchema);
  } catch (error: any) {
    return [];
  }
};
