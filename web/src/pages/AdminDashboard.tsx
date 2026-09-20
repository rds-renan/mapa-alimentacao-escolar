import { AdminShell } from '@/components/admin-shell'

/*
 * A tela-casa da direção. O painel gerencial é a issue #70; o que existe aqui
 * é a tela-marco que a #61 estabeleceu como convenção — o destino existe, diz
 * de qual issue é, e a navegação em volta já é a definitiva.
 *
 * O que importa nela desde já é o que ela não é: o destino de quem entra como
 * direção **não** é o fluxo do mapa. São dois fluxos, e é isso que as guardas
 * de rota separam.
 */
export function AdminDashboard() {
  return (
    <AdminShell
      title="Painel"
      subtitle="O histórico mensal da alimentação da escola"
    >
      <p className="text-base text-muted-foreground">
        O painel gerencial entra na issue #70. A gestão de acessos, do modelo
        oficial e dos dados da escola está em Gestão, aqui ao lado.
      </p>
    </AdminShell>
  )
}
