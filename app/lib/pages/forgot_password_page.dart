import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_messages.dart';
import '../auth/email_format.dart';
import '../theme/theme.dart';
import '../widgets/entry_scaffold.dart';
import '../widgets/form_message.dart';
import '../widgets/password_field.dart';

/// "Esqueci minha senha" (issue #101, decisão 9 da E6): pede o código,
/// digita o código e a senha nova **na mesma tela**. Nada disso abre o
/// navegador — o caminho que a web percorre em duas telas (pedido de link e
/// senha nova) aqui é um só, porque o que chega por e-mail não é um link
/// para abrir, é um número para digitar. Serve também o convite da direção.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  static const path = '/esqueci-a-senha';

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _emailInvalid = false;
  bool _codeSent = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text;

    if (!isValidEmail(email)) {
      setState(() {
        _emailInvalid = true;
        _error = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    final error = await ref
        .read(authControllerProvider.notifier)
        .requestRecoveryCode(email);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (error != null) {
        _error = error;
      } else {
        _codeSent = true;
      }
    });
  }

  Future<void> _confirmCode() async {
    if (_passwordController.text.length < AuthMessages.minimumPasswordLength) {
      setState(() => _error = AuthMessages.passwordTooShort);
      return;
    }

    if (_passwordController.text != _confirmationController.text) {
      setState(() => _error = AuthMessages.passwordMismatch);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    final error = await ref
        .read(authControllerProvider.notifier)
        .confirmRecoveryCode(
          email: _emailController.text,
          code: _codeController.text,
          newPassword: _passwordController.text,
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }

    // A troca de senha já autenticou o aparelho — o router leva à casa da
    // merendeira sozinho, pela mudança de estado da autenticação.
  }

  void _startOver() {
    setState(() {
      _codeSent = false;
      _error = null;
      _codeController.clear();
      _passwordController.clear();
      _confirmationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return EntryScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: kSpacingUnit * 3.5,
        children: [
          Text(
            'Esqueci minha senha',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            _codeSent
                ? 'Chegou um código de 6 dígitos para $_displayEmail. '
                      'Digite-o abaixo com a senha nova.'
                : 'Informe o e-mail do seu acesso. Mandamos um código para '
                      'você criar uma senha nova.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextField(
            controller: _emailController,
            enabled: !_codeSent,
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
          ),
          if (_codeSent) ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
                counterText: '',
              ),
            ),
            PasswordField(
              controller: _passwordController,
              labelText: 'Senha nova',
              autofillHints: const [AutofillHints.newPassword],
              helperText:
                  'Pelo menos ${AuthMessages.minimumPasswordLength} caracteres.',
            ),
            PasswordField(
              controller: _confirmationController,
              labelText: 'Repita a senha nova',
              autofillHints: const [AutofillHints.newPassword],
            ),
          ],
          if (_error != null) FormMessage(_error!),
          if (_error == null && _codeSent)
            const FormMessage(
              AuthMessages.codeSent,
              kind: FormMessageKind.success,
            ),
          FilledButton(
            onPressed: _submitting
                ? null
                : (_codeSent ? _confirmCode : _requestCode),
            child: Text(
              _submitting
                  ? (_codeSent ? 'Salvando…' : 'Enviando…')
                  : (_codeSent ? 'Trocar a senha' : 'Enviar o código'),
            ),
          ),
          if (_codeSent)
            TextButton(
              onPressed: _submitting ? null : _startOver,
              child: const Text('Pedir código para outro e-mail'),
            )
          else
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar para o login'),
            ),
        ],
      ),
    );
  }

  String get _displayEmail => _emailController.text.trim();
}
