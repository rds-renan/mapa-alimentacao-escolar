import { useState } from 'react'
import { ChevronRight, FileText, List, Menu } from 'lucide-react'
import { Link } from 'react-router'

import { SignOutButton } from '@/auth/sign-out-button'
import { useAuth } from '@/auth/useAuth'
import { Button } from '@/components/ui/button'
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet'
import { ROUTES } from '@/routes'
import { ThemeChoice } from '@/theme/theme-choice'

/*
 * O menu do aplicativo — tela 2a da E3, decisão 9 da mesma etapa.
 *
 * Ele é a porta do que **não** é fluxo diário: documentos gerados, manutenção
 * do catálogo, preferências e sair. Sem ele essas telas não teriam de onde ser
 * abertas — o catálogo, em especial, saiu do caminho do registro na E3 e
 * ficaria inalcançável (US020).
 *
 * Um toque a partir da tela inicial (RNF#1 da US020): o botão está no
 * cabeçalho da visão do mês, e o que ele abre já é o menu inteiro, sem nível
 * intermediário. E ele não interrompe registro em andamento (CA#1 da US020),
 * porque o rascunho do dia mora no aparelho e não depende desta tela estar
 * aberta.
 *
 * O que o menu **não** tem é qualquer caminho para a área da direção (RN#1 da
 * US020): não é uma omissão de interface, é o que as políticas de RLS da E4 já
 * garantem no banco.
 */

interface MenuDestination {
  to: string
  label: string
  icon: typeof FileText
}

const DESTINATIONS: MenuDestination[] = [
  {
    to: ROUTES.generatedDocuments,
    label: 'Documentos gerados',
    icon: FileText,
  },
  { to: ROUTES.foodItems, label: 'Gerenciar gêneros', icon: List },
]

export function AppMenu() {
  const { profile } = useAuth()
  const [open, setOpen] = useState(false)

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button variant="ghost" size="icon" aria-label="Abrir o menu">
          <Menu aria-hidden="true" />
        </Button>
      </SheetTrigger>

      <SheetContent side="left" aria-describedby={undefined}>
        <div className="flex items-center gap-3 border-b border-muted px-4.5 py-5">
          <img src="/logo.png" alt="" className="size-10.5" />
          <div className="flex min-w-0 flex-col">
            <SheetTitle>MAE</SheetTitle>
            <SheetDescription>Mapa da Alimentação Escolar</SheetDescription>
          </div>
        </div>

        <div className="flex flex-col gap-0.5 border-b border-muted px-4.5 py-3.5">
          <span className="text-base font-semibold">{profile?.name}</span>
          <span className="truncate text-xs text-muted-foreground">
            {profile?.email}
          </span>
        </div>

        <nav className="flex flex-col gap-0.5 p-2.5">
          {DESTINATIONS.map(({ to, label, icon: Icon }) => (
            <SheetClose asChild key={to}>
              <Link
                to={to}
                className="flex min-h-touch items-center gap-3 rounded-lg px-3 text-base font-medium hover:bg-muted"
              >
                <Icon
                  className="size-5 shrink-0 text-muted-foreground"
                  aria-hidden="true"
                />
                <span className="flex-1">{label}</span>
                <ChevronRight
                  className="size-4 text-muted-foreground"
                  aria-hidden="true"
                />
              </Link>
            </SheetClose>
          ))}
        </nav>

        {/*
         * O tema (US024). É preferência do aparelho e não tela, então mora
         * aqui dentro do menu e não atrás de um destino: abrir o menu já é ver
         * qual tema está valendo, e trocar não tira ninguém de onde estava.
         */}
        <div className="border-t border-muted p-2.5">
          <ThemeChoice />
        </div>

        <div className="flex flex-col items-start gap-0.5 border-t border-muted p-2.5">
          <SignOutButton />
        </div>
      </SheetContent>
    </Sheet>
  )
}
