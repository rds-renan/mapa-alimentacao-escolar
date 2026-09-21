import type { TopMeal } from './dashboard'
import { DASHBOARD_MESSAGES, percentLabel, timesServedLabel } from './messages'

/*
 * As merendas mais bem aceitas do mês (CA#3 da US017).
 *
 * A merenda não é um cadastro: é o cardápio previsto em texto livre, e o
 * agrupamento é pela descrição normalizada (decisão 3 da E4). "Arroz com
 * frango" e "arroz c/ frango" contam separado — limitação declarada do MVP,
 * cujo lugar de solução é a ingestão do cardápio (US019). A nota no pé do
 * cartão diz isso à direção, em vez de deixá-la descobrir sozinha por que a
 * mesma merenda aparece duas vezes.
 *
 * Cada linha traz quantas vezes a merenda foi servida no mês, e é o que impede
 * o ranking de mentir: num mês uma merenda aparece uma ou duas vezes, então
 * 100% de uma vez só é o caso comum, não a campeã da escola. O painel mostra
 * o número em vez de aplicar um mínimo silencioso — cortar esconderia da
 * direção uma merenda que existiu.
 */
export function TopMealsCard({ meals }: { meals: TopMeal[] }) {
  return (
    <section
      aria-labelledby="top-meals-title"
      className="flex flex-col gap-4.5 rounded-xl border border-border bg-card p-5"
    >
      <hgroup className="flex flex-col gap-0.5">
        <h2 id="top-meals-title" className="text-lg font-semibold">
          {DASHBOARD_MESSAGES.topTitle}
        </h2>
        <p className="text-xs text-muted-foreground">
          {DASHBOARD_MESSAGES.topSubtitle}
        </p>
      </hgroup>

      {meals.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          {DASHBOARD_MESSAGES.topEmpty}
        </p>
      ) : (
        <>
          <ol className="flex flex-col gap-3.5">
            {meals.map((meal) => (
              <TopMealRow key={meal.name} meal={meal} />
            ))}
          </ol>

          <p className="text-2xs text-muted-foreground">
            {DASHBOARD_MESSAGES.topHint}
          </p>
        </>
      )}
    </section>
  )
}

function TopMealRow({ meal }: { meal: TopMeal }) {
  return (
    <li className="flex flex-col gap-1.5">
      <div className="flex items-baseline justify-between gap-3">
        <span className="min-w-0 text-sm">{meal.name}</span>
        <span className="shrink-0 text-xs tabular-nums">
          {percentLabel(meal.greatShare)}
        </span>
      </div>

      {/*
       * A barra é o mesmo dado do número ao lado, desenhada — por isso
       * `aria-hidden`: anunciada, ela repetiria "92%" duas vezes seguidas.
       */}
      <div
        aria-hidden="true"
        className="h-2 overflow-hidden rounded-sm bg-muted"
      >
        <div
          className="h-full rounded-sm bg-chart-1"
          style={{ width: `${meal.greatShare}%` }}
        />
      </div>

      <span className="text-2xs text-muted-foreground">
        {timesServedLabel(meal.times)}
      </span>
    </li>
  )
}
