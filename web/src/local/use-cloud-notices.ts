import { useEffect, useRef } from 'react'
import { toast } from 'sonner'

import { CloudNotices } from './cloud-notices'
import type { DaySyncState } from './sync'

/*
 * Os avisos da nuvem do dia em toast (issue #178). Um por vez: o novo toma o
 * lugar do anterior pelo mesmo `id`, porque um aviso velho chegando depois
 * diria um estado que já passou. Trocar de dia recomeça a contagem.
 */
export function useCloudNotices(
  mapDate: string,
  status: DaySyncState | null
): void {
  const notices = useRef<CloudNotices | null>(null)

  useEffect(() => {
    const current = new CloudNotices((text) =>
      toast(text, { id: 'aviso-da-nuvem' })
    )
    notices.current = current
    return () => current.dispose()
  }, [mapDate])

  useEffect(() => {
    notices.current?.update(status)
  }, [status])
}
