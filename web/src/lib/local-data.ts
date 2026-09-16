/*
 * O que sair do aplicativo precisa apagar (CA#5 da issue #59).
 *
 * A sessão em si é apagada pelo próprio Supabase no `signOut`. O que fica por
 * conta daqui é o dado do dia a dia: a partir da issue #60, o rascunho do dia
 * em edição e a fila de envios pendentes moram no IndexedDB (decisão 3 da E5),
 * e eles são da pessoa que estava logada — as duas merendeiras se revezam no
 * mesmo aparelho, e o rascunho de uma não pode aparecer para a outra.
 *
 * O que NÃO se apaga é o que é do aparelho e não da pessoa: a preferência de
 * tema (US024) mora no localStorage justamente por ser escolha do aparelho, e
 * sair da conta não muda o aparelho.
 *
 * Atenção para quando a fila existir (issue #60): apagar a fila com envios
 * pendentes é perder mapa que ainda não subiu — a regra RN#1 da US011 diz que
 * o dado local não se descarta antes de confirmado no servidor. Quem chamar
 * isto precisa primeiro avisar que há coisa por enviar.
 */
export async function clearLocalData(): Promise<void> {
  try {
    sessionStorage.clear()
  } catch {
    // Navegador com armazenamento bloqueado: não há o que limpar.
  }

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
