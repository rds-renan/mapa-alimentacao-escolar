import { ADMIN_MESSAGES } from '@/admin/messages'
import { CooksCard } from '@/admin/cooks-card'
import { SchoolCard } from '@/admin/school-card'
import { TemplateCard } from '@/admin/template-card'
import { useAuth } from '@/auth/useAuth'
import { AdminShell } from '@/components/admin-shell'

/*
 * A tela de gestão da direção — a tela "Gestão" da E3 (US015, US016).
 *
 * São três assuntos numa tela só, e o que eles têm em comum é serem o
 * gerencial que não faz sentido ficar na carga das merendeiras: quem entra no
 * sistema, com qual modelo o documento sai e o que aparece no cabeçalho dele.
 *
 * O que esta tela **não** tem, e nenhuma outra da direção tem, é caminho para
 * registrar mapa: são dois fluxos separados, e quem os separa de verdade são
 * as políticas de RLS da E4 — a `meal_map_cook_insert` exige o papel de
 * merendeira, e nem um endereço digitado à mão contorna isso.
 */
export function AdminManagement() {
  const { profile } = useAuth()

  return (
    <AdminShell
      title={ADMIN_MESSAGES.managementTitle}
      subtitle={ADMIN_MESSAGES.managementSubtitle}
    >
      <CooksCard />

      <div className="grid gap-4 lg:grid-cols-2">
        <TemplateCard schoolId={profile?.school_id} />
        <SchoolCard />
      </div>
    </AdminShell>
  )
}
