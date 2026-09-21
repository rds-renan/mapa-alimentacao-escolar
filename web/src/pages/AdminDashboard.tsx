import { CircleAlert, LoaderCircle } from 'lucide-react'
import { useSearchParams } from 'react-router'

import { AcceptanceCard } from '@/admin/acceptance-card'
import { useDashboard } from '@/admin/dashboard-queries'
import { ADMIN_MESSAGES, DASHBOARD_MESSAGES } from '@/admin/messages'
import { MonthPicker } from '@/admin/month-picker'
import { SummaryCards } from '@/admin/summary-cards'
import { TopMealsCard } from '@/admin/top-meals-card'
import { AdminShell } from '@/components/admin-shell'
import { Button } from '@/components/ui/button'
import { isMonthKey, monthKeyToday } from '@/month/month'
import { MONTH_PARAM } from '@/routes'

/*
 * O painel gerencial — a tela-casa da direção (US017, issue #70).
 *
 * É a funcionalidade de destaque do perfil, e o que a define é o que ela **não
 * faz**: não abre mapa, não edita nada, não tem link para dia nenhum. O painel
 * é leitura agregada (RN#1 da US017) e o registro continua sendo das
 * merendeiras — é a mesma linha que a tela Mapas respeita ao reabrir sem
 * corrigir. A guarda de rota já impediria a direção de alcançar o registro; o
 * que esta tela garante é que ela nem seja convidada a tentar.
 *
 * Os dados são de uma consulta só — os dias do mês, os mesmos que a merendeira
 * lê —, então a espera, a falha e o mês vazio valem para a tela inteira, e não
 * cartão por cartão: três esqueletos piscando em sequência para um único
 * pedido seria teatro.
 *
 * O mês aberto vai na barra de endereço, como na visão do mês e pelo mesmo
 * motivo: recarregar com F5 não pode jogar a direção de volta no mês de hoje
 * quando ela estava olhando o mês passado.
 */
export function AdminDashboard() {
  const [params, setParams] = useSearchParams()
  const requested = params.get(MONTH_PARAM)
  const today = monthKeyToday()
  const month = isMonthKey(requested) ? requested : today

  const dashboard = useDashboard(month)

  return (
    <AdminShell
      title={ADMIN_MESSAGES.dashboardTitle}
      subtitle={ADMIN_MESSAGES.dashboardSubtitle}
      actions={
        <MonthPicker
          month={month}
          today={today}
          onChange={(chosen) => setParams({ [MONTH_PARAM]: chosen })}
        />
      }
    >
      {dashboard.loading ? (
        <p
          role="status"
          className="flex items-center gap-2 py-10 text-sm text-muted-foreground"
        >
          <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
          {DASHBOARD_MESSAGES.loading}
        </p>
      ) : dashboard.failed ? (
        <div role="alert" className="flex flex-col gap-3 py-10">
          <p className="flex items-start gap-2 text-sm text-muted-foreground">
            <CircleAlert
              className="mt-0.5 size-4 shrink-0"
              aria-hidden="true"
            />
            {DASHBOARD_MESSAGES.loadFailed}
          </p>
          <Button
            variant="outline"
            className="self-start"
            onClick={dashboard.retry}
          >
            {DASHBOARD_MESSAGES.retry}
          </Button>
        </div>
      ) : (
        <>
          <SummaryCards summary={dashboard.summary} />

          {dashboard.empty ? (
            <p className="py-6 text-sm text-muted-foreground">
              {DASHBOARD_MESSAGES.empty}
            </p>
          ) : (
            /*
             * Sete para cinco, como no desenho da E3: a barra empilhada precisa
             * de largura para a fatia menor não virar um risco, e o ranking é
             * uma lista de nomes curtos. Num monitor estreito ou no celular
             * viram duas linhas, porque espremer as duas quebraria a primeira.
             */
            <div className="grid gap-4 lg:grid-cols-12">
              <div className="lg:col-span-7">
                <AcceptanceCard acceptance={dashboard.acceptance} />
              </div>
              <div className="lg:col-span-5">
                <TopMealsCard meals={dashboard.top} />
              </div>
            </div>
          )}
        </>
      )}
    </AdminShell>
  )
}
