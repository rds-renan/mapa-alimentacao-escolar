import { useSyncExternalStore } from 'react'

/*
 * A rede, como a tela 5 precisa dela.
 *
 * A fila de envio já consulta `navigator.onLine` para não tentar o que vai
 * falhar; aqui a pergunta é outra e é de interface: **antes** de ela tocar em
 * "Gerar documento", a tela precisa dizer que a geração acontece no servidor e
 * depende de internet (RN#3 da US012). O catálogo de avisos da E3 escreveu
 * esse aviso para ficar na tela, com o botão desabilitado — explicar a espera
 * em vez de deixar o toque falhar em silêncio.
 *
 * `navigator.onLine` é notoriamente otimista: ele diz que há *uma rede*, não
 * que há internet. Serve mesmo assim, porque o custo do engano é pequeno — o
 * falso positivo cai no diálogo de falha, que já existe; o falso negativo não
 * acontece, porque sem interface de rede não há rede.
 */

function subscribe(onChange: () => void): () => void {
  window.addEventListener('online', onChange)
  window.addEventListener('offline', onChange)

  return () => {
    window.removeEventListener('online', onChange)
    window.removeEventListener('offline', onChange)
  }
}

export function useOnline(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => navigator.onLine,
    // No servidor não há navegador, e a tela nasce supondo que há rede: é o
    // estado em que ela não atrapalha.
    () => true
  )
}
