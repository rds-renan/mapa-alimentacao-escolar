import { execFileSync } from 'node:child_process'
import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'

import { createClient, type SupabaseClient } from '@supabase/supabase-js'

import type { Database } from '../src/lib/database.types'

import {
  DOCUMENT_BUCKET,
  SCHOOL_ID,
  TEMPLATE_BUCKET,
  TEMPLATE_PATH,
  testDate,
} from './cenario'
import { supabaseLocal } from './supabase-local'

/*
 * O que precisa estar de pé antes de o navegador abrir.
 *
 * São duas coisas, e nenhuma delas é papel da merendeira — por isso nenhuma
 * passa pela tela:
 *
 * 1. **o modelo oficial no balde.** O seed registra a linha do modelo, mas um
 *    arquivo não cabe num `.sql`; e o modelo de verdade não entra no
 *    repositório (tem brasão, nome da prefeitura e um mapa real preenchido).
 *    Quem sobe é o mesmo modelo de teste que a Edge Function usa nos testes
 *    dela — construído do zero, com a estrutura do oficial e nada do que é
 *    dele. Reaproveitá-lo é o que impede dois modelos sintéticos envelhecerem
 *    em direções diferentes.
 *
 * 2. **o dia do teste em branco.** A geração bloqueia o mapa, então a segunda
 *    rodada encontraria o dia da primeira travado e o teste falharia dizendo
 *    algo que não é sobre o caminho. A limpeza é cirúrgica — só o dia que este
 *    teste usa e os documentos que o incluíram —, e acontece **antes** da
 *    rodada, não depois: assim o rastro da falha continua no banco para ser
 *    aberto no Studio.
 *
 * A chave secreta aparece aqui e em nenhum outro lugar: apagar mapa bloqueado
 * e escrever no balde do modelo é coisa que as políticas de acesso negam de
 * propósito a quem está logada. Ela é a chave do Supabase local, impressa pela
 * CLI e igual em qualquer máquina.
 */

const repositorio = path.resolve(import.meta.dirname, '../..')

export default async function preparar() {
  const { url, secretKey } = supabaseLocal()

  // Com os tipos que a decisão 8 da E5 manda gerar: a preparação mexe nas
  // mesmas tabelas que a aplicação, e uma coluna renomeada tem de quebrar aqui
  // também, na checagem de tipos, e não no meio de uma rodada.
  const supabase = createClient<Database>(url, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  await conferirOSeed(supabase)
  await limparODiaDoTeste(supabase)
  await subirOModelo(supabase)
}

type Servidor = SupabaseClient<Database>

/**
 * O seed está aplicado?
 *
 * A pergunta vale a resposta: sem ele, tudo o que vem depois falha por um
 * motivo diferente do verdadeiro — login recusado, catálogo vazio, modelo sem
 * registro —, e o teste apontaria para o lugar errado.
 */
async function conferirOSeed(supabase: Servidor) {
  const { data, error } = await supabase
    .from('document_template')
    .select('id, file_path')
    .eq('school_id', SCHOOL_ID)
    .eq('is_current', true)
    .maybeSingle()

  if (error) {
    throw new Error(
      `O banco local não respondeu (${error.message}). Suba-o com ` +
        '`supabase start && supabase db reset`.'
    )
  }

  if (!data) {
    throw new Error(
      'O seed de desenvolvimento não está aplicado: a escola do teste não tem ' +
        'modelo oficial vigente. Rode `supabase db reset`.'
    )
  }

  if (data.file_path !== TEMPLATE_PATH) {
    throw new Error(
      `O modelo vigente aponta para ${data.file_path}, e a preparação sobe o ` +
        `arquivo em ${TEMPLATE_PATH}. Um dos dois mudou.`
    )
  }
}

async function limparODiaDoTeste(supabase: Servidor) {
  const date = testDate()

  const { data: map, error: mapError } = await supabase
    .from('meal_map')
    .select('id')
    .eq('school_id', SCHOOL_ID)
    .eq('map_date', date)
    .maybeSingle()

  if (mapError) throw new Error(mapError.message)
  if (!map) return

  // Os documentos que incluíram este dia. O vínculo é `on delete restrict` no
  // mapa de propósito — documento gerado é permanente (decisão 10 da E4) —,
  // então o documento sai primeiro, e leva o vínculo junto na cascata.
  const { data: links, error: linkError } = await supabase
    .from('document_meal_map')
    .select('generated_document_id')
    .eq('meal_map_id', map.id)

  if (linkError) throw new Error(linkError.message)

  const documentIds = [
    ...new Set(links.map((link) => link.generated_document_id)),
  ]

  if (documentIds.length > 0) {
    const { data: documents, error: documentError } = await supabase
      .from('generated_document')
      .select('id, file_path')
      .in('id', documentIds)

    if (documentError) throw new Error(documentError.message)

    const paths = documents
      .map((document) => document.file_path)
      .filter((file): file is string => file !== null)

    if (paths.length > 0) {
      await supabase.storage.from(DOCUMENT_BUCKET).remove(paths)
    }

    const { error } = await supabase
      .from('generated_document')
      .delete()
      .in('id', documentIds)

    if (error) throw new Error(error.message)
  }

  const { error } = await supabase.from('meal_map').delete().eq('id', map.id)
  if (error) throw new Error(error.message)
}

async function subirOModelo(supabase: Servidor) {
  const pasta = mkdtempSync(path.join(tmpdir(), 'mae-modelo-'))

  try {
    const arquivo = path.join(pasta, 'modelo-de-teste.docx')

    // O mesmo construtor que os testes da Edge Function usam, chamado pelo seu
    // próprio caminho de linha de comando.
    execFileSync(
      'deno',
      ['run', '--allow-write', '_shared/modelo-de-teste.ts', arquivo],
      {
        cwd: path.join(repositorio, 'supabase/functions'),
        stdio: ['ignore', 'ignore', 'pipe'],
      }
    )

    const { error } = await supabase.storage
      .from(TEMPLATE_BUCKET)
      .upload(TEMPLATE_PATH, readFileSync(arquivo), {
        contentType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        upsert: true,
      })

    if (error) {
      throw new Error(`Não deu para subir o modelo de teste: ${error.message}`)
    }
  } finally {
    rmSync(pasta, { recursive: true, force: true })
  }
}
