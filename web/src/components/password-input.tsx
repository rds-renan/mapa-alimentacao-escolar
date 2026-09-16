import { useState } from 'react'
import { Eye, EyeOff } from 'lucide-react'

import { Input } from '@/components/ui/input'
import { cn } from 'cn'

/*
 * Campo de senha com o olho de mostrar. O botão fica **dentro** do campo, no
 * alvo de toque de 44 px, e é um `button` de verdade: tem nome acessível que
 * diz a ação ("Mostrar senha" / "Ocultar senha"), tem estado (`aria-pressed`)
 * e não envia o formulário ao ser tocado, que é o erro clássico de botão sem
 * `type` dentro de `form`.
 *
 * A senha nasce escondida, como se espera, e o navegador continua enxergando o
 * campo como senha para o preenchimento automático — o que muda ao mostrar é
 * só o tipo do campo enquanto o olho está apertado.
 */
export function PasswordInput({
  className,
  ...props
}: Omit<React.ComponentProps<typeof Input>, 'type'>) {
  const [visible, setVisible] = useState(false)

  return (
    <div className="relative">
      <Input
        {...props}
        type={visible ? 'text' : 'password'}
        className={cn('pr-touch', className)}
      />
      <button
        type="button"
        onClick={() => setVisible((atual) => !atual)}
        aria-label={visible ? 'Ocultar senha' : 'Mostrar senha'}
        aria-pressed={visible}
        className="absolute inset-y-0 right-0 flex size-touch items-center justify-center rounded-md text-muted-foreground transition-colors hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-none"
      >
        {visible ? (
          <EyeOff className="size-5" aria-hidden="true" />
        ) : (
          <Eye className="size-5" aria-hidden="true" />
        )}
      </button>
    </div>
  )
}
