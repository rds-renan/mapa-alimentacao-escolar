import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_messages.dart';
import '../auth/email_format.dart';
import '../theme/theme.dart';
import '../widgets/entry_scaffold.dart';
import '../widgets/form_message.dart';
import '../widgets/password_field.dart';
import 'forgot_password_page.dart';

/// Tela 1 da E3: a única porta de entrada. Não há autocadastro — o acesso é
/// criado pela direção (CA#3 da US016), e é isso que o rodapé explica para
/// quem chegar aqui sem conta. Mesmos textos de `web/src/pages/SignIn.tsx`
/// (issue #59); o erro não diz qual dos dois campos está errado.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  static const path = '/entrar';

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();

  String? _error;
  bool _emailInvalid = false;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text;

    if (!isValidEmail(email)) {
      /*
       * Trava aqui: já se sabe que não é e-mail, e mandar assim traria de
       * volta o erro de senha — que não é o problema.
       */
      setState(() {
        _emailInvalid = true;
        _error = null;
      });
      _emailFocus.requestFocus();
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    final error = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: email, password: _passwordController.text);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(authControllerProvider.select((s) => s.notice));

    return EntryScaffold(
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: kSpacingUnit,
        children: [
          const Icon(Icons.lock_outline, size: 14),
          Text(
            'O acesso é criado pela direção da escola',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: kSpacingUnit * 3.5,
        children: [
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            decoration: InputDecoration(
              labelText: 'E-mail',
              errorText: _emailInvalid ? AuthMessages.emailInvalid : null,
            ),
            onChanged: (_) {
              if (_emailInvalid || _error != null) {
                setState(() {
                  _emailInvalid = false;
                  _error = null;
                });
              }
            },
            /*
             * Ao sair do campo, e não a cada tecla: ninguém quer ser
             * corrigido no meio da digitação de um e-mail que ainda não
             * terminou.
             */
            onEditingComplete: () {
              final typed = _emailController.text.trim();
              if (typed.isNotEmpty && !isValidEmail(typed)) {
                setState(() {
                  _emailInvalid = true;
                  _error = null;
                });
              }
              FocusScope.of(context).nextFocus();
            },
          ),
          PasswordField(
            controller: _passwordController,
            labelText: 'Senha',
            autofillHints: const [AutofillHints.password],
          ),
          if (_error != null) FormMessage(_error!),
          if (_error == null && notice != null) FormMessage(notice),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Entrando…' : 'Entrar'),
          ),
          TextButton(
            onPressed: () => context.push(ForgotPasswordPage.path),
            child: const Text('Esqueci minha senha'),
          ),
        ],
      ),
    );
  }
}
