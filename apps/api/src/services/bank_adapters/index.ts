import { BankType } from "../../models/bank_type"
import { BankAdapter } from "./bank_adapter.interface"
import { BradescoAdapter } from "./bradesco_adapter"
import { CaixaAdapter } from "./caixa_adapter"
import { ItauAdapter } from "./itau_adapter"
import { NubankAdapter } from "./nubank_adapter"

export function getBankAdapter(bankType: BankType): BankAdapter {
  switch (bankType) {
    case BankType.Nubank:
      return new NubankAdapter()
    case BankType.Itau:
      return new ItauAdapter()
    case BankType.Caixa:
      return new CaixaAdapter()
    case BankType.Bradesco:
      return new BradescoAdapter()
    default:
      throw new Error(`Banco não suportado: ${bankType}`)
  }
}
