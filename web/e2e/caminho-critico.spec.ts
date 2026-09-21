import { readFileSync } from 'node:fs'

import { expect, test, type Page } from '@playwright/test'

import {
  COOK,
  FOOD_ITEM,
  dayAndMonth,
  shortDate,
  testDate,
  testMonth,
} from './cenario'
import { documentText, readFromDocx } from './docx'

/*
 * O caminho crítico do MAE, de ponta a ponta (issue #72, decisão 11 da E5).
 *
 * É o percurso inteiro da merendeira, no navegador, contra o Supabase local
 * com o seed fictício: entrar, registrar um dia, esperar ele subir, escolher
 * o mapa, gerar o documento e chegar ao arquivo — aberto e conferido.
 *
 * Ele prova uma coisa que nenhum teste de unidade prova: que as peças se
 * encaixam. A fila, a gravação atômica do dia, as políticas de acesso, a Edge
 * Function que preenche o modelo, o balde privado e o link assinado são sete
 * fronteiras, e cada teste de unidade fica de um lado só de uma delas.
 *
 * Cada `test.step` é um passo do caminho, e é assim de propósito: quando ele
 * falhar, o relatório diz **em que passo** o caminho quebrou antes de dizer
 * qual asserção caiu.
 *
 * O que ele NÃO é: teste de uso. Isso é a E7, com merendeira de verdade na
 * frente do produto, e revela problema que nenhuma asserção alcança. As duas
 * coisas não se substituem.
 */

const DATE = testDate()
const MONTH = testMonth(DATE)
/** Como a aplicação escreve a data nas listas: "30 de setembro". */
const DAY_LABEL = dayAndMonth(DATE)
/** Como o documento oficial a imprime, na coluna "Dia": "30/09". */
const DAY_IN_DOCUMENT = shortDate(DATE)

const LUNCH = 'Arroz, feijão, frango assado e salada de alface'
const MORNING = 'Pão com manteiga e leite com achocolatado'
const AFTERNOON = 'Bolo de fubá e suco de laranja'
const MEALS_SERVED = '312'

test('a merendeira registra um dia e chega ao documento oficial', async ({
  page,
}) => {
  await test.step('entra com a conta da merendeira', async () => {
    await page.goto('/entrar')

    await page.getByLabel('E-mail').fill(COOK.email)
    await page.getByLabel('Senha', { exact: true }).fill(COOK.password)
    await page.getByRole('button', { name: 'Entrar' }).click()

    // A visão do mês é a casa dela: chegar aqui é ter sessão e perfil.
    await expect(
      page.getByRole('button', { name: 'Próximo mês' })
    ).toBeVisible()
  })

  await test.step(`abre ${DAY_LABEL}, que está vazio`, async () => {
    // O mês vai no endereço para o teste não depender da hora em que roda.
    await page.goto(`/?mes=${MONTH}`)

    const row = page.locator(`a[href="/dia/${DATE}"]`)
    await expect(row).toHaveAttribute('aria-label', /vazio/i)
    await row.click()

    await expect(page.getByLabel('Refeições servidas no dia')).toBeVisible()
  })

  await test.step('registra as três refeições e o número do dia', async () => {
    await registerMeal(page, 'Lanche da manhã', MORNING, 'Ótimo')
    await registerMeal(page, 'Almoço', LUNCH, 'Bom')
    await registerMeal(page, 'Lanche da tarde', AFTERNOON, 'Ótimo')

    await page.getByLabel('Refeições servidas no dia').fill(MEALS_SERVED)
  })

  await test.step(`anota ${FOOD_ITEM.toLowerCase()} nos gêneros do almoço`, async () => {
    await openMeal(page, 'Almoço')
    await page.getByRole('button', { name: 'Adicionar gênero' }).click()

    const sheet = page.getByRole('dialog')
    await expect(sheet.getByText('Escolher gênero')).toBeVisible()
    await sheet.getByRole('button', { name: FOOD_ITEM }).click()

    // Escolhido, ele entra na refeição já com a quantidade em 1.
    await expect(
      page.getByRole('textbox', { name: `Quantidade de ${FOOD_ITEM}` })
    ).toHaveValue('1')
  })

  await test.step('o dia sobe sozinho, sem botão de salvar', async () => {
    /*
     * A faixa é a decisão 3 da E3 em uma linha, e é ela que diz que o dia
     * chegou ao servidor. Sem isto o mapa não teria identificador de lá, e a
     * tela seguinte não o deixaria entrar no documento.
     */
    await expect(
      page.getByText(
        'Enviado. Este mapa já está disponível para gerar o documento.'
      )
    ).toBeVisible({ timeout: 30_000 })
  })

  await test.step('o mês passa a mostrar o dia como preenchido', async () => {
    await page.getByRole('link', { name: 'Voltar para a visão do mês' }).click()

    await expect(page.locator(`a[href="/dia/${DATE}"]`)).toHaveAttribute(
      'aria-label',
      /preenchido/i
    )
  })

  await test.step('escolhe o mapa do dia para o documento', async () => {
    await page.getByRole('link', { name: 'Gerar documento' }).click()
    await page.getByRole('button', { name: 'Escolher dias' }).click()

    await page
      .getByRole('checkbox', { name: new RegExp(`^${DAY_LABEL},`) })
      .click()

    await expect(page.getByText('1 mapa selecionado')).toBeVisible()
  })

  await test.step('confirma e gera o documento', async () => {
    await page.getByRole('button', { name: 'Gerar documento' }).click()

    // A única confirmação do fluxo dela, porque o bloqueio é irreversível.
    const confirmation = page.getByRole('alertdialog')
    await expect(confirmation).toContainText(/fica bloqueado/)
    await confirmation
      .getByRole('button', { name: 'Gerar', exact: true })
      .click()

    await expect(page.getByText('Documento gerado')).toBeVisible({
      timeout: 60_000,
    })
  })

  await test.step('baixa o arquivo e confere o que está dentro', async () => {
    const download = page.waitForEvent('download')
    await page
      .getByRole('button', { name: `Baixar o documento de ${DAY_LABEL}` })
      .click()

    const file = await download
    expect(file.suggestedFilename()).toMatch(
      /^mapa-da-alimentacao-escolar-[a-z]+-\d{4}\.docx$/
    )

    const saved = await file.path()
    const xml = readFromDocx(readFileSync(saved), 'word/document.xml')
    const text = documentText(xml)

    // O documento saiu com o dia que ela acabou de registrar, e não com um
    // formulário em branco de aparência correta.
    expect(text).toContain(DAY_IN_DOCUMENT)
    expect(text).toContain(MORNING)
    expect(text).toContain(LUNCH)
    expect(text).toContain(AFTERNOON)
    expect(text).toContain(MEALS_SERVED)
    expect(text).toContain(`${FOOD_ITEM} — 1 quilo`)
    expect(text).toMatch(/\(X\)\s*bom/i)
  })

  await test.step('o dia registrado ficou bloqueado para edição', async () => {
    await page.goto(`/dia/${DATE}`)

    await expect(
      page.getByText('Este dia já está em um documento gerado')
    ).toBeVisible()
  })
})

/** Abre o cartão de uma refeição, se ele já não estiver aberto. */
async function openMeal(page: Page, title: string) {
  const header = page.getByRole('button', { name: title })
  if ((await header.getAttribute('aria-expanded')) !== 'true') {
    await header.click()
  }
  await expect(header).toHaveAttribute('aria-expanded', 'true')
}

/**
 * Uma refeição registrada: o cardápio previsto e a aceitação num toque.
 *
 * Só um cartão fica aberto por vez, então a tela tem um único campo de
 * descrição e um único trio de aceitação enquanto isto roda.
 */
async function registerMeal(
  page: Page,
  title: string,
  description: string,
  acceptance: string
) {
  await openMeal(page, title)
  await page.getByLabel('Cardápio previsto').fill(description)
  await page.getByRole('button', { name: acceptance, exact: true }).click()
  await expect(
    page.getByRole('button', { name: acceptance, exact: true })
  ).toHaveAttribute('aria-pressed', 'true')
}
