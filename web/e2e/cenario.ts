/*
 * O cenário do teste de ponta a ponta: quem entra, em que escola, em que dia.
 *
 * Tudo aqui é o que o seed de desenvolvimento traz, e o seed é inteiramente
 * fictício — escola, município, pessoas e e-mails (regra de sigilo do
 * projeto). Nenhum dado real, nenhuma credencial de verdade passa por este
 * teste.
 */

/** A merendeira do seed. A senha é a de desenvolvimento, e só existe local. */
export const COOK = {
  email: 'merendeira1@dominio.com.br',
  password: 'mae-desenvolvimento',
} as const

/** A escola do seed, e o modelo oficial que ela tem registrado. */
export const SCHOOL_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
export const TEMPLATE_PATH = `${SCHOOL_ID}/modelo-oficial.docx`
export const TEMPLATE_BUCKET = 'document-templates'
export const DOCUMENT_BUCKET = 'generated-documents'

/** Um gênero que o seed já tem no catálogo: escolhê-lo não cria resíduo. */
export const FOOD_ITEM = 'Arroz'

/*
 * O dia que o teste registra: o último dia útil do mês em que ele roda.
 *
 * Não é uma data fixa porque o mês que a aplicação abre é o mês de hoje, e um
 * teste preso a setembro de 2026 passaria a navegar meses atrás de si mesmo em
 * outubro. E é o **último** dia útil porque o seed ocupa os quatro primeiros
 * dias do mês — um deles bloqueado —, e o teste precisa de um dia em branco
 * para registrar do zero.
 */
export function testDate(now = new Date()): string {
  const year = now.getFullYear()
  const month = now.getMonth()
  const day = new Date(year, month + 1, 0)

  while (day.getDay() === 0 || day.getDay() === 6) {
    day.setDate(day.getDate() - 1)
  }

  return format(day)
}

/** O mês do dia do teste, em AAAA-MM: é o que vai na barra de endereço. */
export function testMonth(date = testDate()): string {
  return date.slice(0, 7)
}

const MONTH_NAMES = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
]

/**
 * "30 de setembro" — a data como a merendeira a lê.
 *
 * É a mesma forma que a aplicação usa nas etiquetas de acessibilidade das
 * listas, e é por elas que o teste alcança o dia. Escrita aqui de novo, e não
 * importada de `src/`: um teste que chama a função da aplicação para prever o
 * que a aplicação vai escrever concorda com ela mesma quando as duas estiverem
 * erradas.
 */
export function dayAndMonth(date: string): string {
  const [, month, day] = date.split('-')
  return `${Number(day)} de ${MONTH_NAMES[Number(month) - 1]}`
}

function format(date: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

/** "30/09" — a data como a coluna "Dia" do documento oficial a imprime. */
export function shortDate(date: string): string {
  const [, month, day] = date.split('-')
  return `${day}/${month}`
}
