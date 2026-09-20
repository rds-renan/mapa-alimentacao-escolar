import { useMemo, useState } from 'react'
import {
  Check,
  ChevronLeft,
  CircleAlert,
  FileText,
  Info,
  LoaderCircle,
  Lock,
  Upload,
  WifiOff,
} from 'lucide-react'
import { Link, useNavigate, useSearchParams } from 'react-router'

import { Button } from '@/components/ui/button'
import { DayOptionRow } from '@/documents/day-option-row'
import {
  ConfirmGenerationDialog,
  GenerationFailureDialog,
} from '@/documents/generate-dialogs'
import {
  MODE_LABELS,
  SELECTION_MESSAGES,
  selectionLabel,
  unsentNotice,
} from '@/documents/messages'
import { MissingNotice } from '@/documents/missing-notice'
import { useGenerateDocument, useGenerationInFlight } from '@/documents/queries'
import {
  closable,
  missingDays,
  periodLabel,
  toOptions,
  type DayOption,
  type SelectionMode,
} from '@/documents/selection'
import { useOnline } from '@/documents/use-online'
import { useSync } from '@/local/useSync'
import {
  groupIntoWeeks,
  isMonthKey,
  listedDays,
  monthKeyToday,
  monthLabel,
  monthName,
} from '@/month/month'
import { useMonth } from '@/month/queries'
import { MONTH_PARAM, ROUTES } from '@/routes'

/*
 * A seleção de mapas — tela 5 da E3 (US013), e a antessala do único passo
 * irreversível do fluxo da merendeira.
 *
 * O desenho da E3 tem três botões no alto, e eles são **modos**, não ações: a
 * tela foi desenhada com "Escolher dias" aberto, e os outros dois nunca
 * chegaram a ser desenhados. Cada um responde a uma intenção diferente —
 * fechar o mês, fechar uma semana, escolher dias avulsos —, e a tela abre no
 * primeiro, porque a prestação de contas é mensal e o mês inteiro tem de sair
 * em poucos toques (RNF#1 da US013). Abrindo assim, são zero.
 *
 * A regra que atravessa a tela toda: **mapa pendente não entra em documento.**
 * O servidor aceitaria — sairia como formulário em branco naquela refeição —,
 * e a US012 pedia apenas que os pendentes fossem apontados. A decisão do
 * projeto foi mais dura, e por um motivo de fora do software: o documento vai
 * à prefeitura em papel, e o que vai incompleto volta. Então o atalho que não
 * consegue fechar o período não seleciona nada — ele mostra o que falta, dia
 * por dia, que é a pergunta que a merendeira tem na cabeça quando abre esta
 * tela.
 */

export function SelectMaps() {
  const [params] = useSearchParams()
  const requested = params.get(MONTH_PARAM)
  const month = isMonthKey(requested) ? requested : monthKeyToday()

  const navigate = useNavigate()
  const online = useOnline()
  const { flush } = useSync()
  const { byDate, loading, failed, retry } = useMonth(month)

  const [mode, setMode] = useState<SelectionMode>('month')
  /*
   * A escolha de cada modo mora em seu próprio lugar, e trocar de modo limpa
   * as duas: são intenções diferentes, e herdar a marcação anterior faria a
   * tela dizer "22 mapas selecionados" logo depois de ela pedir outra coisa.
   */
  const [chosenWeeks, setChosenWeeks] = useState<Set<number>>(new Set())
  const [chosenDays, setChosenDays] = useState<Set<string>>(new Set())
  const [confirming, setConfirming] = useState(false)

  const generate = useGenerateDocument()
  const generating = useGenerationInFlight()

  const { options, weeks } = useMemo(() => {
    const days = listedDays(month, new Set(byDate.keys()))
    const list = toOptions(days, byDate)
    const map = new Map(list.map((option) => [option.date, option]))

    return {
      options: list,
      weeks: groupIntoWeeks(days).map((week) => ({
        ...week,
        options: week.days.map((date) => map.get(date) as DayOption),
      })),
    }
  }, [month, byDate])

  const monthClosable = closable(options)
  const missing = useMemo(() => missingDays(options), [options])
  const unsent = options.filter((option) => option.unsent).length

  const selected = useMemo(() => {
    const eligible = (list: DayOption[]) =>
      list.filter((option) => option.eligible)

    const chosen =
      mode === 'month'
        ? monthClosable
          ? eligible(options)
          : []
        : mode === 'week'
          ? weeks
              .filter((week) => chosenWeeks.has(week.number))
              .flatMap((week) => eligible(week.options))
          : eligible(options).filter((option) => chosenDays.has(option.date))

    return {
      dates: new Set(chosen.map((option) => option.date)),
      ids: chosen.map((option) => option.id as string),
    }
  }, [mode, monthClosable, options, weeks, chosenWeeks, chosenDays])

  function changeMode(next: SelectionMode) {
    setMode(next)
    setChosenWeeks(new Set())
    setChosenDays(new Set())
  }

  function toggle<T>(value: T, set: (next: Set<T>) => void, current: Set<T>) {
    const next = new Set(current)
    if (next.has(value)) next.delete(value)
    else next.add(value)
    set(next)
  }

  function requestGeneration() {
    setConfirming(false)
    generate.mutate(selected.ids, {
      /*
       * Fica na chamada, e não na mutação: se ela saiu da tela no meio, a
       * navegação não deve acontecer por baixo do que ela estiver fazendo. A
       * geração continua — o registro é do servidor, e o documento aparece em
       * Documentos gerados de qualquer jeito.
       *
       * Qual documento acabou de sair vai junto no estado da navegação: é o
       * que faz o primeiro cartão de lá abrir como a tela 6 da E3, com a
       * confirmação e o aviso do bloqueio. Quem chega a Documentos gerados
       * por outro caminho vê só a lista, que é o certo.
       */
      onSuccess: (document) =>
        void navigate(ROUTES.generatedDocuments, {
          state: { justGenerated: document.generated_document_id },
        }),
    })
  }

  const monthPath = `${ROUTES.cookHome}?${MONTH_PARAM}=${month}`
  const canGenerate = selected.ids.length > 0 && online && !generating

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="sticky top-0 z-10 border-b border-border bg-card">
        <div className="mx-auto flex w-full max-w-screen items-center gap-1 p-2">
          <Button
            variant="ghost"
            size="icon"
            aria-label={SELECTION_MESSAGES.backToMonth}
            asChild
          >
            <Link to={monthPath}>
              <ChevronLeft aria-hidden="true" />
            </Link>
          </Button>

          <h1 className="flex flex-1 flex-col gap-px overflow-hidden">
            <span className="truncate text-lg font-semibold tracking-tight">
              {SELECTION_MESSAGES.title}
            </span>
            <span className="truncate text-xs font-normal text-muted-foreground">
              Escolha os mapas de {monthLabel(month).toLowerCase()}
            </span>
          </h1>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-screen flex-1 flex-col gap-3.5 px-4 pt-3.5 pb-6">
        {loading ? (
          <p
            role="status"
            className="flex flex-1 items-center justify-center gap-2 text-base text-muted-foreground"
          >
            <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
            {SELECTION_MESSAGES.loading}
          </p>
        ) : failed ? (
          <div
            role="alert"
            className="flex flex-1 flex-col items-center justify-center gap-3 text-center"
          >
            <CircleAlert
              className="size-6 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-base text-muted-foreground">
              {SELECTION_MESSAGES.loadFailed}
            </p>
            <Button variant="outline" onClick={retry}>
              {SELECTION_MESSAGES.retry}
            </Button>
          </div>
        ) : (
          <>
            <div
              role="group"
              aria-label="Como escolher os mapas"
              className="flex gap-2"
            >
              {(['month', 'week', 'days'] as SelectionMode[]).map((one) => (
                <Button
                  key={one}
                  variant={mode === one ? 'default' : 'outline'}
                  aria-pressed={mode === one}
                  className="flex-1 px-2 text-sm"
                  onClick={() => changeMode(one)}
                >
                  {MODE_LABELS[one]}
                </Button>
              ))}
            </div>

            <p className="flex items-start gap-2 rounded-lg bg-muted px-3.5 py-3 text-xs text-muted-foreground">
              <Info className="mt-px size-4 shrink-0" aria-hidden="true" />
              {SELECTION_MESSAGES.singleDocument}
            </p>

            {/*
             * O aviso do que falta só aparece no modo que tenta fechar o mês.
             * Nos outros dois ele seria ruído: a semana diz o que falta no seu
             * próprio cabeçalho, e "escolher dias" é justamente o modo em que
             * o buraco é escolha dela (CA#1 da US013).
             */}
            {mode === 'month' && !monthClosable && missing.length > 0 ? (
              <MissingNotice scope={monthName(month)} missing={missing} />
            ) : null}

            {unsent > 0 ? (
              <div
                role="status"
                className="flex flex-col items-start gap-2 rounded-lg border border-border bg-muted px-3.5 py-3 text-xs text-muted-foreground"
              >
                <p className="flex items-start gap-2">
                  <Upload
                    className="mt-px size-4 shrink-0"
                    aria-hidden="true"
                  />
                  {unsentNotice(unsent)}
                </p>
                <Button
                  variant="outline"
                  size="sm"
                  className="ml-6"
                  onClick={() => void flush()}
                >
                  {SELECTION_MESSAGES.sendNow}
                </Button>
              </div>
            ) : null}

            {weeks.length === 0 ? (
              <p className="text-base text-muted-foreground">
                {SELECTION_MESSAGES.empty}
              </p>
            ) : null}

            {weeks.map((week) => {
              const weekClosable = closable(week.options)
              const weekMissing = missingDays(week.options).length
              const weekChosen = chosenWeeks.has(week.number)

              return (
                <section key={week.number} className="flex flex-col gap-2">
                  {mode === 'week' ? (
                    <button
                      type="button"
                      role="checkbox"
                      aria-checked={weekChosen}
                      aria-label={`${week.label}${
                        weekClosable
                          ? ''
                          : `, ${weekMissing === 1 ? 'falta 1 dia' : `faltam ${weekMissing} dias`}`
                      }`}
                      disabled={!weekClosable}
                      onClick={() =>
                        toggle(week.number, setChosenWeeks, chosenWeeks)
                      }
                      className="flex min-h-touch items-center gap-2.5 rounded-lg px-1 text-left not-disabled:hover:bg-muted/60 disabled:opacity-60"
                    >
                      <span
                        aria-hidden="true"
                        className={`flex size-5 shrink-0 items-center justify-center rounded border-2 ${
                          weekChosen
                            ? 'border-primary bg-primary text-primary-foreground'
                            : 'border-input bg-card'
                        }`}
                      >
                        {weekChosen ? (
                          <Check className="size-3" strokeWidth={3} />
                        ) : null}
                      </span>
                      <span
                        aria-hidden="true"
                        className="flex-1 text-xs font-semibold text-secondary-foreground"
                      >
                        {week.label}
                      </span>
                      {weekClosable ? null : (
                        <span
                          aria-hidden="true"
                          className="text-xs text-warning"
                        >
                          {weekMissing === 1
                            ? 'falta 1 dia'
                            : `faltam ${weekMissing} dias`}
                        </span>
                      )}
                    </button>
                  ) : (
                    <h2 className="pt-0.5 text-xs font-semibold text-secondary-foreground">
                      {week.label}
                    </h2>
                  )}

                  <div className="flex flex-col overflow-hidden rounded-xl border border-border bg-card">
                    {week.options.map((option) => (
                      <DayOptionRow
                        key={option.date}
                        option={option}
                        selected={selected.dates.has(option.date)}
                        readOnly={mode !== 'days'}
                        onToggle={() =>
                          toggle(option.date, setChosenDays, chosenDays)
                        }
                      />
                    ))}
                  </div>
                </section>
              )
            })}

            <p className="flex items-start gap-2 rounded-lg border border-warning-border bg-warning-subtle px-3.5 py-3 text-xs text-warning">
              <Lock className="mt-px size-4 shrink-0" aria-hidden="true" />
              {SELECTION_MESSAGES.lockWarning}
            </p>
          </>
        )}
      </main>

      <footer className="sticky bottom-0 border-t border-border bg-card">
        <div className="mx-auto flex w-full max-w-screen flex-col gap-2 px-4 pt-3 pb-4">
          {/*
           * Sem rede, o aviso toma o lugar da contagem e o botão fica
           * desabilitado — explicar a espera, em vez de deixar o toque falhar
           * em silêncio (catálogo de avisos da E3).
           */}
          {online ? (
            <span className="text-center text-xs text-muted-foreground">
              {selectionLabel(selected.dates.size)}
            </span>
          ) : (
            <p
              role="status"
              className="flex items-start gap-2 rounded-lg border border-warning-border bg-warning-subtle px-3.5 py-2.5 text-xs text-warning"
            >
              <WifiOff className="mt-px size-4 shrink-0" aria-hidden="true" />
              {SELECTION_MESSAGES.offline}
            </p>
          )}

          <Button
            size="lg"
            className="w-full"
            disabled={!canGenerate}
            onClick={() => setConfirming(true)}
          >
            {generating ? (
              <LoaderCircle className="animate-spin" aria-hidden="true" />
            ) : (
              <FileText aria-hidden="true" />
            )}
            {generating
              ? SELECTION_MESSAGES.generating
              : SELECTION_MESSAGES.generate}
          </Button>
        </div>
      </footer>

      <ConfirmGenerationDialog
        open={confirming}
        period={periodLabel([...selected.dates])}
        count={selected.ids.length}
        onCancel={() => setConfirming(false)}
        onConfirm={requestGeneration}
      />

      <GenerationFailureDialog
        open={generate.isError}
        message={generate.error?.message ?? ''}
        onClose={() => generate.reset()}
        onRetry={requestGeneration}
      />
    </div>
  )
}
