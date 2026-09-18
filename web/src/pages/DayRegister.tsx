import { useParams } from 'react-router'

import { PendingScreen } from '@/components/pending-screen'

/** O registro do dia (issue #62). Por enquanto, só o destino do toque no dia. */
export function DayRegister() {
  const { mapDate } = useParams()

  return (
    <PendingScreen title="Registro do dia" issue={62}>
      A visão do mês já sabe abrir cada dia — este é o dia {mapDate}.
    </PendingScreen>
  )
}
