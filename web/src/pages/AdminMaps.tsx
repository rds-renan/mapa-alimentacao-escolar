import { ADMIN_MESSAGES } from '@/admin/messages'
import { LockedMapsCard } from '@/admin/locked-maps-card'
import { UnlocksCard } from '@/admin/unlocks-card'
import { AdminShell } from '@/components/admin-shell'

/*
 * A tela Mapas — o terceiro destino da direção (US023, issue #69).
 *
 * Ela existe porque a RN#1 da US007 cria um beco: o mapa incluído em documento
 * gerado fica bloqueado, e um erro descoberto depois não tinha caminho nenhum.
 * No preenchimento manual elas refazem a folha, e um aplicativo que trave a
 * correção seria pior que o improviso que veio substituir.
 *
 * A E3 desenhou dois destinos para a direção, e este é o terceiro: o desenho
 * veio antes da revisão de escopo que criou a US023, e é o mesmo precedente da
 * #64 e da #68 — `design/telas/` e os PNGs são atualizados no mesmo PR.
 *
 * São dois cartões, e a ordem deles é a do gesto: encontra o dia, reabre;
 * embaixo, o que já foi reaberto. O que esta tela **não** tem é caminho para o
 * mapa — ela não abre o dia, não mostra o que está escrito nele e não o edita.
 * A direção reabre; quem corrige é a merendeira.
 */
export function AdminMaps() {
  return (
    <AdminShell
      title={ADMIN_MESSAGES.mapsTitle}
      subtitle={ADMIN_MESSAGES.mapsSubtitle}
    >
      <LockedMapsCard />
      <UnlocksCard />
    </AdminShell>
  )
}
