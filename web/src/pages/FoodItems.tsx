import { useMemo, useState } from 'react'
import {
  ArrowLeft,
  ChevronDown,
  ChevronRight,
  CircleAlert,
  LoaderCircle,
  Search,
} from 'lucide-react'
import { Link } from 'react-router'

import { useAuth } from '@/auth/useAuth'
import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import type { CatalogItem } from '@/food-items/catalog'
import { FoodItemForm } from '@/food-items/food-item-form'
import {
  canSave,
  draftOf,
  duplicateOf,
  EMPTY_DRAFT,
  sections,
  unitChanged,
  type FoodItemDraft,
} from '@/food-items/form'
import {
  addedLabel,
  CATALOG_MESSAGES,
  deactivatedLabel,
  editLabel,
  inactiveTitle,
  reactivatedLabel,
  savedLabel,
} from '@/food-items/messages'
import { useCatalog, useCatalogMutations } from '@/food-items/queries'
import { ROUTES } from '@/routes'

/*
 * A manutenção do catálogo de gêneros — tela 4 da E3 (US009).
 *
 * É a tela que sustenta a consistência das quantidades: a unidade mora aqui, e
 * é daqui que o registro do dia a lê. Não é do caminho diário — quem a alcança
 * é o menu (decisão 9 da E3), porque cadastrar gênero no meio de uma refeição
 * já acontece na folha 3b, sem sair do dia.
 *
 * A gravação vai direto ao servidor, sem a fila do aparelho: a fila existe
 * para o mapa do dia, que é o que não pode se perder (decisão 2 da E5).
 *
 * Desativar não pede confirmação. A única confirmação do fluxo da merendeira é
 * a de gerar o documento, porque ela é irreversível (decisão 11 da E3); esta
 * tem volta na seção de baixo, e confirmar tudo é o caminho para ela deixar de
 * ler as confirmações.
 */
export function FoodItems() {
  const { profile } = useAuth()
  const catalog = useCatalog()
  const { save, toggle } = useCatalogMutations(profile?.school_id)

  const [search, setSearch] = useState('')
  const [draft, setDraft] = useState<FoodItemDraft>(EMPTY_DRAFT)
  const [showInactive, setShowInactive] = useState(false)
  /** O que acabou de acontecer, dito no lugar onde aconteceu. */
  const [done, setDone] = useState<string | null>(null)

  const items = useMemo(() => catalog.data ?? [], [catalog.data])
  const { active, inactive } = useMemo(
    () => sections(items, search),
    [items, search]
  )

  const editing = items.find((item) => item.id === draft.id) ?? null
  const duplicate = duplicateOf(draft, items)

  function edit(item: CatalogItem) {
    setDraft(draftOf(item))
    setDone(null)
    save.reset()
  }

  function cancel() {
    setDraft(EMPTY_DRAFT)
    setDone(null)
    save.reset()
  }

  function submit() {
    if (!canSave(draft) || duplicate) return

    const creating = draft.id === null
    const name = draft.name.trim()

    save.mutate(draft, {
      onSuccess: () => {
        setDraft(EMPTY_DRAFT)
        setDone(creating ? addedLabel(name) : savedLabel(name))
      },
    })
  }

  function toggleActive() {
    if (!editing) return

    const next = !editing.active
    toggle.mutate(
      { id: editing.id, active: next },
      {
        onSuccess: () => {
          setDraft(EMPTY_DRAFT)
          setDone(
            next
              ? reactivatedLabel(editing.name)
              : deactivatedLabel(editing.name)
          )
          // Desativou: a seção de baixo é onde o gênero está agora, e é para
          // lá que ela vai olhar se tiver sido engano.
          if (!next) setShowInactive(true)
        },
      }
    )
  }

  return (
    <div className="flex min-h-dvh flex-col bg-background">
      <header className="sticky top-0 z-10 border-b border-border bg-card">
        <div className="mx-auto flex w-full max-w-screen items-center gap-1 p-2">
          <Button variant="ghost" size="icon" asChild>
            <Link to={ROUTES.cookHome} aria-label={CATALOG_MESSAGES.back}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>

          <h1 className="flex flex-1 flex-col gap-px overflow-hidden">
            <span className="truncate text-base font-semibold tracking-tight">
              {CATALOG_MESSAGES.title}
            </span>
            <span className="truncate text-xs font-normal text-muted-foreground">
              {CATALOG_MESSAGES.subtitle}
            </span>
          </h1>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-screen flex-1 flex-col gap-3.5 px-4 pt-3.5 pb-6">
        <div className="relative">
          <Search
            aria-hidden="true"
            className="pointer-events-none absolute top-1/2 left-3 size-4.5 -translate-y-1/2 text-muted-foreground"
          />
          <Input
            type="search"
            aria-label={CATALOG_MESSAGES.search}
            placeholder={CATALOG_MESSAGES.search}
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            className="pl-10"
          />
        </div>

        <FoodItemForm
          draft={draft}
          editing={editing}
          duplicate={duplicate}
          warnUnitChange={unitChanged(draft, items)}
          saving={save.isPending || toggle.isPending}
          failed={save.isError || toggle.isError}
          onChange={setDraft}
          onSubmit={submit}
          onCancel={cancel}
          onToggleActive={toggleActive}
        />

        {done ? <FormMessage kind="success">{done}</FormMessage> : null}

        {catalog.isPending ? (
          <p
            role="status"
            className="flex flex-1 items-center justify-center gap-2 text-base text-muted-foreground"
          >
            <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
            {CATALOG_MESSAGES.loading}
          </p>
        ) : catalog.isError ? (
          /*
           * A web não promete navegar sem internet (decisão 2 da E5). O
           * cartão de cima continua de pé de propósito: o que falhou foi a
           * lista, e o cadastro tenta o servidor por conta própria.
           */
          <div
            role="alert"
            className="flex flex-col items-center gap-3 py-6 text-center"
          >
            <CircleAlert
              className="size-6 text-muted-foreground"
              aria-hidden="true"
            />
            <p className="text-base text-muted-foreground">
              {CATALOG_MESSAGES.loadFailed}
            </p>
            <Button variant="outline" onClick={() => void catalog.refetch()}>
              {CATALOG_MESSAGES.retry}
            </Button>
          </div>
        ) : (
          <>
            {/*
             * Duas listas na mesma tela, e um leitor de tela precisa saber em
             * qual delas está: a de trabalho e a dos que saíram das sugestões.
             */}
            <section
              aria-label={CATALOG_MESSAGES.listTitle}
              className="flex flex-col gap-2"
            >
              <h2 className="pt-0.5 text-xs font-semibold text-secondary-foreground">
                {CATALOG_MESSAGES.listTitle}
              </h2>

              {items.length === 0 ? (
                <p className="text-base text-muted-foreground">
                  {CATALOG_MESSAGES.empty}
                </p>
              ) : active.length === 0 ? (
                <p className="text-base text-muted-foreground">
                  {CATALOG_MESSAGES.noResults}
                </p>
              ) : (
                <div className="flex flex-col overflow-hidden rounded-xl border border-border bg-card">
                  {active.map((item) => (
                    <CatalogRow
                      key={item.id}
                      item={item}
                      selected={item.id === draft.id}
                      onEdit={() => edit(item)}
                    />
                  ))}
                </div>
              )}
            </section>

            {/*
             * Os desativados não somem da tela: o gênero sai das sugestões,
             * não do catálogo (CA#3 da US009), e desativar por engano precisa
             * ter volta. Recolhidos porque não são a lista de trabalho.
             */}
            {inactive.length > 0 ? (
              <section
                aria-label={inactiveTitle(inactive.length)}
                className="flex flex-col gap-2"
              >
                <button
                  type="button"
                  aria-expanded={showInactive}
                  onClick={() => setShowInactive((one) => !one)}
                  className="flex min-h-touch items-center gap-1.5 text-xs font-semibold text-secondary-foreground"
                >
                  {showInactive ? (
                    <ChevronDown className="size-4" aria-hidden="true" />
                  ) : (
                    <ChevronRight className="size-4" aria-hidden="true" />
                  )}
                  {inactiveTitle(inactive.length)}
                </button>

                {showInactive ? (
                  <div className="flex flex-col overflow-hidden rounded-xl border border-border bg-card">
                    {inactive.map((item) => (
                      <CatalogRow
                        key={item.id}
                        item={item}
                        selected={item.id === draft.id}
                        onEdit={() => edit(item)}
                      />
                    ))}
                  </div>
                ) : null}
              </section>
            ) : null}
          </>
        )}
      </main>
    </div>
  )
}

/** Uma linha da lista: o nome, a unidade e o toque que carrega o cartão. */
function CatalogRow({
  item,
  selected,
  onEdit,
}: {
  item: CatalogItem
  selected: boolean
  onEdit(): void
}) {
  return (
    <button
      type="button"
      aria-label={editLabel(item.name)}
      onClick={onEdit}
      className={`flex min-h-touch items-center gap-3 border-b border-muted px-3.5 py-2 text-left last:border-b-0 hover:bg-muted ${
        selected ? 'bg-muted' : ''
      } ${item.active ? '' : 'text-muted-foreground'}`}
    >
      <span className="flex-1 truncate text-sm font-medium">{item.name}</span>
      <span className="shrink-0 rounded-full border border-border bg-muted px-2.5 py-0.5 text-2xs font-medium text-muted-foreground">
        {item.default_unit}
      </span>
      <ChevronRight
        className="size-4 shrink-0 text-muted-foreground"
        aria-hidden="true"
      />
    </button>
  )
}
