import * as React from 'react'
import { cn } from 'cn'
import { AlertDialog as AlertDialogPrimitive } from 'radix-ui'

import { buttonVariants } from '@/components/ui/button'

/*
 * O diálogo que interrompe e exige uma decisão — a segunda das duas naturezas
 * do catálogo de avisos da E3, ao lado do aviso de passagem, que some sozinho.
 *
 * É `AlertDialog` e não `Dialog` por uma diferença que não é de estilo: ele não
 * fecha ao clicar fora nem ao pressionar Esc sozinho — a saída é sempre um dos
 * dois botões. Só há dois usos assim no aplicativo, e os dois pedem isso: a
 * confirmação antes de gerar, porque o bloqueio dos mapas é irreversível para a
 * merendeira, e o diálogo de falha, que carrega a informação de que nada se
 * perdeu e não pode evaporar num toque distraído.
 *
 * Os botões usam os mesmos tamanhos do resto do fluxo dela: alvo de toque de
 * 44 px (decisão 6 da E3), e não o compacto de desktop da biblioteca.
 */

const AlertDialog = AlertDialogPrimitive.Root

function AlertDialogContent({
  className,
  ...props
}: React.ComponentProps<typeof AlertDialogPrimitive.Content>) {
  return (
    <AlertDialogPrimitive.Portal>
      <AlertDialogPrimitive.Overlay
        data-slot="alert-dialog-overlay"
        className="fixed inset-0 z-50 bg-foreground/45 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:animate-in data-[state=open]:fade-in-0"
      />
      <AlertDialogPrimitive.Content
        data-slot="alert-dialog-content"
        className={cn(
          'fixed top-1/2 left-1/2 z-50 flex w-[calc(100%-2rem)] max-w-88 -translate-x-1/2 -translate-y-1/2 flex-col gap-3 rounded-xl border border-border bg-card p-5 text-card-foreground shadow-lg data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95',
          className
        )}
        {...props}
      />
    </AlertDialogPrimitive.Portal>
  )
}

function AlertDialogTitle({
  className,
  ...props
}: React.ComponentProps<typeof AlertDialogPrimitive.Title>) {
  return (
    <AlertDialogPrimitive.Title
      data-slot="alert-dialog-title"
      className={cn('text-lg leading-snug font-semibold', className)}
      {...props}
    />
  )
}

function AlertDialogDescription({
  className,
  ...props
}: React.ComponentProps<typeof AlertDialogPrimitive.Description>) {
  return (
    <AlertDialogPrimitive.Description
      data-slot="alert-dialog-description"
      className={cn('text-sm text-muted-foreground', className)}
      {...props}
    />
  )
}

/*
 * Os dois botões, lado a lado e do mesmo tamanho. Em celular, decisão de um
 * toque não se toma com um botão pequeno ao lado de um grande — e nenhum dos
 * dois é o caminho "óbvio" a ponto de merecer destaque: a confirmação existe
 * justamente para ela parar e escolher.
 */
function AlertDialogFooter({
  className,
  ...props
}: React.ComponentProps<'div'>) {
  return (
    <div
      data-slot="alert-dialog-footer"
      className={cn('mt-1 flex gap-2 *:flex-1', className)}
      {...props}
    />
  )
}

function AlertDialogCancel({
  className,
  ...props
}: React.ComponentProps<typeof AlertDialogPrimitive.Cancel>) {
  return (
    <AlertDialogPrimitive.Cancel
      data-slot="alert-dialog-cancel"
      className={cn(buttonVariants({ variant: 'outline' }), className)}
      {...props}
    />
  )
}

function AlertDialogAction({
  className,
  ...props
}: React.ComponentProps<typeof AlertDialogPrimitive.Action>) {
  return (
    <AlertDialogPrimitive.Action
      data-slot="alert-dialog-action"
      className={cn(buttonVariants(), className)}
      {...props}
    />
  )
}

export {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogTitle,
}
