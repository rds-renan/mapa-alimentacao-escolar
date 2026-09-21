import type { MonthSummary } from './dashboard'
import {
  countLabel,
  DASHBOARD_MESSAGES,
  registeredDaysLabel,
  remainingDaysLabel,
} from './messages'

/*
 * Os três números do alto do painel (CA#2 da US017).
 *
 * Cada um vem com uma linha embaixo dizendo de que ele é feito, e isso não é
 * enfeite: "312" não distingue média de meta, e o número de refeições do dia é
 * informado pela direção às merendeiras (RN#1 da US005) — dizê-lo evita que a
 * direção leia o painel como se o número tivesse sido contado na cozinha.
 *
 * O terceiro cartão é o único que não é um número, é uma fração: "20 de 22"
 * responde a pergunta que a direção faz de verdade, que não é quantos dias
 * foram registrados, é se falta algum.
 */
export function SummaryCards({ summary }: { summary: MonthSummary }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <SummaryCard
        title={DASHBOARD_MESSAGES.servedTitle}
        value={countLabel(summary.mealsServed)}
        hint={DASHBOARD_MESSAGES.servedHint}
      />
      <SummaryCard
        title={DASHBOARD_MESSAGES.averageTitle}
        /*
         * Um travessão, e não um zero: mês sem nenhum dia com o número
         * informado não tem média zero, não tem média nenhuma — e "0" faria a
         * direção procurar o dia em que a escola não serviu nada.
         */
        value={
          summary.averagePerDay === null
            ? '—'
            : countLabel(summary.averagePerDay)
        }
        hint={DASHBOARD_MESSAGES.averageHint}
      />
      <SummaryCard
        title={DASHBOARD_MESSAGES.daysTitle}
        value={registeredDaysLabel(summary.registered, summary.schoolDays)}
        hint={remainingDaysLabel(summary)}
      />
    </div>
  )
}

function SummaryCard({
  title,
  value,
  hint,
}: {
  title: string
  value: string
  hint: string
}) {
  return (
    <div className="flex flex-col gap-1.5 rounded-xl border border-border bg-card px-5 py-4.5">
      <span className="text-xs font-medium text-muted-foreground">{title}</span>
      {/*
       * `tabular-nums` porque os três cartões ficam lado a lado: sem isso os
       * números dançam de largura e as linhas de baixo desalinham.
       */}
      <span className="text-3xl font-semibold tracking-tight tabular-nums">
        {value}
      </span>
      <span className="text-xs text-muted-foreground">{hint}</span>
    </div>
  )
}
