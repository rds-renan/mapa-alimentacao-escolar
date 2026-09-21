import { MEAL_TITLES } from '@/day/messages'
import { MEAL_ORDER, type MealType } from '@/local/day'

import type { MealAcceptance } from './dashboard'
import {
  acceptanceSummaryLabel,
  DASHBOARD_MESSAGES,
  greatShareLabel,
} from './messages'

/*
 * A aceitação das três refeições no mês (CA#1 da US017).
 *
 * A barra é feita de três `div` com largura em porcentagem, e não de uma
 * biblioteca de gráficos. As decisões técnicas da E5 previam que uma nascesse
 * aqui; o desenho da E3 não pede nenhuma — não há eixo, escala, tooltip nem
 * série temporal, só a proporção de três valores que somam o todo. Cem
 * quilobytes para desenhar três retângulos seria peso sem contrapartida, e o
 * CLAUDE.md pede para não antecipar dependência.
 *
 * As cores são a paleta de dados da decisão 6 da E3 — `--chart-1/2/3`, azul →
 * cinza → vermelho —, separada do acento da marca e validada para daltonismo.
 * Elas não carregam a informação sozinhas: o número ao lado diz a mesma coisa
 * em texto, e a frase do `aria-label` diz a distribuição inteira. É o que
 * mantém a leitura de pé no tema escuro, no monitor da secretaria e no leitor
 * de tela.
 */
export function AcceptanceCard({
  acceptance,
}: {
  acceptance: Record<MealType, MealAcceptance>
}) {
  const rated = MEAL_ORDER.reduce(
    (total, type) => total + acceptance[type].rated,
    0
  )

  return (
    <section
      aria-labelledby="acceptance-title"
      className="flex flex-col gap-4.5 rounded-xl border border-border bg-card p-5"
    >
      <div className="flex flex-wrap items-start gap-x-4 gap-y-2">
        <hgroup className="flex min-w-0 flex-1 flex-col gap-0.5">
          <h2 id="acceptance-title" className="text-lg font-semibold">
            {DASHBOARD_MESSAGES.acceptanceTitle}
          </h2>
          <p className="text-xs text-muted-foreground">
            {DASHBOARD_MESSAGES.acceptanceSubtitle}
          </p>
        </hgroup>

        {/*
         * A legenda é `aria-hidden` porque só explica a cor, e quem não vê a
         * cor já recebe a distribuição em palavras na frase de cada barra.
         */}
        <ul
          aria-hidden="true"
          className="flex flex-wrap items-center gap-x-3.5 gap-y-1"
        >
          <Legend color="bg-chart-1" label={DASHBOARD_MESSAGES.great} />
          <Legend
            color="border border-border bg-chart-2"
            label={DASHBOARD_MESSAGES.good}
          />
          <Legend color="bg-chart-3" label={DASHBOARD_MESSAGES.poor} />
        </ul>
      </div>

      {rated === 0 ? (
        <p className="text-sm text-muted-foreground">
          {DASHBOARD_MESSAGES.acceptanceEmpty}
        </p>
      ) : (
        <>
          <ul className="flex flex-col gap-4">
            {MEAL_ORDER.map((type) => (
              <AcceptanceRow key={type} meal={acceptance[type]} />
            ))}
          </ul>

          <p className="text-2xs text-muted-foreground">
            {DASHBOARD_MESSAGES.acceptanceHint}
          </p>
        </>
      )}
    </section>
  )
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <li className="flex items-center gap-1.5 text-xs text-secondary-foreground">
      <span className={`size-2.5 rounded-full ${color}`} />
      {label}
    </li>
  )
}

function AcceptanceRow({ meal }: { meal: MealAcceptance }) {
  const title = MEAL_TITLES[meal.type]

  return (
    <li className="flex flex-wrap items-center gap-x-3.5 gap-y-1.5">
      <span className="w-32 shrink-0 text-sm text-secondary-foreground">
        {title}
      </span>

      {/*
       * A barra **não** tem trilho de fundo, e isso custou uma volta: com um
       * `bg-muted` atrás, o cinza do "bom" (`--chart-2`, #f0efec) ficava
       * indistinguível do trilho (#f4f4f5), que é a mesma cor a olho. Uma
       * refeição sem nenhum "ótimo" aparecia como uma barra quase vazia com um
       * pedaço vermelho no fim — quando o claro era o "bom", e a refeição
       * estava longe de ser um fracasso. As três fatias somam o todo, então
       * trilho não é informação: é uma quarta cor disputando com uma das três.
       */}
      <div
        role="img"
        aria-label={acceptanceSummaryLabel(title, meal.counts)}
        className="flex h-4.5 min-w-32 flex-1 gap-0.5 overflow-hidden rounded-sm"
      >
        {/*
         * As larguras são a proporção exata, sem arredondar: três inteiros
         * arredondados somam 99 ou 101, e a sobra aparece como um degrau na
         * ponta da barra. O número arredondado fica no rótulo, onde ele é
         * lido, e não na geometria, onde ele se acumula.
         */}
        {meal.rated === 0 ? (
          <div className="w-full rounded-sm bg-muted" />
        ) : (
          <>
            <Segment
              share={meal.shares.great}
              className="rounded-l-sm bg-chart-1"
            />
            {/*
             * O "bom" é claro demais para se sustentar sozinho sobre o cartão
             * branco: sem o fio da borda, o fim da fatia desaparece quando ela
             * é a última. É o mesmo fio que o desenho da E3 dá ao ponto da
             * legenda, e pelo mesmo motivo. Em sombra interna, para não somar
             * largura à fatia.
             */}
            <Segment
              share={meal.shares.good}
              className="bg-chart-2 shadow-[inset_0_0_0_1px_var(--border)]"
            />
            <Segment
              share={meal.shares.poor}
              className="rounded-r-sm bg-chart-3"
            />
          </>
        )}
      </div>

      <span className="w-20 shrink-0 text-xs tabular-nums">
        {meal.rated === 0 ? '—' : greatShareLabel(meal.shares.great)}
      </span>
    </li>
  )
}

/** Um pedaço da barra. Fatia zerada não desenha nada — nem a borda do raio. */
function Segment({ share, className }: { share: number; className: string }) {
  if (share === 0) return null
  return <div className={className} style={{ width: `${share}%` }} />
}
