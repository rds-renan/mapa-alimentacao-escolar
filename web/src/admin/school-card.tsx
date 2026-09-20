import { useState } from 'react'
import { LoaderCircle } from 'lucide-react'

import { FormMessage } from '@/components/form-message'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

import { SCHOOL_MESSAGES } from './messages'
import { useSaveSchool, useSchool, type School } from './queries'

/*
 * Os dados institucionais da escola (CA#2 da US015).
 *
 * São três campos e nenhum deles é decoração: o nome, o município e o ano
 * letivo entram no cabeçalho de todo documento gerado. Editáveis porque o
 * formato do documento muda por decisão externa, e absorver essa mudança aqui
 * é o que mantém o fluxo das merendeiras intocado.
 *
 * O ano letivo é número inteiro e o campo é numérico — mesma decisão das
 * quantidades do registro: teclado numérico, sem fração.
 */
export function SchoolCard() {
  const school = useSchool()
  const save = useSaveSchool()

  /*
   * O que a direção mudou, e só isso — o formulário é o que veio do servidor
   * com essas mudanças por cima.
   *
   * Guardar o delta, e não uma cópia da linha inteira, é o que faz uma
   * releitura em segundo plano (o `refetchOnReconnect`, quando a internet
   * volta) atualizar o que ela não tocou sem apagar o que ela está digitando.
   * É também o que dispensa copiar o servidor para o estado num efeito.
   */
  const [edits, setEdits] = useState<Partial<School>>({})
  const [done, setDone] = useState(false)

  const draft = school.data ? { ...school.data, ...edits } : null

  function change(field: keyof School, value: string | number) {
    setEdits((current) => ({ ...current, [field]: value }))
    setDone(false)
    save.reset()
  }

  function submit(event: React.FormEvent) {
    event.preventDefault()
    if (!draft || !complete(draft) || save.isPending) return

    save.mutate(draft, {
      onSuccess: () => {
        // Salvo: o servidor passa a ser a verdade de novo, e não há mais
        // nenhuma mudança pendente por cima dele.
        setEdits({})
        setDone(true)
      },
    })
  }

  return (
    <section
      aria-labelledby="school-title"
      className="flex flex-col gap-3.5 rounded-xl border border-border bg-card p-4"
    >
      <hgroup className="flex flex-col gap-0.5">
        <h2 id="school-title" className="text-base font-semibold">
          {SCHOOL_MESSAGES.title}
        </h2>
        <p className="text-xs text-muted-foreground">
          {SCHOOL_MESSAGES.subtitle}
        </p>
      </hgroup>

      {school.isPending ? (
        <p
          role="status"
          className="flex items-center gap-2 py-2 text-sm text-muted-foreground"
        >
          <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
          {SCHOOL_MESSAGES.loading}
        </p>
      ) : school.isError || !draft ? (
        <div role="alert" className="flex flex-col items-start gap-3">
          <FormMessage>{SCHOOL_MESSAGES.loadFailed}</FormMessage>
          <Button variant="outline" onClick={() => void school.refetch()}>
            {SCHOOL_MESSAGES.retry}
          </Button>
        </div>
      ) : (
        <form onSubmit={submit} className="flex flex-col gap-3.5">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="school-name">{SCHOOL_MESSAGES.nameLabel}</Label>
            <Input
              id="school-name"
              value={draft.name}
              placeholder={SCHOOL_MESSAGES.namePlaceholder}
              onChange={(event) => change('name', event.target.value)}
            />
          </div>

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="school-city">{SCHOOL_MESSAGES.cityLabel}</Label>
              <Input
                id="school-city"
                value={draft.city}
                placeholder={SCHOOL_MESSAGES.cityPlaceholder}
                onChange={(event) => change('city', event.target.value)}
              />
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="school-year">{SCHOOL_MESSAGES.yearLabel}</Label>
              <Input
                id="school-year"
                type="number"
                inputMode="numeric"
                min={2000}
                max={2100}
                value={Number.isNaN(draft.school_year) ? '' : draft.school_year}
                onChange={(event) =>
                  change('school_year', Number.parseInt(event.target.value, 10))
                }
              />
            </div>
          </div>

          {!complete(draft) ? (
            <FormMessage>{SCHOOL_MESSAGES.incomplete}</FormMessage>
          ) : null}
          {save.isError ? (
            <FormMessage>{save.error.message}</FormMessage>
          ) : null}
          {done ? (
            <FormMessage kind="success">{SCHOOL_MESSAGES.saved}</FormMessage>
          ) : null}

          <Button
            type="submit"
            className="self-start"
            disabled={!complete(draft) || save.isPending}
          >
            {save.isPending ? (
              <LoaderCircle className="animate-spin" aria-hidden="true" />
            ) : null}
            {save.isPending ? SCHOOL_MESSAGES.saving : SCHOOL_MESSAGES.save}
          </Button>
        </form>
      )}
    </section>
  )
}

/** O banco recusa nome em branco e ano fora de 2000–2100; a tela avisa antes. */
function complete(school: School): boolean {
  return (
    school.name.trim() !== '' &&
    school.city.trim() !== '' &&
    Number.isInteger(school.school_year) &&
    school.school_year >= 2000 &&
    school.school_year <= 2100
  )
}
