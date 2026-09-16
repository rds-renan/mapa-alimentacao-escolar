/*
 * O logo com o nome, como nas telas de entrada da E3: é a única marca do
 * aplicativo, e ela aparece nas três telas que existem antes do login.
 */
export function Brand() {
  return (
    <div className="flex flex-col items-center gap-3.5">
      <img src="/logo.png" alt="" className="size-22" />
      <div className="flex flex-col items-center gap-1">
        <span className="text-3xl font-semibold tracking-tight">MAE</span>
        <span className="text-sm text-muted-foreground">
          Mapa da Alimentação Escolar
        </span>
      </div>
    </div>
  )
}
