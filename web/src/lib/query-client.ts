import { QueryClient } from '@tanstack/react-query'

/*
 * O cliente da TanStack Query — a metade de cima da fronteira da decisão 4 da
 * E5: o que vem do servidor é dela, o que ainda não subiu é da camada local.
 * Ela entra aqui, e não na fundação, porque a visão do mês é a primeira tela
 * que lê do servidor; antes disso seria dependência por antecipação.
 *
 * Os ajustes fogem do padrão da biblioteca em dois pontos, e os dois são sobre
 * a escola: a internet lá é fraca e intermitente.
 */
export function createQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        /*
         * Meio minuto sem reconsultar. O dado que esta tela mostra muda quando
         * a própria merendeira mexe nele — e aí quem invalida é a fila, não o
         * relógio. O que este tempo evita é a consulta repetida a cada ida e
         * volta entre o mês e o dia, que numa rede ruim vira espera visível.
         */
        staleTime: 30_000,
        /*
         * Três tentativas, com a espera dobrando: numa rede que oscila, a
         * segunda tentativa quase sempre pega. Passar disso é insistir num
         * erro que não é de rede.
         */
        retry: 3,
        /*
         * Voltar para a aba não é sinal de dado velho — é ela voltando da
         * cozinha. Quem revalida de verdade é o retorno da rede, logo abaixo.
         */
        refetchOnWindowFocus: false,
        refetchOnReconnect: true,
      },
    },
  })
}
