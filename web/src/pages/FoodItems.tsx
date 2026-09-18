import { PendingScreen } from '@/components/pending-screen'

/** A manutenção do catálogo de gêneros (issue #64). */
export function FoodItems() {
  return (
    <PendingScreen title="Gerenciar gêneros" issue={64}>
      Aqui ficam os gêneros da cozinha, cada um com a sua unidade padrão.
    </PendingScreen>
  )
}
