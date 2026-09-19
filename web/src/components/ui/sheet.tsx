import * as React from 'react'
import { cn } from 'cn'
import { Dialog as DialogPrimitive } from 'radix-ui'

/*
 * A folha que entra pela lateral ou por baixo da tela.
 *
 * É o componente do menu (tela 2a da E3), o do "Escolher gênero" (tela 3b),
 * que sobe por baixo, e o da "Alteração do cardápio" (tela 3a), que toma a
 * tela inteira — a mesma peça com outro lado. Vem do shadcn/ui, com os
 * tamanhos ajustados para o alvo de toque de 44 px da decisão 6 da E3: o
 * padrão da biblioteca é de desktop.
 *
 * O lado `full` existe porque a tela 3a é desenhada como uma tela, com
 * cabeçalho e rodapé próprios, mas não é uma tela de fluxo: é uma etapa dentro
 * do registro do dia, e sair dela não pode passar pela navegação do
 * navegador.
 *
 * `full` e `bottom` ficam presos ao **container central** da decisão 1 da E3 —
 * os mesmos 390 px do resto do fluxo da merendeira. Sem isso, a folha que no
 * celular ocupa a tela toda se esticava de ponta a ponta do monitor sobre uma
 * coluna estreita: o mesmo desenho nas duas plataformas não quer dizer o mesmo
 * número de pixels, quer dizer a mesma largura de leitura.
 *
 * A centralização é por margem automática, e não por `translate`: as animações
 * de entrada e saída já usam o `transform` do elemento, e as duas brigariam.
 *
 * `left` e `right` **não** entram nessa conta, e não é esquecimento: o mesmo
 * lado serve ao menu da merendeira e à barra lateral da direção, que é tela de
 * desktop de verdade (decisão 1 da E3 só põe no container o fluxo da
 * merendeira). Prendê-los aos 390 px estreitaria a área do administrador para
 * consertar o que, como barra lateral, já se comporta bem nas duas.
 */

const Sheet = DialogPrimitive.Root
const SheetTrigger = DialogPrimitive.Trigger
const SheetClose = DialogPrimitive.Close

function SheetContent({
  className,
  children,
  side = 'left',
  ...props
}: React.ComponentProps<typeof DialogPrimitive.Content> & {
  side?: 'left' | 'right' | 'bottom' | 'full'
}) {
  return (
    <DialogPrimitive.Portal>
      <DialogPrimitive.Overlay
        data-slot="sheet-overlay"
        className="fixed inset-0 z-50 bg-foreground/45 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:animate-in data-[state=open]:fade-in-0"
      />
      <DialogPrimitive.Content
        data-slot="sheet-content"
        data-side={side}
        className={cn(
          'fixed z-50 flex flex-col overflow-y-auto bg-card text-card-foreground shadow-lg transition ease-in-out data-[state=closed]:animate-out data-[state=closed]:duration-200 data-[state=open]:animate-in data-[state=open]:duration-300',
          side === 'left' &&
            'inset-y-0 left-0 w-80 max-w-[85vw] border-r border-border data-[state=closed]:slide-out-to-left data-[state=open]:slide-in-from-left',
          side === 'right' &&
            'inset-y-0 right-0 w-80 max-w-[85vw] border-l border-border data-[state=closed]:slide-out-to-right data-[state=open]:slide-in-from-right',
          side === 'full' &&
            'inset-0 mx-auto w-full max-w-screen border-x border-border data-[state=closed]:slide-out-to-right data-[state=open]:slide-in-from-right',
          side === 'bottom' &&
            'inset-x-0 bottom-0 mx-auto max-h-[85dvh] w-full max-w-screen rounded-t-2xl border-x border-t border-border data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom',
          className
        )}
        {...props}
      >
        {children}
      </DialogPrimitive.Content>
    </DialogPrimitive.Portal>
  )
}

function SheetTitle({
  className,
  ...props
}: React.ComponentProps<typeof DialogPrimitive.Title>) {
  return (
    <DialogPrimitive.Title
      data-slot="sheet-title"
      className={cn('text-lg leading-snug font-semibold', className)}
      {...props}
    />
  )
}

function SheetDescription({
  className,
  ...props
}: React.ComponentProps<typeof DialogPrimitive.Description>) {
  return (
    <DialogPrimitive.Description
      data-slot="sheet-description"
      className={cn('text-xs text-muted-foreground', className)}
      {...props}
    />
  )
}

export {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetTitle,
  SheetTrigger,
}
