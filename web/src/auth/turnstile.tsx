import { useEffect, useRef } from 'react'

import { TURNSTILE_SITE_KEY } from './captcha'

/*
 * O desafio contra robôs, do Turnstile da Cloudflare — a mesma casa que já
 * hospeda a web. Ele resolve sozinho na maioria das vezes, sem pedir nada a
 * quem está do outro lado: o objetivo é não colocar mais um obstáculo entre a
 * merendeira e o aplicativo, e sim entre o aplicativo e quem tenta senha em
 * série.
 *
 * O componente só é montado quando há chave configurada. O código do desafio
 * vale uma vez só: depois de um login recusado, o widget é remontado para
 * pedir outro (ver o `key` na tela de login).
 */

interface TurnstileApi {
  render(
    container: HTMLElement,
    options: {
      sitekey: string
      callback: (token: string) => void
      'expired-callback': () => void
      'error-callback': () => void
      theme: 'auto' | 'light' | 'dark'
    }
  ): string
  remove(widgetId: string): void
}

declare global {
  interface Window {
    turnstile?: TurnstileApi
  }
}

const SCRIPT_URL =
  'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'

let loading: Promise<void> | null = null

function loadScript(): Promise<void> {
  if (loading) return loading

  loading = new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = SCRIPT_URL
    script.async = true
    script.defer = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('turnstile indisponível'))
    document.head.append(script)
  })

  return loading
}

export function Turnstile({
  onToken,
}: {
  /** Recebe o código do desafio, ou `null` quando ele expira ou falha. */
  onToken: (token: string | null) => void
}) {
  const container = useRef<HTMLDivElement>(null)
  // O retorno mais recente, para o efeito não depender dele e remontar o
  // widget a cada desenho da tela.
  const callback = useRef(onToken)
  useEffect(() => {
    callback.current = onToken
  }, [onToken])

  useEffect(() => {
    let active = true
    let widgetId: string | undefined

    void loadScript()
      .then(() => {
        if (!active || !container.current || !window.turnstile) return

        widgetId = window.turnstile.render(container.current, {
          sitekey: TURNSTILE_SITE_KEY,
          callback: (token) => callback.current(token),
          'expired-callback': () => callback.current(null),
          'error-callback': () => callback.current(null),
          theme: 'auto',
        })
      })
      .catch(() => {
        /*
         * O desafio não carregou — rede ruim, bloqueador, o serviço fora do
         * ar. Quem decide o que fazer é o servidor: se ele exigir o desafio, o
         * login é recusado e a mensagem aparece; se não exigir, a merendeira
         * entra. O que não se faz é trancar a porta do lado de cá.
         */
        if (active) callback.current(null)
      })

    return () => {
      active = false
      if (widgetId) window.turnstile?.remove(widgetId)
    }
  }, [])

  return <div ref={container} className="flex justify-center empty:hidden" />
}
