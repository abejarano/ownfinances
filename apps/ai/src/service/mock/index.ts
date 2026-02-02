import type { TransactionAI } from "@desquadra/queue";

export const MockResponseClassifyTransactions = (): TransactionAI[] => {
  return [
    {
      originalDate: "02/01/2026",
      originalDescription: "Compra no débito - PQ ANHANGUERA",
      amount: -10,
      categoryId: "dd2cba39136c8cd4fcb7def1",
      categoryName: "Transporte y Combustible",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito em parque, classificado como 'Transporte y Combustible' por implicar custos de deslocamento ou entrada.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência Recebida - ALEPH SOLUTIONS INFORMATICA LTDA - 34.615.691/0001-50 - BCO BRADESCO S.A. (0237) Agência: 3114 Conta: 33095-7",
      amount: 17000,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de empresa. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 68021106-5",
      amount: -1700,
      categoryId: "null",
      categoryName: "null",
      type: "transfer",
      toAccount: "6730294de4f9cb9591d4ed04",
      reasoning:
        "Transação com 'Angel Vicente Bejarano Afanador' identificada como 'transfer'. Conta destino 'NU PAGAMENTOS' corresponde a 'Nubank empresa'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - MERCADO PAGO INSTITUICAO DE PAGAMENTO LTDA - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 1488917887-3",
      amount: -624.47,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência para Mercado Pago, sem descrição clara do serviço ou produto adquirido. Classificada como despesa genérica.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ITAU UNIBANCO HOLDING S.A. - 60.872.504/0001-23 - ITAÚ UNIBANCO S.A. (0341) Agência: 2525 Conta: 4841-5",
      amount: -3341.41,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência para Itaú Unibanco Holding, sem descrição clara do propósito. Classificada como despesa genérica.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Yoliver Concepcion Jimenez de Bejarano - •••.608.082-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 62286039-2",
      amount: -1500,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência enviada para pessoa física que não é Angel Bejarano. Classificada como despesa genérica.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - BANCO BTG PACTUAL S.A. (0208) Agência: 20 Conta: 843183-8",
      amount: -800,
      categoryId: "null",
      categoryName: "null",
      type: "transfer",
      toAccount: "5dcd4734401115ddb89adb5f",
      reasoning:
        "Transação com 'Angel Vicente Bejarano Afanador' identificada como 'transfer'. Conta destino 'BANCO BTG PACTUAL' corresponde a 'BTG cuenta personal'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 68021106-5",
      amount: -250,
      categoryId: "null",
      categoryName: "null",
      type: "transfer",
      toAccount: "6730294de4f9cb9591d4ed04",
      reasoning:
        "Transação com 'Angel Vicente Bejarano Afanador' identificada como 'transfer'. Conta destino 'NU PAGAMENTOS' corresponde a 'Nubank empresa'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - ITAÚ UNIBANCO S.A. (0341) Agência: 1268 Conta: 45244-6",
      amount: -400,
      categoryId: "null",
      categoryName: "null",
      type: "transfer",
      toAccount: "2c731a6f57e07fb7d3e43114",
      reasoning:
        "Transação com 'Angel Vicente Bejarano Afanador' identificada como 'transfer'. Conta destino 'ITAÚ UNIBANCO' corresponde a 'Itau cuenta personal'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - GOOGLE CLOUD BRASIL COMPUTACAO E SERVICOS DE DADOS LTDA. - 25.012.398/0001-07 - EBANX IP LTDA. (0383) Agência: 1 Conta: 1001701159-8",
      amount: -94.47,
      categoryId: "e1b9730fdd42ba3ac267d29f",
      categoryName: "Suscripciones (streaming/apps)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento de serviço de nuvem 'Google Cloud', classificado como 'Suscripciones (streaming/apps)'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - WISE BRASIL IP LTDA. Agência: 1 Conta: 550167-2",
      amount: -100,
      categoryId: "null",
      categoryName: "null",
      type: "transfer",
      toAccount: null,
      reasoning:
        "Transação com 'Angel Vicente Bejarano Afanador' identificada como 'transfer'. A conta destino 'Wise Brasil IP Ltda' não está na lista de contas gerenciadas.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - TELEFONICA BRAS - 02.558.157/0001-62 - BCO SANTANDER (BRASIL) S.A. (0033) Agência: 2271 Conta: 13068744-7",
      amount: -130.53,
      categoryId: "f14ceebaa7aad048e380bc4d",
      categoryName: "Internet y celular",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento a 'TELEFONICA BRAS', classificado como 'Internet y celular'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Balca Assessoria, Consultoria e Corretagem de Seguros Ltda - 10.726.276/0001-05 - BCO C6 S.A. (0336) Agência: 1 Conta: 18201619-6",
      amount: -556.35,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência para empresa de assessoria/corretagem de seguros. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angibel Nahomi Bejarano Jimenez - •••.608.122-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 42781631-8",
      amount: -300,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência enviada para pessoa física que não é Angel Bejarano. Classificada como despesa genérica.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - Yalef Andre de Araujo Souza - •••.981.134-•• - CELCOIN IP S.A. (0509) Agência: 1 Conta: 44082102-3",
      amount: 4324.2,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de pessoa física. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ITAU UNIBANCO HOLDING S.A. - 60.872.504/0001-23 - ITAÚ UNIBANCO S.A. (0341) Agência: 2525 Conta: 4841-5",
      amount: -4325.46,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência para Itaú Unibanco Holding, sem descrição clara do propósito. Classificada como despesa genérica.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência Recebida - Angibel Nahomi Bejarano Jimenez - •••.608.122-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 42781631-8",
      amount: 150,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de pessoa física. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Kaique Pereira de Sousa - •••.230.478-•• - BCO BRADESCO S.A. (0237) Agência: 3737 Conta: 372503-0",
      amount: -370,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência enviada para pessoa física. Classificada como despesa genérica.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -606.88,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'SONDA'.",
    },
    {
      originalDate: "06/01/2026",
      originalDescription:
        "Pagamento de boleto efetuado - GLOBAL CONECTA TELECOM LTDA",
      amount: -79.9,
      categoryId: "f14ceebaa7aad048e380bc4d",
      categoryName: "Internet y celular",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento de serviço de telecomunicação 'GLOBAL CONECTA TELECOM', classificado como 'Internet y celular'.",
    },
    {
      originalDate: "07/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - PIX Marketplace - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2918333524-0",
      amount: -196.23,
      categoryId: "e1b9730fdd42ba3ac267d29f",
      categoryName: "Suscripciones (streaming/apps)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento para 'PIX Marketplace', indicando compra de serviço/conteúdo digital, classificado como 'Suscripciones (streaming/apps)'.",
    },
    {
      originalDate: "07/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - MARY CLASS GESTAO CONDOMINIAL - 18.051.456/0001-46 - BCO BRADESCO S.A. (0237) Agência: 2217 Conta: 62242-7",
      amount: -2650,
      categoryId: "e576ed13f0a9fc3772c1417a",
      categoryName: "Vivienda (alquiler/condominio)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento de gestão condominial, classificado como 'Vivienda (alquiler/condominio)'.",
    },
    {
      originalDate: "08/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -576.05,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'SONDA'.",
    },
    {
      originalDate: "09/01/2026",
      originalDescription: "Compra no débito - CAJAMAR_CONSIGAZ",
      amount: -30,
      categoryId: "bedddb3c240a0109eaf13dba",
      categoryName: "Servicios del hogar (agua, luz, gas)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra relacionada a serviço de gás 'CONSIGAZ', classificado como 'Servicios del hogar (agua, luz, gas)'.",
    },
    {
      originalDate: "09/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - SABESP - 43.776.517/0001-80 - ITAÚ UNIBANCO S.A. (0341) Agência: 57 Conta: 81298-4",
      amount: -185.49,
      categoryId: "bedddb3c240a0109eaf13dba",
      categoryName: "Servicios del hogar (agua, luz, gas)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento a 'SABESP' (empresa de água), classificado como 'Servicios del hogar (agua, luz, gas)'.",
    },
    {
      originalDate: "10/01/2026",
      originalDescription: "Compra no débito - BRASIL COM S",
      amount: -253,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'BRASIL COM S'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "10/01/2026",
      originalDescription: "Compra no débito - RESTAURANTE RINCONCI",
      amount: -29.7,
      categoryId: "cb05282e3ff58048a41b3955",
      categoryName: "Restaurantes",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra em 'RESTAURANTE RINCONCI', classificado como 'Restaurantes'.",
    },
    {
      originalDate: "10/01/2026",
      originalDescription: "Compra no débito - BARBEARIA DOM HELIO",
      amount: -180,
      categoryId: "63e174f49cc9b8c06e26045d",
      categoryName: "Cuidado personal",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra em 'BARBEARIA DOM HELIO', classificado como 'Cuidado personal'.",
    },
    {
      originalDate: "11/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Claro - 40.432.544/0001-47 - CLARO PAY S.A. IP Agência: 1 Conta: 1872704-2",
      amount: -56.11,
      categoryId: "f14ceebaa7aad048e380bc4d",
      categoryName: "Internet y celular",
      type: "expense",
      toAccount: null,
      reasoning: "Pagamento a 'Claro', classificado como 'Internet y celular'.",
    },
    {
      originalDate: "11/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -295.38,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'SONDA'.",
    },
    {
      originalDate: "13/01/2026",
      originalDescription: "Compra no débito - CAJAMAR_CONSIGAZ",
      amount: -20,
      categoryId: "bedddb3c240a0109eaf13dba",
      categoryName: "Servicios del hogar (agua, luz, gas)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra relacionada a serviço de gás 'CONSIGAZ', classificado como 'Servicios del hogar (agua, luz, gas)'.",
    },
    {
      originalDate: "13/01/2026",
      originalDescription: "Compra no débito - CLAUDIA DE PAULA COST",
      amount: -8,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'CLAUDIA DE PAULA COST'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "13/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -717.15,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'SONDA'.",
    },
    {
      originalDate: "14/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ENEL DISTRIBUICAO SAO PAULO - 61.695.227/0001-93 - ITAÚ UNIBANCO S.A. (0341) Agência: 911 Conta: 4486-5",
      amount: -276.25,
      categoryId: "bedddb3c240a0109eaf13dba",
      categoryName: "Servicios del hogar (agua, luz, gas)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento a 'ENEL DISTRIBUICAO SAO PAULO' (empresa de eletricidade), classificado como 'Servicios del hogar (agua, luz, gas)'.",
    },
    {
      originalDate: "14/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ENEL DISTRIBUICAO SAO PAULO - 61.695.227/0001-93 - ITAÚ UNIBANCO S.A. (0341) Agência: 911 Conta: 4486-5",
      amount: -315.04,
      categoryId: "bedddb3c240a0109eaf13dba",
      categoryName: "Servicios del hogar (agua, luz, gas)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento a 'ENEL DISTRIBUICAO SAO PAULO' (empresa de eletricidade), classificado como 'Servicios del hogar (agua, luz, gas)'.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - PIX Marketplace - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2918333524-0",
      amount: -48.96,
      categoryId: "e1b9730fdd42ba3ac267d29f",
      categoryName: "Suscripciones (streaming/apps)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento para 'PIX Marketplace', indicando compra de serviço/conteúdo digital, classificado como 'Suscripciones (streaming/apps)'.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Pagamento de boleto efetuado - NEON PAGAMENTOS SA INSTITUICAO DE P     AGAMENTO",
      amount: -122.16,
      categoryId: "e5820d4a3d64702d17519a7e",
      categoryName: "Préstamos",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento de boleto para instituição de pagamento 'NEON PAGAMENTOS', classificado como 'Préstamos'.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - BRUNO TAVARES DOS SANTOS INTERMEDIACOES LTDA - 59.468.424/0001-28 - CORPX BANK IP S.A. Agência: 1 Conta: 20000022-4",
      amount: 2500,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de empresa de intermediação. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - MERCADO PAGO INSTITUICAO DE PAGAMENTO LTDA - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 1488917887-3",
      amount: -711.18,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência para Mercado Pago, sem descrição clara do serviço ou produto adquirido. Classificada como despesa genérica.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription: "Pagamento de boleto efetuado - ESCOLA VILARTE",
      amount: -1661,
      categoryId: "bfd7f180e1b3b20583ba7ea1",
      categoryName: "Educación (escuela/cursos)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento de boleto para 'ESCOLA VILARTE', classificado como 'Educación (escuela/cursos)'.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ITAU UNIBANCO HOLDING S.A. - 60.872.504/0001-23 - ITAÚ UNIBANCO S.A. (0341) Agência: 2525 Conta: 4841-5",
      amount: -161.4,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência para Itaú Unibanco Holding, sem descrição clara do propósito. Classificada como despesa genérica.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - ORION",
      amount: -13.5,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'ORION'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - ORION",
      amount: -100,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'ORION'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - GENESIS NEGOCIAÇÕES - 52.950.601/0001-69 - GOWD IP LTDA. Agência: 1 Conta: 9237244457571010100-1",
      amount: 1500,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de empresa de negociações. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - AUTO BAN JUNDIAI",
      amount: -13.7,
      categoryId: "dd2cba39136c8cd4fcb7def1",
      categoryName: "Transporte y Combustible",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra relacionada a serviços de autoestrada ('AUTO BAN JUNDIAI'), classificada como 'Transporte y Combustible'.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - KI FRIO",
      amount: -396,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'KI FRIO'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - JIM.COM* PB VIDRACARIA",
      amount: -400,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra em vidraçaria ('VIDRACARIA'). Não há categoria específica para melhorias do lar na lista fornecida.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -164.78,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'SONDA'.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - PIX Marketplace - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2918333524-0",
      amount: -252.49,
      categoryId: "e1b9730fdd42ba3ac267d29f",
      categoryName: "Suscripciones (streaming/apps)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento para 'PIX Marketplace', indicando compra de serviço/conteúdo digital, classificado como 'Suscripciones (streaming/apps)'.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - JONAS TESTONI INTERMEDIACAO DIGITAL LTDA - 51.615.914/0001-06 - CORPX BANK IP S.A. Agência: 1 Conta: 20000063-1",
      amount: 2000,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de empresa de intermediação digital. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - CENTER CASTILHO MATERI",
      amount: -222.9,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito em loja de materiais ('CENTER CASTILHO MATERI'). Não há categoria específica para materiais de construção na lista fornecida.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - Comand",
      amount: -341.99,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'Comand'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -47.48,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em 'MERCADO XINQI', classificado como 'Supermercado'.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -19.74,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em 'MERCADO XINQI', classificado como 'Supermercado'.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - LojaoZeusmack",
      amount: -86.96,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'LojaoZeusmack'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -48.39,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em 'MERCADO XINQI', classificado como 'Supermercado'.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Rosilys Helayne Rodríguez Calzadilla - •••.548.132-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 179210318-2",
      amount: -200,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Transferência enviada para pessoa física que não é Angel Bejarano. Classificada como despesa genérica.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - IFOOD.COM AGENCIA DE RESTAURANTES ONLINE S.A. - 14.380.200/0001-21 - ADYEN DO BRASIL IP LTDA. Agência: 1 Conta: 100000003-3",
      amount: -70.99,
      categoryId: "cb05282e3ff58048a41b3955",
      categoryName: "Restaurantes",
      type: "expense",
      toAccount: null,
      reasoning: "Pagamento a 'IFOOD.COM', classificado como 'Restaurantes'.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -519.06,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'SONDA'.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - BIFARMA",
      amount: -21.99,
      categoryId: "148f3229ba43ad8c22276d08",
      categoryName: "Salud y Farmacia",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra em farmácia 'BIFARMA', classificada como 'Salud y Farmacia'.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - CENTER CASTILHO MATERI",
      amount: -10.9,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito em loja de materiais ('CENTER CASTILHO MATERI'). Não há categoria específica para materiais de construção na lista fornecida.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - MINI EXTRA 4972@@@@@@@",
      amount: -13.75,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'MINI EXTRA'.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - CAJAMAR_CONSIGAZ",
      amount: -20,
      categoryId: "bedddb3c240a0109eaf13dba",
      categoryName: "Servicios del hogar (agua, luz, gas)",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra relacionada a serviço de gás 'CONSIGAZ', classificado como 'Servicios del hogar (agua, luz, gas)'.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -16.99,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em 'MERCADO XINQI', classificado como 'Supermercado'.",
    },
    {
      originalDate: "19/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - Anibal Manuel Maita Requena - •••.928.352-•• - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2552875574-1",
      amount: 1200,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de pessoa física. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "19/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - RECEITA FEDERAL - 00.394.460/0058-87 - ITAÚ UNIBANCO S.A. (0341) Agência: 332 Conta: 81010-0",
      amount: -1166.28,
      categoryId: "2786f717121c1d3e3614ca3e",
      categoryName: "Impuestos",
      type: "expense",
      toAccount: null,
      reasoning:
        "Pagamento a 'RECEITA FEDERAL', classificado como 'Impuestos'.",
    },
    {
      originalDate: "19/01/2026",
      originalDescription: "Compra no débito - ORION",
      amount: -200,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito com descrição ambígua 'ORION'. Não há categoria específica na lista fornecida.",
    },
    {
      originalDate: "22/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - ANGEL VICENTE B AFANADOR - •••.608.222-•• - ITAÚ UNIBANCO S.A. (0341) Agência: 1268 Conta: 45244-6",
      amount: 200,
      categoryId: "null",
      categoryName: "null",
      type: "transfer",
      toAccount: null,
      reasoning:
        "Transação com 'ANGEL VICENTE B AFANADOR' identificada como 'transfer'. Sendo uma transferência recebida, 'toAccount' é nulo.",
    },
    {
      originalDate: "22/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -775.59,
      categoryId: "db8c48443614d82a3c6f48be",
      categoryName: "Supermercado",
      type: "expense",
      toAccount: null,
      reasoning: "Compra em supermercado 'SONDA'.",
    },
    {
      originalDate: "22/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - DIGITAL INTERMEDIATION LTDA - 61.261.227/0001-85 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2810053479-1",
      amount: 1000,
      categoryId: "null",
      categoryName: "null",
      type: "income",
      toAccount: null,
      reasoning:
        "Transferência recebida de empresa de intermediação digital. Classificada como 'income' mas sem categoria específica na lista fornecida.",
    },
    {
      originalDate: "22/01/2026",
      originalDescription: "Compra no débito - BAZAR E PAPELARIA VINA",
      amount: -445.6,
      categoryId: "null",
      categoryName: "null",
      type: "expense",
      toAccount: null,
      reasoning:
        "Compra no débito em 'BAZAR E PAPELARIA VINA'. Não há categoria específica para bazar/papelaria na lista fornecida.",
    },
  ];
};
