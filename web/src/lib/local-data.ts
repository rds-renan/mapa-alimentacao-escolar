import { closeLocalDatabase } from '@/local/store'

/*
 * O que sair do aplicativo apaga (CA#5 da issue #59).
 *
 * Sair apaga **tudo** o que era da pessoa no aparelho, inclusive o dia que
 * ainda não subiu. A sessão em si é apagada pelo próprio Supabase no `signOut`;
 * o resto é daqui.
 *
 * Isso vale contra a leitura literal da RN#1 da US011, e é decisão consciente.
 * Guardar mapa por enviar depois da saída custaria mais do que salva: a web é
 * uso raro neste produto — o registro do dia acontece no celular —, então um
 * dia parado aqui pode esperar **meses**, por uma pessoa que talvez nunca mais
 * entre, e chegar ao servidor num formato que o sistema já não reconhece. Ficar
 * sem internet num computador também é bem mais raro do que no celular, então o
 * cenário que justificaria guardar quase não existe.
 *
 * O que torna isso legítimo é o aviso: quem tem mapa por enviar é avisada antes
 * de sair e decide. Perder por escolha dela é uma coisa; perder por decisão do
 * sistema seria outra.
 *
 * O que NÃO se apaga é o que é do aparelho e não da pessoa: a preferência de
 * tema (US024) mora no localStorage justamente por ser escolha do aparelho, e
 * sair da conta não muda o aparelho.
 */
export async function clearLocalData(): Promise<void> {
  try {
    sessionStorage.clear()
  } catch {
    // Navegador com armazenamento bloqueado: não há o que limpar.
  }

  // Antes de apagar, fechar: banco com conexão aberta não apaga, fica esperando.
  await closeLocalDatabase()

  if (typeof indexedDB === 'undefined' || !indexedDB.databases) return

  try {
    // A origem é só do MAE: todo banco que existir aqui é nosso.
    const databases = await indexedDB.databases()
    await Promise.all(
      databases.map(
        (database) =>
          new Promise<void>((resolve) => {
            if (!database.name) return resolve()
            const request = indexedDB.deleteDatabase(database.name)
            // Resolve em qualquer desfecho: um banco que não apagou agora não
            // pode segurar a saída da pessoa da conta.
            request.onsuccess = () => resolve()
            request.onerror = () => resolve()
            request.onblocked = () => resolve()
          })
      )
    )
  } catch {
    // Idem: falha ao listar não impede sair.
  }
}
