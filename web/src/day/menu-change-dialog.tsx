import { useId } from 'react'
import { Info, X } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
} from '@/components/ui/sheet'
import { Textarea } from '@/components/ui/textarea'
import type { MealType, MenuChangePayload } from '@/local/day'
import { filled } from '@/month/month'

import { FoodItemList, type FoodItemActions } from './food-item-list'
import { MENU_CHANGE_MESSAGES, mealSubtitle } from './messages'

/*
 * A alteração do cardápio — tela 3a (US002).
 *
 * O que ela registra aqui é **o que entrou no lugar**, e só: os gêneros com as
 * suas quantidades e o motivo em texto livre. Não há campo para o item que
 * saiu, porque o formulário oficial não o pede em lugar nenhum — e a refeição
 * lá atrás continua sendo o cardápio previsto, que é o que dá sentido à
 * justificativa (decisão 8 da E3, decisão 7 da E4). É por isso que o aviso do
 * alto existe: sem ele, a tela convidaria a reescrever o cardápio.
 *
 * Há no máximo uma alteração por refeição: a justificativa cobre a modificação
 * inteira e os gêneros são uma lista, então duas trocas no mesmo almoço são um
 * registro só (RN#2 da US002).
 *
 * Os botões do rodapé não são um "salvar" — não existe salvar neste aplicativo
 * (decisão 3 da E3). Cada tecla daqui já está gravada no aparelho antes de ela
 * confirmar; o que os dois botões decidem é se a alteração **fica**. Enquanto
 * faltar o motivo ou o gênero, a fila segura o dia no aparelho em vez de
 * mandá-lo para uma recusa certa, e as duas linhas de "o que falta" dizem por
 * quê.
 */
export function MenuChangeDialog({
  open,
  type,
  mapDate,
  change,
  readOnly,
  actions,
  onReasonChange,
  onRemove,
  onCancel,
  onConfirm,
}: {
  open: boolean
  type: MealType
  mapDate: string
  change: MenuChangePayload | null
  readOnly: boolean
  actions: FoodItemActions
  onReasonChange(reason: string): void
  onRemove(): void
  onCancel(): void
  onConfirm(): void
}) {
  const reasonId = useId()
  const itemsId = useId()
  const missingItemsId = useId()
  const missingReasonId = useId()

  const items = change?.food_items ?? []
  const reason = change?.reason ?? ''
  const started = items.length > 0 || filled(reason)
  const missingItems = started && items.length === 0
  const missingReason = started && !filled(reason)

  /*
   * A sugestão preenche o campo vazio e troca a sugestão anterior — é o que
   * "reduzir digitação" quer dizer (RNF#1 da US002). O que ela escreveu com as
   * próprias palavras não é apagado por um toque: aí a sugestão entra depois
   * do que já está lá.
   */
  function suggest(text: string) {
    const current = reason.trim()
    const preset = MENU_CHANGE_MESSAGES.reasonSuggestions.some(
      (one) => one === current
    )

    onReasonChange(current === '' || preset ? text : `${current} ${text}`)
  }

  return (
    <Sheet
      open={open}
      // Fechar pela tecla Esc, pelo fundo ou pelo X é confirmar: o que está
      // escrito já está gravado, e desfazer por acidente seria a surpresa.
      onOpenChange={(next) => {
        if (!next) onConfirm()
      }}
    >
      <SheetContent side="full" className="gap-0 bg-background">
        <header className="flex items-start gap-2 border-b border-border bg-card px-4 py-2.5">
          <div className="flex min-w-0 flex-1 flex-col gap-0.5 py-1.5">
            <SheetTitle>{MENU_CHANGE_MESSAGES.title}</SheetTitle>
            <SheetDescription>{mealSubtitle(type, mapDate)}</SheetDescription>
          </div>

          <Button
            variant="ghost"
            size="icon"
            aria-label={MENU_CHANGE_MESSAGES.close}
            onClick={onConfirm}
          >
            <X aria-hidden="true" />
          </Button>
        </header>

        <div className="flex flex-1 flex-col gap-4 px-4 py-4">
          <p className="flex items-start gap-2 rounded-lg border border-accent-border bg-accent px-3.5 py-3 text-xs leading-relaxed text-accent-foreground">
            <Info className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
            {MENU_CHANGE_MESSAGES.notice(type)}
          </p>

          <div className="flex flex-col gap-2">
            <span id={itemsId} className="text-sm font-medium">
              {MENU_CHANGE_MESSAGES.itemsLabel}
            </span>
            <div aria-labelledby={itemsId} role="group">
              <FoodItemList
                items={items}
                readOnly={readOnly}
                actions={actions}
              />
            </div>
            {missingItems ? (
              <span
                id={missingItemsId}
                className="text-xs text-muted-foreground"
              >
                {MENU_CHANGE_MESSAGES.itemsMissing}
              </span>
            ) : null}
          </div>

          <div className="flex flex-col gap-2">
            <Label htmlFor={reasonId} className="text-sm text-foreground">
              {MENU_CHANGE_MESSAGES.reasonLabel}
            </Label>
            <Textarea
              id={reasonId}
              rows={3}
              disabled={readOnly}
              aria-describedby={missingReason ? missingReasonId : undefined}
              placeholder={MENU_CHANGE_MESSAGES.reasonPlaceholder}
              value={reason}
              onChange={(event) => onReasonChange(event.target.value)}
            />
            {missingReason ? (
              <span
                id={missingReasonId}
                className="text-xs text-muted-foreground"
              >
                {MENU_CHANGE_MESSAGES.reasonMissing}
              </span>
            ) : null}

            {readOnly ? null : (
              <div className="flex flex-wrap gap-2">
                {MENU_CHANGE_MESSAGES.reasonSuggestions.map((one) => (
                  <Button
                    key={one}
                    type="button"
                    size="sm"
                    variant="outline"
                    onClick={() => suggest(one)}
                    className="rounded-full font-normal"
                  >
                    {one}
                  </Button>
                ))}
              </div>
            )}
          </div>

          <p className="flex items-start gap-2 rounded-lg bg-muted px-3.5 py-3 text-xs leading-relaxed text-muted-foreground">
            <Info className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
            {MENU_CHANGE_MESSAGES.document}
          </p>

          {/*
           * A saída de quem registrou uma alteração por engano. Não está no
           * desenho da E3, e entrou porque sem ela o único caminho de volta
           * seria tirar os gêneros um a um e apagar o motivo — três gestos e
           * nenhuma pista de que o conjunto deles é "não houve troca".
           */}
          {started && !readOnly ? (
            <Button
              type="button"
              variant="destructive"
              onClick={onRemove}
              className="self-start"
            >
              {MENU_CHANGE_MESSAGES.remove}
            </Button>
          ) : null}
        </div>

        <footer
          className={`sticky bottom-0 grid gap-2.5 border-t border-border bg-card px-4 pt-3 pb-4 ${
            readOnly ? 'grid-cols-1' : 'grid-cols-2'
          }`}
        >
          {readOnly ? null : (
            <Button type="button" variant="outline" onClick={onCancel}>
              {MENU_CHANGE_MESSAGES.cancel}
            </Button>
          )}
          <Button type="button" onClick={onConfirm}>
            {readOnly
              ? MENU_CHANGE_MESSAGES.done
              : MENU_CHANGE_MESSAGES.confirm}
          </Button>
        </footer>
      </SheetContent>
    </Sheet>
  )
}
