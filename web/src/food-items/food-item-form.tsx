import { useEffect, useId, useRef } from 'react'
import { CircleAlert, LoaderCircle, X } from 'lucide-react'

import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

import { UNIT_SUGGESTIONS, type CatalogItem } from './catalog'
import { canSave, type FoodItemDraft } from './form'
import { CATALOG_MESSAGES, duplicateLabel } from './messages'

/*
 * O cartão do desenho da tela 4 — e ele é um só.
 *
 * "Novo gênero" e "editar gênero" são o mesmo formulário: tocar uma linha da
 * lista carrega o gênero aqui, e o botão "Adicionar ao catálogo" dá lugar a
 * dois lado a lado, desativar e salvar. Dois formulários na mesma tela, ou uma
 * folha por cima só para editar três campos, custariam mais tela e mais gesto
 * para fazer o que este cartão já faz.
 *
 * A unidade é campo de texto com as seis sugestões da E3 acima dele: o caso
 * comum continua sendo um toque, e o incomum — "bandeja", "fardo" — não
 * precisa de porta separada. É o que a decisão 8 da E4 quer dizer com texto
 * livre, e é esta tela que abre esse leque; a folha do registro (3b) fica com
 * as seis, porque lá o teclado no meio de uma refeição é que seria o custo.
 */
export function FoodItemForm({
  draft,
  editing,
  duplicate,
  warnUnitChange,
  saving,
  failed,
  onChange,
  onSubmit,
  onCancel,
  onToggleActive,
}: {
  draft: FoodItemDraft
  /** O gênero da lista que está no cartão, ou nulo quando é um novo. */
  editing: CatalogItem | null
  /** O homônimo que já está no catálogo, que impede a gravação. */
  duplicate: CatalogItem | null
  warnUnitChange: boolean
  saving: boolean
  failed: boolean
  onChange(draft: FoodItemDraft): void
  onSubmit(): void
  onCancel(): void
  onToggleActive(): void
}) {
  const nameId = useId()
  const unitId = useId()
  const suggestionsId = useId()
  const card = useRef<HTMLFormElement>(null)
  const nameInput = useRef<HTMLInputElement>(null)

  /*
   * A lista fica abaixo do cartão, então tocar um gênero lá embaixo carregaria
   * o formulário fora da tela — pareceria que o toque não fez nada. O foco no
   * nome resolve o mesmo para quem navega por teclado e leitor de tela.
   */
  useEffect(() => {
    if (draft.id === null) return

    card.current?.scrollIntoView?.({ block: 'nearest' })
    nameInput.current?.focus()
  }, [draft.id])

  const blocked = duplicate !== null

  return (
    <form
      ref={card}
      noValidate
      onSubmit={(event) => {
        event.preventDefault()
        onSubmit()
      }}
      className="flex flex-col gap-3.5 rounded-xl border border-accent-border bg-accent p-3.5"
    >
      <div className="flex items-center gap-2">
        <span className="flex-1 text-sm font-semibold">
          {editing ? CATALOG_MESSAGES.editTitle : CATALOG_MESSAGES.newTitle}
        </span>

        {editing ? (
          <Button
            type="button"
            variant="ghost"
            size="icon"
            aria-label={CATALOG_MESSAGES.cancelEdit}
            onClick={onCancel}
          >
            <X aria-hidden="true" />
          </Button>
        ) : null}
      </div>

      <div className="flex flex-col gap-1.5">
        <Label htmlFor={nameId}>{CATALOG_MESSAGES.nameLabel}</Label>
        <Input
          id={nameId}
          ref={nameInput}
          value={draft.name}
          placeholder={CATALOG_MESSAGES.namePlaceholder}
          aria-invalid={blocked}
          onChange={(event) => onChange({ ...draft, name: event.target.value })}
        />
        {duplicate ? (
          <FormMessage>
            {duplicateLabel(duplicate.name, duplicate.active)}
          </FormMessage>
        ) : null}
      </div>

      <div className="flex flex-col gap-2">
        <Label htmlFor={unitId}>{CATALOG_MESSAGES.unitLabel}</Label>
        <Input
          id={unitId}
          value={draft.unit}
          placeholder={CATALOG_MESSAGES.unitPlaceholder}
          aria-describedby={suggestionsId}
          onChange={(event) => onChange({ ...draft, unit: event.target.value })}
        />

        <div
          id={suggestionsId}
          role="group"
          aria-label={CATALOG_MESSAGES.unitHint}
          className="flex flex-wrap gap-2"
        >
          {UNIT_SUGGESTIONS.map((one) => (
            <Button
              key={one}
              type="button"
              size="sm"
              variant={draft.unit.trim() === one ? 'default' : 'outline'}
              aria-pressed={draft.unit.trim() === one}
              onClick={() => onChange({ ...draft, unit: one })}
              className="rounded-full"
            >
              {one}
            </Button>
          ))}
        </div>

        {/*
         * O aviso da consequência retroativa: a unidade mora no catálogo, e
         * `meal_food_item` guarda só a quantidade — trocá-la reescreve o que
         * os dias já registrados dizem. Não é proibição, é o que ela precisa
         * saber para decidir, e por isso aparece no lugar onde ela está
         * decidindo.
         */}
        {warnUnitChange ? (
          <p className="flex items-start gap-2 text-sm text-muted-foreground">
            <CircleAlert
              className="mt-0.5 size-4 shrink-0"
              aria-hidden="true"
            />
            <span>{CATALOG_MESSAGES.unitChanged}</span>
          </p>
        ) : null}
      </div>

      {failed ? <FormMessage>{CATALOG_MESSAGES.saveFailed}</FormMessage> : null}

      {editing ? (
        <div className="flex gap-2.5">
          <Button
            type="button"
            variant="outline"
            className="flex-1"
            onClick={onToggleActive}
          >
            {editing.active
              ? CATALOG_MESSAGES.deactivate
              : CATALOG_MESSAGES.reactivate}
          </Button>
          <Button
            type="submit"
            className="flex-1"
            disabled={!canSave(draft) || blocked || saving}
          >
            {saving ? (
              <LoaderCircle className="animate-spin" aria-hidden="true" />
            ) : null}
            {saving ? CATALOG_MESSAGES.saving : CATALOG_MESSAGES.save}
          </Button>
        </div>
      ) : (
        <Button type="submit" disabled={!canSave(draft) || blocked || saving}>
          {saving ? (
            <LoaderCircle className="animate-spin" aria-hidden="true" />
          ) : null}
          {saving ? CATALOG_MESSAGES.saving : CATALOG_MESSAGES.add}
        </Button>
      )}
    </form>
  )
}
