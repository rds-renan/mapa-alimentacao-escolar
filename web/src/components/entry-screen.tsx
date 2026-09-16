import { Brand } from './brand'

/*
 * O contorno das três telas que existem antes de entrar: login, pedido de
 * senha nova e senha nova. Largura de celular com container central na web,
 * como a decisão 1 da E3 definiu.
 */
export function EntryScreen({
  children,
  footer,
}: {
  children: React.ReactNode
  footer?: React.ReactNode
}) {
  return (
    <div className="flex min-h-dvh flex-col bg-background px-6 pt-8 pb-6">
      <div className="mx-auto flex w-full max-w-screen flex-1 flex-col justify-center gap-8">
        <Brand />
        {children}
      </div>
      {footer ? (
        <div className="mx-auto w-full max-w-screen pt-4">{footer}</div>
      ) : null}
    </div>
  )
}
