import 'package:flutter/material.dart';

/// Campo de senha com o olho de mostrar, dentro do próprio campo — o mesmo
/// desenho de `web/src/components/password-input.tsx`. A senha nasce
/// escondida, e o botão tem nome acessível que diz a ação e o estado
/// (`tooltip` + `Semantics`), como a E3 pede.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.autofillHints,
    this.errorText,
    this.helperText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText,
        errorText: widget.errorText,
        helperText: widget.helperText,
        suffixIcon: IconButton(
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          tooltip: _visible ? 'Ocultar senha' : 'Mostrar senha',
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
