import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { monthLabel, type MonthKey } from '@/month/month'

import { listedMonths } from './dashboard'
import { DASHBOARD_MESSAGES } from './messages'

/*
 * O seletor de mês do painel (CA#4 da US017).
 *
 * É um menu suspenso, e não as setas ‹ › da visão do mês, porque as duas telas
 * navegam o tempo por motivos diferentes: a merendeira anda de mês em mês, a
 * partir de hoje, conferindo o que falta; a direção pula para um mês qualquer
 * do ano para comparar. Sete toques numa seta para chegar em fevereiro é o
 * gesto errado para a segunda pergunta.
 *
 * O nome do mês é o próprio valor selecionado — não há um rótulo visível ao
 * lado. `aria-label` carrega para o leitor de tela o que a posição na tela
 * carrega para quem a enxerga.
 */
export function MonthPicker({
  month,
  today,
  onChange,
}: {
  month: MonthKey
  today: MonthKey
  onChange(month: MonthKey): void
}) {
  const months = listedMonths(month, today)

  return (
    <Select value={month} onValueChange={onChange}>
      <SelectTrigger aria-label={DASHBOARD_MESSAGES.monthLabel}>
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        {months.map((option) => (
          <SelectItem key={option} value={option}>
            {monthLabel(option)}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}
