import { useState } from 'react'
import { LogOut } from 'lucide-react'

import { Button } from '@/components/ui/button'

import { useAuth } from './useAuth'

/*
 * Sair: encerra a sessão e apaga o que era da pessoa no aparelho (CA#5 da
 * issue #59). O lugar definitivo deste botão é o menu do aplicativo (issue
 * #61) e a área da direção; enquanto as telas não existem, ele mora aqui para
 * que a saída exista desde já.
 */
export function SignOutButton() {
  const { signOut } = useAuth()
  const [leaving, setLeaving] = useState(false)

  return (
    <Button
      variant="ghost"
      size="sm"
      disabled={leaving}
      onClick={() => {
        setLeaving(true)
        void signOut()
      }}
    >
      <LogOut aria-hidden="true" />
      Sair
    </Button>
  )
}
