import { supabase } from '@/lib/supabase'
import { ROUTES } from '@/routes'

/*
 * O e-mail que leva à tela de criar senha.
 *
 * Dois lugares o disparam, e é de propósito que seja a mesma chamada: a
 * merendeira que esqueceu a senha, na tela de login (issue #59), e a direção,
 * na gestão de acessos — tanto ao cadastrar alguém quanto ao redefinir a senha
 * de quem já existe (issue #68). Um caminho só significa um endereço de volta
 * só: mudar `/nova-senha` de lugar não pode deixar um dos dois para trás.
 *
 * O erro volta cru. Quem chama é que sabe traduzi-lo: a tela de login não diz
 * se o e-mail existe, e a gestão de acessos fala com quem já sabe que ele
 * existe — porque acabou de cadastrá-lo.
 */
export async function sendPasswordEmail(
  email: string,
  captchaToken?: string | null
) {
  const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
    redirectTo: `${window.location.origin}${ROUTES.newPassword}`,
    ...(captchaToken ? { captchaToken } : {}),
  })

  return error
}
