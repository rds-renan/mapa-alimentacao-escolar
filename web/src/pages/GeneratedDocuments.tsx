import { PendingScreen } from '@/components/pending-screen'

/** Os documentos ainda dentro da janela de 7 dias (issue #67). */
export function GeneratedDocuments() {
  return (
    <PendingScreen title="Documentos gerados" issue={67}>
      Aqui ficam os documentos ainda dentro dos 7 dias, com o período de cada um
      e a ação de compartilhar de novo.
    </PendingScreen>
  )
}
