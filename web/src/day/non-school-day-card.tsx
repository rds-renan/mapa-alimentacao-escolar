import { useId } from 'react'

import { Card, CardContent } from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import { Textarea } from '@/components/ui/textarea'
import { filled } from '@/month/month'

import { DAY_MESSAGES } from './messages'

/*
 * O dia não letivo (US006).
 *
 * Fica na mesma tela do registro, no alto (RNF#1): conselho de classe, feriado
 * e recesso são dias do mapa como os outros, só que com uma observação no
 * lugar das refeições. Marcar recolhe o resto da tela e deixa só o motivo — um
 * dia é letivo ou não letivo, nunca os dois (RN#1).
 *
 * A observação é o que falta para o dia poder subir, e a linha embaixo do
 * campo diz isso enquanto ela não escreveu. Não é acusação de campo vazio: o
 * que já estava digitado continua guardado, e o dia sobe assim que o motivo
 * existir.
 */
export function NonSchoolDayCard({
  nonSchoolDay,
  note,
  readOnly,
  onToggle,
  onNoteChange,
}: {
  nonSchoolDay: boolean
  note: string | null
  readOnly: boolean
  onToggle(nonSchoolDay: boolean): void
  onNoteChange(note: string): void
}) {
  const switchId = useId()
  const hintId = useId()
  const noteId = useId()
  const missingId = useId()
  const missing = nonSchoolDay && !filled(note)

  return (
    <>
      <Card size="sm">
        <CardContent className="flex items-center gap-3">
          <div className="flex flex-1 flex-col gap-0.5">
            <Label htmlFor={switchId} className="text-base font-medium">
              {DAY_MESSAGES.nonSchoolDayTitle}
            </Label>
            <span id={hintId} className="text-xs text-muted-foreground">
              {DAY_MESSAGES.nonSchoolDayHint}
            </span>
          </div>

          <Switch
            id={switchId}
            aria-describedby={hintId}
            checked={nonSchoolDay}
            disabled={readOnly}
            onCheckedChange={onToggle}
          />
        </CardContent>
      </Card>

      {nonSchoolDay ? (
        <Card>
          <CardContent className="flex flex-col gap-2">
            <Label htmlFor={noteId} className="text-sm text-foreground">
              {DAY_MESSAGES.noteLabel}
            </Label>
            <Textarea
              id={noteId}
              rows={4}
              disabled={readOnly}
              aria-describedby={missing ? missingId : undefined}
              placeholder={DAY_MESSAGES.notePlaceholder}
              value={note ?? ''}
              onChange={(event) => onNoteChange(event.target.value)}
            />
            {missing ? (
              <span id={missingId} className="text-xs text-muted-foreground">
                {DAY_MESSAGES.noteMissing}
              </span>
            ) : null}
          </CardContent>
        </Card>
      ) : null}
    </>
  )
}
