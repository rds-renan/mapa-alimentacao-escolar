import { dayAndMonth, weekdayName } from '@/month/month'

/*
 * Os textos da área da direção. Mesmas três regras do catálogo de avisos da
 * E3: nenhuma mensagem culpa quem está lendo, o erro diz primeiro o que não se
 * perdeu, e nada de jargão.
 *
 * "Desativar" e não "excluir", como no catálogo de gêneros e pelo mesmo
 * motivo, aqui mais forte: o acesso sai do ar e a pessoa continua no sistema,
 * porque a autoria dos mapas, dos documentos e dos desbloqueios que ela deixou
 * é parte da auditoria (decisão 2 da E4).
 */

export const ADMIN_MESSAGES = {
  brand: 'MAE',
  brandSubtitle: 'Mapa da Alimentação Escolar',
  dashboard: 'Painel',
  management: 'Gestão',
  maps: 'Mapas',
  openMenu: 'Abrir a navegação',
  role: 'Direção',

  managementTitle: 'Gestão',
  managementSubtitle: 'Merendeiras, modelo oficial e dados da escola',

  mapsTitle: 'Mapas',
  mapsSubtitle: 'Dias que saíram em documento e podem ser reabertos',
} as const

// ---------------------------------------------------------------------------
// Merendeiras (US016)
// ---------------------------------------------------------------------------

export const COOKS_MESSAGES = {
  title: 'Merendeiras',
  subtitle: 'Quem pode registrar o mapa da escola',

  columnName: 'Nome',
  columnEmail: 'E-mail',
  columnStatus: 'Situação',
  columnLastAccess: 'Último acesso',

  active: 'Ativa',
  inactive: 'Sem acesso',
  neverAccessed: 'Nunca entrou',

  newTitle: 'Cadastrar merendeira',
  newSubtitle:
    'Ela recebe um e-mail para criar a própria senha. A direção não define senha de ninguém.',
  cancel: 'Cancelar',
  nameLabel: 'Nome',
  namePlaceholder: 'Maria da Silva',
  emailLabel: 'E-mail',
  emailPlaceholder: 'nome@dominio.com.br',
  create: 'Cadastrar e enviar o convite',
  creating: 'Cadastrando…',

  resetPassword: 'Redefinir senha',
  deactivate: 'Desativar',
  reactivate: 'Reativar',

  loading: 'Carregando as merendeiras…',
  loadFailed:
    'Não deu para carregar a lista. Nada foi perdido — foi só a lista que não veio.',
  retry: 'Tentar de novo',
  empty: 'Nenhuma merendeira cadastrada ainda.',

  invalid: 'Preencha o nome e um e-mail válido.',
  createFailed:
    'Não deu para cadastrar agora, quase sempre é a internet. O que você escreveu continua no formulário — é só tentar de novo.',
  updateFailed: 'Não deu para mudar o acesso agora. Tente de novo.',
  resetFailed: 'Não deu para enviar o e-mail agora. Tente de novo.',
} as const

/**
 * O que sai depois de cadastrar.
 *
 * Diz o que a direção precisa fazer em seguida — nada — e o que a merendeira
 * vai encontrar. Sem isso, a direção fica esperando uma senha que não existe.
 */
export function inviteSentLabel(name: string, email: string): string {
  return `${name} foi cadastrada. O e-mail para criar a senha foi enviado para ${email}.`
}

/**
 * Cadastrou, mas o e-mail não saiu. O acesso existe — o que falta é o convite,
 * e o botão que o reenvia é o mesmo "Redefinir senha" da linha dela.
 */
export function inviteFailedLabel(name: string): string {
  return `${name} foi cadastrada, mas o e-mail para criar a senha não saiu. Use "Redefinir senha" na linha dela para enviar de novo.`
}

export function resetSentLabel(name: string, email: string): string {
  return `O e-mail para criar uma senha nova foi enviado para ${email}, de ${name}.`
}

export function deactivatedLabel(name: string): string {
  return `${name} não entra mais no aplicativo. Os mapas e os documentos que ela registrou continuam como estão.`
}

export function reactivatedLabel(name: string): string {
  return `${name} voltou a ter acesso.`
}

/** "Desativar o acesso de Maria", o rótulo que o leitor de tela anuncia. */
export function deactivateLabel(name: string): string {
  return `Desativar o acesso de ${name}`
}

export function reactivateLabel(name: string): string {
  return `Reativar o acesso de ${name}`
}

export function resetPasswordLabel(name: string): string {
  return `Enviar e-mail de senha nova para ${name}`
}

/** "Hoje, 14h32", "12/09/2026" ou o que dizer quando ela nunca entrou. */
export function lastAccessLabel(lastAccess: string | null): string {
  if (!lastAccess) return COOKS_MESSAGES.neverAccessed

  const when = new Date(lastAccess)
  if (Number.isNaN(when.getTime())) return COOKS_MESSAGES.neverAccessed

  const time = when
    .toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
    .replace(':', 'h')

  const today = new Date()
  const sameDay = when.toDateString() === today.toDateString()
  if (sameDay) return `Hoje, ${time}`

  const yesterday = new Date(today)
  yesterday.setDate(today.getDate() - 1)
  if (when.toDateString() === yesterday.toDateString()) {
    return `Ontem, ${time}`
  }

  return when.toLocaleDateString('pt-BR')
}

// ---------------------------------------------------------------------------
// Modelo oficial (US015)
// ---------------------------------------------------------------------------

export const TEMPLATE_MESSAGES = {
  title: 'Modelo oficial do documento',
  subtitle: 'Todo documento é gerado a partir deste arquivo',

  none: 'A escola ainda não tem um modelo oficial. Sem ele, nenhum documento é gerado.',
  privacy:
    'O arquivo fica guardado em área privada e não aparece para as merendeiras.',

  replace: 'Substituir modelo',
  upload: 'Enviar modelo',
  download: 'Baixar',
  sending: 'Enviando…',

  loading: 'Carregando o modelo…',
  loadFailed: 'Não deu para saber qual é o modelo vigente agora.',
  retry: 'Tentar de novo',

  wrongType:
    'O modelo tem de ser um arquivo .docx, como o que a prefeitura envia.',
  tooLarge: 'O arquivo é grande demais para ser um modelo de documento.',
  uploadFailed:
    'Não deu para enviar o modelo agora. O modelo que já estava vigente continua valendo.',
  downloadFailed: 'Não deu para baixar o modelo agora. Tente de novo.',
  replaced:
    'O modelo novo passou a valer. Os próximos documentos saem com ele.',
} as const

/** "Substituído em 20/08/2026", o que a direção precisa saber do arquivo. */
export function templateReplacedLabel(uploadedAt: string): string {
  const when = new Date(uploadedAt)
  if (Number.isNaN(when.getTime())) return ''

  return `Enviado em ${when.toLocaleDateString('pt-BR')}`
}

// ---------------------------------------------------------------------------
// Dados da escola (US015)
// ---------------------------------------------------------------------------

export const SCHOOL_MESSAGES = {
  title: 'Dados da escola',
  subtitle: 'Preenchem o cabeçalho do documento oficial',

  nameLabel: 'Nome da escola',
  namePlaceholder: 'Escola Municipal…',
  cityLabel: 'Município',
  cityPlaceholder: 'Município',
  yearLabel: 'Ano letivo',

  save: 'Salvar alterações',
  saving: 'Salvando…',
  saved:
    'Os dados da escola foram salvos. Os próximos documentos saem com eles.',

  loading: 'Carregando os dados da escola…',
  loadFailed: 'Não deu para carregar os dados da escola.',
  retry: 'Tentar de novo',

  incomplete: 'Preencha o nome, o município e o ano letivo.',
  saveFailed:
    'Não deu para salvar agora, quase sempre é a internet. O que você escreveu continua no formulário — é só tentar de novo.',
} as const

// ---------------------------------------------------------------------------
// Mapas em documento e reabertura (US023)
// ---------------------------------------------------------------------------

/*
 * "Reabrir", e não "desbloquear": o que a direção faz é devolver o dia para a
 * merendeira corrigir, e é assim que a história descreve o gesto. "Desbloquear"
 * nomeia a coluna do banco, não a ação de quem está na tela — e diria, de
 * quebra, que a direção mexe no mapa, que é justamente o que a RN#1 nega.
 */
export const LOCKED_MAPS_MESSAGES = {
  title: 'Dias em documento',
  subtitle: 'Bloqueados para edição desde a geração do documento',

  loading: 'Carregando os dias…',
  loadFailed:
    'Não deu para carregar os dias agora. Nada foi alterado — foi só a lista que não veio.',
  retry: 'Tentar de novo',
  empty:
    'Nenhum dia saiu em documento ainda. Um dia fica bloqueado quando a merendeira gera o documento que o inclui.',

  reopen: 'Reabrir',
} as const

/** "Sexta, 4 de setembro" — como a direção lê o dia da lista e do diálogo. */
export function dayLabel(mapDate: string): string {
  return `${weekdayName(mapDate)}, ${dayAndMonth(mapDate)}`
}

/** "No documento de 30/09" — onde o dia foi parar, que é o que o bloqueou. */
export function inDocumentLabel(generatedAt: string | null): string {
  const when = generatedAt ? new Date(generatedAt) : null

  if (!when || Number.isNaN(when.getTime())) return 'Em documento gerado'
  return `No documento de ${when.toLocaleDateString('pt-BR')}`
}

/** O rótulo que o leitor de tela anuncia no botão da linha. */
export function reopenLabel(dayLabel: string): string {
  return `Reabrir o mapa de ${dayLabel}`
}

/**
 * A lista mostra os mais recentes, e diz isso quando chega ao limite.
 *
 * Não é paginação por metade: correção aparece dias depois da geração, não
 * meses, e uma escola bloqueia cerca de vinte dias por mês. Dizer o corte é
 * mais honesto do que uma lista que parece completa e não é.
 */
export function recentOnlyLabel(count: number): string {
  return `Aparecem os ${count} dias mais recentes.`
}

export const REOPEN_MESSAGES = {
  reasonLabel: 'Justificativa',
  reasonPlaceholder: 'Ex.: o número de refeições do dia saiu trocado',
  reasonHint:
    'Obrigatória. Fica registrada com o seu nome e a data, e não se apaga.',
  cancel: 'Cancelar',
  confirm: 'Reabrir o mapa',
  reopening: 'Reabrindo…',
  /*
   * O erro diz primeiro o que não mudou. Aqui isso é informação operacional, e
   * verificável: a reabertura é uma transação só — ou registra e desbloqueia,
   * ou não faz nada.
   */
  failed:
    'Não deu para reabrir agora, quase sempre é a internet. O mapa continua bloqueado e o que você escreveu continua no formulário.',
} as const

/** "Reabrir o mapa de sexta, 4 de setembro?" — o título do diálogo. */
export function reopenTitle(dayLabel: string): string {
  return `Reabrir o mapa de ${dayLabel}?`
}

export const REOPEN_BODY =
  'A merendeira volta a poder editar este dia. O documento que já saiu continua registrado como foi, e depois da correção ela gera o documento do período de novo.'

export function reopenedLabel(dayLabel: string): string {
  return `O mapa de ${dayLabel} foi reaberto. A merendeira já pode corrigir o dia.`
}

export const UNLOCKS_MESSAGES = {
  title: 'Reaberturas',
  subtitle: 'Registro permanente: não se apaga nem se edita',

  loading: 'Carregando o histórico…',
  loadFailed:
    'Não deu para carregar o histórico agora. Ele não se perde — foi só a leitura que não veio.',
  retry: 'Tentar de novo',
  empty: 'Nenhum mapa foi reaberto até agora.',
} as const

/** "Reaberto por Direção em 02/10/2026, 14h32" — a linha do histórico. */
export function unlockedByLabel(name: string, unlockedAt: string): string {
  const when = new Date(unlockedAt)

  if (Number.isNaN(when.getTime())) return `Reaberto por ${name}`

  const time = when
    .toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
    .replace(':', 'h')

  return `Reaberto por ${name} em ${when.toLocaleDateString('pt-BR')}, ${time}`
}
