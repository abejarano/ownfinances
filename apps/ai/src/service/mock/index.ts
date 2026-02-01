import type { TransactionAI } from "@desquadra/queue";

export const MockResponseClassifyTransaciton = (): TransactionAI[] => {
  return [
    {
      originalDate: "02/01/2026",
      originalDescription: "Compra no débito - PQ ANHANGUERA",
      amount: -10,
      categoryId: "3535237adda3f7c41233cb6a",
      categoryName: "Lazer / Ocio",
      type: "expense",
      reasoning:
        "Purchase at 'PQ ANHANGUERA' (park) classified as Lazer / Ocio.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência Recebida - ALEPH SOLUTIONS INFORMATICA LTDA - 34.615.691/0001-50 - BCO BRADESCO S.A. (0237) Agência: 3114 Conta: 33095-7",
      amount: 17000,
      categoryId: "e6e08a3df82e37a47fc11e19",
      categoryName: "Freelancer",
      type: "income",
      reasoning: "Income from 'ALEPH SOLUTIONS' classified as Freelancer.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 68021106-5",
      amount: -1700,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angel based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - MERCADO PAGO INSTITUICAO DE PAGAMENTO LTDA - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 1488917887-3",
      amount: -624.47,
      categoryId: "c8ea284bd4983000a29e0f70",
      categoryName: "Prestamos",
      type: "expense",
      reasoning:
        "Payment to 'Mercado Pago Instituicao de Pagamento Ltda' classified as Prestamos (likely payment for services/loan via the platform).",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ITAU UNIBANCO HOLDING S.A. - 60.872.504/0001-23 - ITAÚ UNIBANCO S.A. (0341) Agência: 2525 Conta: 4841-5",
      amount: -3341.41,
      categoryId: "c8ea284bd4983000a29e0f70",
      categoryName: "Prestamos",
      type: "expense",
      reasoning:
        "Payment to financial institution ('Neon Pagamentos', 'Itau Unibanco'), classified as Prestamos (loan/credit card payment).",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Yoliver Concepcion Jimenez de Bejarano - •••.608.082-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 62286039-2",
      amount: -1500,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from yoliver based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - BANCO BTG PACTUAL S.A. (0208) Agência: 20 Conta: 843183-8",
      amount: -800,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angel based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 68021106-5",
      amount: -250,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angel based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - ITAÚ UNIBANCO S.A. (0341) Agência: 1268 Conta: 45244-6",
      amount: -400,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angel based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - GOOGLE CLOUD BRASIL COMPUTACAO E SERVICOS DE DADOS LTDA. - 25.012.398/0001-07 - EBANX IP LTDA. (0383) Agência: 1 Conta: 1001701159-8",
      amount: -94.47,
      categoryId: "f1c342a6b11074daee693d82",
      categoryName: "Servicios digitales / Suscripciones",
      type: "expense",
      reasoning: "Description contains 'Google Cloud'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angel Vicente Bejarano Afanador - •••.608.222-•• - WISE BRASIL IP LTDA. Agência: 1 Conta: 550167-2",
      amount: -100,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angel based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - TELEFONICA BRAS - 02.558.157/0001-62 - BCO SANTANDER (BRASIL) S.A. (0033) Agência: 2271 Conta: 13068744-7",
      amount: -130.53,
      categoryId: "8dcaa534569ae998813b8668",
      categoryName: "Comunicación",
      type: "expense",
      reasoning: "Description contains 'Telefonica', 'Claro' or 'Telecom'.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Balca Assessoria, Consultoria e Corretagem de Seguros Ltda - 10.726.276/0001-05 - BCO C6 S.A. (0336) Agência: 1 Conta: 18201619-6",
      amount: -556.35,
      categoryId: "31cbd39ecd3ca685097d8f53",
      categoryName: "Servicios del hogar",
      type: "expense",
      reasoning:
        "Description contains 'Balca Assessoria', likely for household services.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Angibel Nahomi Bejarano Jimenez - •••.608.122-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 42781631-8",
      amount: -300,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angibel based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - Yalef Andre de Araujo Souza - •••.981.134-•• - CELCOIN IP S.A. (0509) Agência: 1 Conta: 44082102-3",
      amount: 4324.2,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Classified as Transferencia based on 'transferência' keyword.",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ITAU UNIBANCO HOLDING S.A. - 60.872.504/0001-23 - ITAÚ UNIBANCO S.A. (0341) Agência: 2525 Conta: 4841-5",
      amount: -4325.46,
      categoryId: "c8ea284bd4983000a29e0f70",
      categoryName: "Prestamos",
      type: "expense",
      reasoning:
        "Payment to financial institution ('Neon Pagamentos', 'Itau Unibanco'), classified as Prestamos (loan/credit card payment).",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência Recebida - Angibel Nahomi Bejarano Jimenez - •••.608.122-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 42781631-8",
      amount: 150,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angibel based on rule. (Original type from amount: income. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Kaique Pereira de Sousa - •••.230.478-•• - BCO BRADESCO S.A. (0237) Agência: 3737 Conta: 372503-0",
      amount: -370,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from kaique based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "05/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -606.88,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "06/01/2026",
      originalDescription:
        "Pagamento de boleto efetuado - GLOBAL CONECTA TELECOM LTDA",
      amount: -79.9,
      categoryId: "8dcaa534569ae998813b8668",
      categoryName: "Comunicación",
      type: "expense",
      reasoning: "Description contains 'Telefonica', 'Claro' or 'Telecom'.",
    },
    {
      originalDate: "07/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - PIX Marketplace - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2918333524-0",
      amount: -196.23,
      categoryId: "3535237adda3f7c41233cb6a",
      categoryName: "Lazer / Ocio",
      type: "expense",
      reasoning:
        "Payment via 'PIX Marketplace' classified as Lazer / Ocio (general online shopping).",
    },
    {
      originalDate: "07/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - MARY CLASS GESTAO CONDOMINIAL - 18.051.456/0001-46 - BCO BRADESCO S.A. (0237) Agência: 2217 Conta: 62242-7",
      amount: -2650,
      categoryId: "84ccb705bb253990272d9cb9",
      categoryName: "Vivienda",
      type: "expense",
      reasoning: "Condominium fee classified as Vivienda.",
    },
    {
      originalDate: "08/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -576.05,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "09/01/2026",
      originalDescription: "Compra no débito - CAJAMAR_CONSIGAZ",
      amount: -30,
      categoryId: "31cbd39ecd3ca685097d8f53",
      categoryName: "Servicios del hogar",
      type: "expense",
      reasoning: "Gas purchase classified as Servicios del hogar.",
    },
    {
      originalDate: "09/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - SABESP - 43.776.517/0001-80 - ITAÚ UNIBANCO S.A. (0341) Agência: 57 Conta: 81298-4",
      amount: -185.49,
      categoryId: "31cbd39ecd3ca685097d8f53",
      categoryName: "Servicios del hogar",
      type: "expense",
      reasoning:
        "Description contains 'SABESP' or 'ENEL', classified as utility services.",
    },
    {
      originalDate: "10/01/2026",
      originalDescription: "Compra no débito - BRASIL COM S",
      amount: -253,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "10/01/2026",
      originalDescription: "Compra no débito - RESTAURANTE RINCONCI",
      amount: -29.7,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Description contains 'Restaurante', classified as Alimentación.",
    },
    {
      originalDate: "11/01/2026",
      originalDescription: "Compra no débito - BARBEARIA DOM HELIO",
      amount: -180,
      categoryId: "113ecf6cfbfaea8e7236edbd",
      categoryName: "Cuidado personal",
      type: "expense",
      reasoning:
        "Description contains 'Barbearia', classified as Cuidado personal.",
    },
    {
      originalDate: "11/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Claro - 40.432.544/0001-47 - CLARO PAY S.A. IP Agência: 1 Conta: 1872704-2",
      amount: -56.11,
      categoryId: "8dcaa534569ae998813b8668",
      categoryName: "Comunicación",
      type: "expense",
      reasoning: "Description contains 'Telefonica', 'Claro' or 'Telecom'.",
    },
    {
      originalDate: "11/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -295.38,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "13/01/2026",
      originalDescription: "Compra no débito - CAJAMAR_CONSIGAZ",
      amount: -20,
      categoryId: "31cbd39ecd3ca685097d8f53",
      categoryName: "Servicios del hogar",
      type: "expense",
      reasoning: "Gas purchase classified as Servicios del hogar.",
    },
    {
      originalDate: "13/01/2026",
      originalDescription: "Compra no débito - CLAUDIA DE PAULA COST",
      amount: -8,
      categoryId: "3535237adda3f7c41233cb6a",
      categoryName: "Lazer / Ocio",
      type: "expense",
      reasoning:
        "Ambiguous purchase ('Claudia de Paula Cost'), defaulting to Lazer / Ocio.",
    },
    {
      originalDate: "13/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -717.15,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "14/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ENEL DISTRIBUICAO SAO PAULO - 61.695.227/0001-93 - ITAÚ UNIBANCO S.A. (0341) Agência: 911 Conta: 4486-5",
      amount: -276.25,
      categoryId: "31cbd39ecd3ca685097d8f53",
      categoryName: "Servicios del hogar",
      type: "expense",
      reasoning:
        "Description contains 'SABESP' or 'ENEL', classified as utility services.",
    },
    {
      originalDate: "14/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ENEL DISTRIBUICAO SAO PAULO - 61.695.227/0001-93 - ITAÚ UNIBANCO S.A. (0341) Agência: 911 Conta: 4486-5",
      amount: -315.04,
      categoryId: "31cbd39ecd3ca685097d8f53",
      categoryName: "Servicios del hogar",
      type: "expense",
      reasoning:
        "Description contains 'SABESP' or 'ENEL', classified as utility services.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - PIX Marketplace - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2918333524-0",
      amount: -48.96,
      categoryId: "3535237adda3f7c41233cb6a",
      categoryName: "Lazer / Ocio",
      type: "expense",
      reasoning:
        "Payment via 'PIX Marketplace' classified as Lazer / Ocio (general online shopping).",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Pagamento de boleto efetuado - NEON PAGAMENTOS SA INSTITUICAO DE P     AGAMENTO",
      amount: -122.16,
      categoryId: "c8ea284bd4983000a29e0f70",
      categoryName: "Prestamos",
      type: "expense",
      reasoning:
        "Payment to financial institution ('Neon Pagamentos', 'Itau Unibanco'), classified as Prestamos (loan/credit card payment).",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - BRUNO TAVARES DOS SANTOS INTERMEDIACOES LTDA - 59.468.424/0001-28 - CORPX BANK IP S.A. Agência: 1 Conta: 20000022-4",
      amount: 2500,
      categoryId: "6877c8bcebbf1af51cfba940",
      categoryName: "Ventas",
      type: "income",
      reasoning:
        "Income from 'intermediação' or 'negociações' classified as Ventas.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - MERCADO PAGO INSTITUICAO DE PAGAMENTO LTDA - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 1488917887-3",
      amount: -711.18,
      categoryId: "c8ea284bd4983000a29e0f70",
      categoryName: "Prestamos",
      type: "expense",
      reasoning:
        "Payment to 'Mercado Pago Instituicao de Pagamento Ltda' classified as Prestamos (likely payment for services/loan via the platform).",
    },
    {
      originalDate: "15/01/2026",
      originalDescription: "Pagamento de boleto efetuado - ESCOLA VILARTE",
      amount: -1661,
      categoryId: "72f9cb9aa36f23b20b0d7706",
      categoryName: "Educación",
      type: "expense",
      reasoning: "Description contains 'Escola', classified as Educación.",
    },
    {
      originalDate: "15/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - ITAU UNIBANCO HOLDING S.A. - 60.872.504/0001-23 - ITAÚ UNIBANCO S.A. (0341) Agência: 2525 Conta: 4841-5",
      amount: -161.4,
      categoryId: "c8ea284bd4983000a29e0f70",
      categoryName: "Prestamos",
      type: "expense",
      reasoning:
        "Payment to financial institution ('Neon Pagamentos', 'Itau Unibanco'), classified as Prestamos (loan/credit card payment).",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - ORION",
      amount: -13.5,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at 'ORION', assumed Alimentación for small purchase.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - ORION",
      amount: -100,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at 'ORION', assumed Alimentación for small purchase.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - GENESIS NEGOCIAÇÕES - 52.950.601/0001-69 - GOWD IP LTDA. Agência: 1 Conta: 9237244457571010100-1",
      amount: 1500,
      categoryId: "6877c8bcebbf1af51cfba940",
      categoryName: "Ventas",
      type: "income",
      reasoning:
        "Income from 'intermediação' or 'negociações' classified as Ventas.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - AUTO BAN JUNDIAI",
      amount: -13.7,
      categoryId: "00677e6835b1acb6443a5ecd",
      categoryName: "Transporte",
      type: "expense",
      reasoning:
        "Auto related purchase at 'Auto Ban Jundiai' classified as Transporte.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - KI FRIO",
      amount: -396,
      categoryId: "dd6563fbee00a682296627a5",
      categoryName: "Herramientas/ Equipamento",
      type: "expense",
      reasoning:
        "Purchase at 'KI FRIO' (appliances/equipment) classified as Herramientas/ Equipamento.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - JIM.COM* PB VIDRACARIA",
      amount: -400,
      categoryId: "94f5f4b3827dc0ace487b0fe",
      categoryName: "Mantenimiento del Hogar",
      type: "expense",
      reasoning:
        "Purchase at 'Vidracaria' (glassware/windows) classified as Mantenimiento del Hogar.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -164.78,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "16/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - PIX Marketplace - 10.573.521/0001-91 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2918333524-0",
      amount: -252.49,
      categoryId: "3535237adda3f7c41233cb6a",
      categoryName: "Lazer / Ocio",
      type: "expense",
      reasoning:
        "Payment via 'PIX Marketplace' classified as Lazer / Ocio (general online shopping).",
    },
    {
      originalDate: "17/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - JONAS TESTONI INTERMEDIACAO DIGITAL LTDA - 51.615.914/0001-06 - CORPX BANK IP S.A. Agência: 1 Conta: 20000063-1",
      amount: 2000,
      categoryId: "6877c8bcebbf1af51cfba940",
      categoryName: "Ventas",
      type: "income",
      reasoning:
        "Income from 'intermediação' or 'negociações' classified as Ventas.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - CENTER CASTILHO MATERI",
      amount: -222.9,
      categoryId: "94f5f4b3827dc0ace487b0fe",
      categoryName: "Mantenimiento del Hogar",
      type: "expense",
      reasoning:
        "Purchase at 'Center Castilho Materiais' classified as Mantenimiento del Hogar.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - Comand",
      amount: -341.99,
      categoryId: "3535237adda3f7c41233cb6a",
      categoryName: "Lazer / Ocio",
      type: "expense",
      reasoning: "Ambiguous purchase ('Comand'), defaulting to Lazer / Ocio.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -47.48,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -19.74,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - LojaoZeusmack",
      amount: -86.96,
      categoryId: "bd6a1fe75056f5c53967c5c5",
      categoryName: "Hobbies / Equipamiento personal",
      type: "expense",
      reasoning:
        "Purchase at 'LojaoZeusmack' (general store) classified as Hobbies / Equipamiento personal.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -48.39,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - Rosilys Helayne Rodríguez Calzadilla - •••.548.132-•• - NU PAGAMENTOS - IP (0260) Agência: 1 Conta: 179210318-2",
      amount: -200,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from rosily based on rule. (Original type from amount: expense. Final type: transfer)",
    },
    {
      originalDate: "17/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - IFOOD.COM AGENCIA DE RESTAURANTES ONLINE S.A. - 14.380.200/0001-21 - ADYEN DO BRASIL IP LTDA. Agência: 1 Conta: 100000003-3",
      amount: -70.99,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning: "Description contains 'IFOOD', classified as Alimentación.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -519.06,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "17/01/2026",
      originalDescription: "Compra no débito - BIFARMA",
      amount: -21.99,
      categoryId: "7c19174b806270548110637a",
      categoryName: "Salud",
      type: "expense",
      reasoning: "Purchase at 'BIFARMA' (pharmacy) classified as Salud.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - CENTER CASTILHO MATERI",
      amount: -10.9,
      categoryId: "94f5f4b3827dc0ace487b0fe",
      categoryName: "Mantenimiento del Hogar",
      type: "expense",
      reasoning:
        "Purchase at 'Center Castilho Materiais' classified as Mantenimiento del Hogar.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - MINI EXTRA 4972@@@@@@@",
      amount: -13.75,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - CAJAMAR_CONSIGAZ",
      amount: -20,
      categoryId: "31cbd39ecd3ca685097d8f53",
      categoryName: "Servicios del hogar",
      type: "expense",
      reasoning: "Gas purchase classified as Servicios del hogar.",
    },
    {
      originalDate: "18/01/2026",
      originalDescription: "Compra no débito - MERCADO XINQI",
      amount: -16.99,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "19/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - Anibal Manuel Maita Requena - •••.928.352-•• - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2552875574-1",
      amount: 1200,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from anibal based on rule. (Original type from amount: income. Final type: transfer)",
    },
    {
      originalDate: "19/01/2026",
      originalDescription:
        "Transferência enviada pelo Pix - RECEITA FEDERAL - 00.394.460/0058-87 - ITAÚ UNIBANCO S.A. (0341) Agência: 332 Conta: 81010-0",
      amount: -1166.28,
      categoryId: "9731c0fb150ba6b2753856d0",
      categoryName: "Obligaciones profesionales",
      type: "expense",
      reasoning:
        "Payment to 'Receita Federal' classified as Obligaciones profesionales.",
    },
    {
      originalDate: "19/01/2026",
      originalDescription: "Compra no débito - ORION",
      amount: -200,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at 'ORION', assumed Alimentación for small purchase.",
    },
    {
      originalDate: "22/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - ANGEL VICENTE B AFANADOR - •••.608.222-•• - ITAÚ UNIBANCO S.A. (0341) Agência: 1268 Conta: 45244-6",
      amount: 200,
      categoryId: "transfer",
      categoryName: "Transferencia",
      type: "transfer",
      reasoning:
        "Identified as a personal transfer to/from angel based on rule. (Original type from amount: income. Final type: transfer)",
    },
    {
      originalDate: "22/01/2026",
      originalDescription: "Compra no débito - SONDA CAJAMAR I",
      amount: -775.59,
      categoryId: "17d425b24541d64ac8220e84",
      categoryName: "Alimentación",
      type: "expense",
      reasoning:
        "Purchase at supermarket/grocery ('Sonda', 'Mercado Xinqi', 'Mini Extra', 'Brasil Com S') classified as Alimentación.",
    },
    {
      originalDate: "22/01/2026",
      originalDescription:
        "Transferência recebida pelo Pix - DIGITAL INTERMEDIATION LTDA - 61.261.227/0001-85 - MERCADO PAGO IP LTDA. (0323) Agência: 1 Conta: 2810053479-1",
      amount: 1000,
      categoryId: "6877c8bcebbf1af51cfba940",
      categoryName: "Ventas",
      type: "income",
      reasoning:
        "Income from 'intermediação' or 'negociações' classified as Ventas.",
    },
    {
      originalDate: "22/01/2026",
      originalDescription: "Compra no débito - BAZAR E PAPELARIA VINA",
      amount: -445.6,
      categoryId: "bd6a1fe75056f5c53967c5c5",
      categoryName: "Hobbies / Equipamiento personal",
      type: "expense",
      reasoning:
        "Purchase at 'Bazar e Papelaria' classified as Hobbies / Equipamiento personal.",
    },
  ];
};
