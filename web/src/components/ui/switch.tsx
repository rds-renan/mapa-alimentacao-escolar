import * as React from 'react'
import { cn } from 'cn'
import { Switch as SwitchPrimitive } from 'radix-ui'

/*
 * A alternância, no tamanho do desenho da E3 (50 × 30 px) e não no da
 * biblioteca, que é de desktop: é ela que liga o dia não letivo, com o dedo,
 * na mesma tela do registro (RNF#1 da US006). A área de toque vai além do
 * desenho pelo `after`, para cobrir os 44 px da decisão 6 da E3 sem engordar
 * o traço na tela.
 */
function Switch({
  className,
  ...props
}: React.ComponentProps<typeof SwitchPrimitive.Root>) {
  return (
    <SwitchPrimitive.Root
      data-slot="switch"
      className={cn(
        'peer group/switch relative inline-flex h-[1.875rem] w-[3.125rem] shrink-0 items-center rounded-full border border-transparent p-[3px] transition-colors outline-none after:absolute after:-inset-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 data-checked:bg-primary data-unchecked:bg-input dark:data-unchecked:bg-input/80 data-disabled:cursor-not-allowed data-disabled:opacity-50',
        className
      )}
      {...props}
    >
      <SwitchPrimitive.Thumb
        data-slot="switch-thumb"
        className="pointer-events-none block size-6 rounded-full bg-background shadow-sm ring-0 transition-transform data-checked:translate-x-5 dark:data-checked:bg-primary-foreground data-unchecked:translate-x-0 dark:data-unchecked:bg-foreground"
      />
    </SwitchPrimitive.Root>
  )
}

export { Switch }
