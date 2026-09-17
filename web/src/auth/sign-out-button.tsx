import { useState } from 'react'
import { LogOut } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { pendingOnSignOutMessage } from '@/local/messages'
import { useSync } from '@/local/useSync'

import { useAuth } from './useAuth'

/*
 * Sair: encerra a sessão e apaga o que era da pessoa no aparelho (CA#5 da
 * issue #59), inclusive o dia que ainda não subiu.
 *
 * Quando há mapa por enviar, ela é avisada antes e decide. É o que transforma
 * uma perda de dado numa escolha: o motivo de apagar está em
 * `src/lib/local-data.ts`, e ele só se sustenta se ela souber antes.
 *
 * O lugar definitivo deste botão é o menu do aplicativo (issue #61) e a área da
 * direção; enquanto as telas não existem, ele mora aqui para que a saída exista
 * desde já — e o aviso é inline pelo mesmo motivo, à espera do diálogo que a
 * E3 desenhou e que a issue #66 também vai precisar.
 */
export function SignOutButton() {
  const { signOut } = useAuth()
  const { pendingCount } = useSync()
  const [pending, setPending] = useState(0)
  const [leaving, setLeaving] = useState(false)

  function leave() {
    setLeaving(true)
    void signOut()
  }

  /*
   * Pergunta ao disco no clique, e não ao contador que a fila mantém para a
   * tela: o contador só fica quente depois do arranque, e quem decide apagar
   * precisa do número certo, não do número provável.
   */
  async function ask() {
    const count = await pendingCount()
    if (count > 0) setPending(count)
    else leave()
  }

  return (
    <div className="relative">
      <Button
        variant="ghost"
        size="sm"
        disabled={leaving}
        aria-expanded={pending > 0}
        onClick={() => void ask()}
      >
        <LogOut aria-hidden="true" />
        Sair
      </Button>

      {pending > 0 ? (
        <div
          role="alertdialog"
          aria-label="Sair com mapa por enviar"
          className="absolute top-full right-0 z-10 mt-2 flex w-72 flex-col gap-3 rounded-lg border border-border bg-card p-4 shadow-lg"
        >
          <p className="text-sm text-foreground">
            {pendingOnSignOutMessage(pending)}
          </p>
          <div className="flex justify-end gap-2">
            <Button variant="ghost" size="sm" onClick={() => setPending(0)}>
              Ficar
            </Button>
            <Button
              variant="destructive"
              size="sm"
              disabled={leaving}
              onClick={leave}
            >
              Sair e apagar
            </Button>
          </div>
        </div>
      ) : null}
    </div>
  )
}
