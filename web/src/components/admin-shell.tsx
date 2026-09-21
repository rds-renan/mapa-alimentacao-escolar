import { CalendarDays, LayoutGrid, Users } from 'lucide-react'
import { NavLink } from 'react-router'

import { ADMIN_MESSAGES } from '@/admin/messages'
import { SignOutButton } from '@/auth/sign-out-button'
import { useAuth } from '@/auth/useAuth'
import { ROUTES } from '@/routes'
import { ThemeChoice } from '@/theme/theme-choice'

/*
 * A casca das telas da direção — a barra lateral das telas Painel e Gestão da
 * E3.
 *
 * Ela existe porque o fluxo da direção é outro fluxo, e não um menu a mais no
 * da merendeira (RN#1 da US020): não há caminho de um para o outro em lugar
 * nenhum da interface, e as duas guardas de rota é que o garantem.
 *
 * Os destinos são três, e nenhum deles registra mapa. O terceiro — Mapas — é o
 * da issue #69, e é o único que toca em mapa: ele **reabre**, e quem corrige
 * continua sendo a merendeira (RN#1 da US023). Não é caminho para o registro;
 * é a saída do beco que o bloqueio cria.
 *
 * Largura: o desenho da E3 é de computador, e é assim que a direção trabalha
 * — a merendeira é que registra de celular. Mas a web abre em qualquer
 * aparelho, então a barra lateral vira uma faixa de duas abas no alto quando
 * não couber, em vez de uma coluna espremida.
 */

interface Destination {
  to: string
  label: string
  icon: typeof Users
}

const DESTINATIONS: Destination[] = [
  { to: ROUTES.adminHome, label: ADMIN_MESSAGES.dashboard, icon: LayoutGrid },
  { to: ROUTES.adminManagement, label: ADMIN_MESSAGES.management, icon: Users },
  { to: ROUTES.adminMaps, label: ADMIN_MESSAGES.maps, icon: CalendarDays },
]

export function AdminShell({
  title,
  subtitle,
  actions,
  children,
}: {
  title: string
  subtitle: string
  /**
   * O controle da própria tela, à direita do título. Hoje só o painel tem um
   * — o seletor de mês (US017) —, e ele fica no cabeçalho porque muda a tela
   * inteira, não um cartão dela.
   */
  actions?: React.ReactNode
  children: React.ReactNode
}) {
  const { profile } = useAuth()

  return (
    <div className="flex min-h-dvh flex-col bg-background md:flex-row">
      <header className="flex shrink-0 flex-col border-b border-border bg-card md:w-60 md:border-r md:border-b-0 md:px-3 md:py-5">
        <div className="flex items-center gap-2.5 px-4 py-3 md:px-2.5 md:pt-1 md:pb-5">
          <img src="/logo.png" alt="" className="size-9" />
          <div className="flex min-w-0 flex-col">
            <span className="text-sm font-semibold tracking-tight">
              {ADMIN_MESSAGES.brand}
            </span>
            <span className="truncate text-2xs text-muted-foreground">
              {ADMIN_MESSAGES.brandSubtitle}
            </span>
          </div>
        </div>

        <nav
          aria-label={ADMIN_MESSAGES.openMenu}
          className="flex gap-1 px-2 pb-2 md:flex-col md:px-0 md:pb-0"
        >
          {DESTINATIONS.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end
              className={({ isActive }) =>
                `flex min-h-touch flex-1 items-center gap-2.5 rounded-lg px-3 text-sm font-medium md:flex-none ${
                  isActive
                    ? 'bg-accent font-semibold text-primary'
                    : 'text-secondary-foreground hover:bg-muted'
                }`
              }
            >
              <Icon className="size-4.5 shrink-0" aria-hidden="true" />
              {label}
            </NavLink>
          ))}
        </nav>

        {/*
         * O tema, quem está logada e a saída, no pé da barra. Mesmo lugar que
         * a decisão 9 da E3 deu para o "Sair" da merendeira: fora do cabeçalho
         * de cada tela, num canto só do aplicativo.
         *
         * O tema entra aqui porque a barra lateral é o único canto fixo que a
         * direção tem — não há menu do lado dela (RN#1 da US020, que separa os
         * dois fluxos). Sem isto, quem trabalha à noite no computador da
         * secretaria seria a única do sistema sem escolha de tema.
         *
         * O bloco inteiro é de computador, como o resto da barra: no celular a
         * direção fica com o padrão "Sistema", que já acompanha o aparelho.
         */}
        <div className="mt-auto hidden flex-col gap-3 border-t border-muted px-2.5 pt-3 md:flex">
          <ThemeChoice />

          <div className="flex items-center gap-2.5">
            <div className="flex min-w-0 flex-1 flex-col">
              <span className="truncate text-sm font-medium">
                {profile?.name}
              </span>
              <span className="text-2xs text-muted-foreground">
                {ADMIN_MESSAGES.role}
              </span>
            </div>
            <SignOutButton />
          </div>
        </div>
      </header>

      {/*
       * O conteúdo tem largura máxima. O desenho da E3 é de 1440 px e a tela
       * cabia inteira nele; num monitor maior, sem o teto, a linha de uma
       * merendeira esticaria o nome numa ponta e os botões na outra, com meio
       * metro de nada no meio.
       */}
      <div className="mx-auto flex w-full max-w-6xl min-w-0 flex-1 flex-col">
        <div className="flex items-start gap-3 px-4 pt-5 pb-1 md:px-8 md:pt-7">
          <hgroup className="flex min-w-0 flex-1 flex-col gap-0.5">
            <h1 className="text-xl font-semibold tracking-tight">{title}</h1>
            <p className="text-sm text-muted-foreground">{subtitle}</p>
          </hgroup>

          {actions}

          {/* No celular a barra de baixo não existe, e a saída fica aqui. */}
          <div className="md:hidden">
            <SignOutButton />
          </div>
        </div>

        <main className="flex min-w-0 flex-1 flex-col gap-4 px-4 py-4 md:px-8 md:pb-8">
          {children}
        </main>
      </div>
    </div>
  )
}
