/*
 * O freio de tentativas de senha. Guarda quantas falharam seguidas e até
 * quando o formulário fica esperando.
 *
 * **Isto não é o que barra um ataque.** É freio de interface: mora no
 * navegador, e quem quiser burlá-lo limpa o armazenamento. Quem barra de
 * verdade é o Supabase, que conta as tentativas por endereço de rede, e o
 * desafio contra robôs, quando ligado. O freio aqui existe por outro motivo,
 * legítimo: quem errou a senha cinco vezes seguidas não vai acertar na sexta,
 * e insistir depressa só piora — para a pessoa e para o servidor.
 *
 * A espera cresce a cada série de erros, e é por isso que ela não é um número
 * só: um engano de digitação custa um minuto; insistência custa mais.
 */
const STORAGE_KEY = 'mae.sign-in-attempts'

/** Quantos erros seguidos até a primeira espera. */
export const MAX_ATTEMPTS = 5

/** As esperas, em segundos, a cada série de erros: 1 min, 5 min, 15 min. */
const WAITS = [60, 300, 900]

export interface AttemptState {
  failures: number
  blockedUntil: number
}

const EMPTY: AttemptState = { failures: 0, blockedUntil: 0 }

function read(): AttemptState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return EMPTY

    const parsed = JSON.parse(raw) as Partial<AttemptState>
    return {
      failures: Number(parsed.failures) || 0,
      blockedUntil: Number(parsed.blockedUntil) || 0,
    }
  } catch {
    // Armazenamento bloqueado ou conteúdo estragado: começa do zero. Um freio
    // que não consegue se lembrar não pode trancar ninguém para fora.
    return EMPTY
  }
}

function write(state: AttemptState) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
  } catch {
    // Idem: sem onde guardar, o freio simplesmente não freia.
  }
}

/** Quanto falta da espera, em milissegundos. Zero quando não há espera. */
export function remainingWait(now = Date.now()): number {
  return Math.max(0, read().blockedUntil - now)
}

/** Registra um erro de senha e devolve quanto tempo o formulário vai esperar. */
export function registerFailure(now = Date.now()): number {
  const failures = read().failures + 1

  if (failures % MAX_ATTEMPTS !== 0) {
    write({ failures, blockedUntil: 0 })
    return 0
  }

  const serie = Math.floor(failures / MAX_ATTEMPTS) - 1
  const wait = WAITS[Math.min(serie, WAITS.length - 1)] * 1000
  write({ failures, blockedUntil: now + wait })

  return wait
}

/** Entrou: a contagem morre aqui. */
export function clearAttempts() {
  try {
    localStorage.removeItem(STORAGE_KEY)
  } catch {
    // Sem armazenamento não há contagem para apagar.
  }
}
