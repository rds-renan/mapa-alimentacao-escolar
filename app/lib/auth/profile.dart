/// O perfil de quem está usando o aplicativo — leitura da tabela `profile`,
/// como a web faz em `web/src/auth/auth-context.ts`.
///
/// Saber o papel aqui é conveniência de interface, não controle de acesso: a
/// decisão 5 da E6 repete o que a decisão 6 da E5 já dizia — quem decide o
/// que a merendeira lê e escreve são as políticas de RLS da E4, no banco.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.schoolId,
  });

  factory Profile.fromRow(Map<String, dynamic> row) => Profile(
    id: row['id'] as String,
    name: row['name'] as String,
    email: row['email'] as String,
    role: row['role'] as String,
    schoolId: row['school_id'] as String,
  );

  final String id;
  final String name;
  final String email;

  /// `'admin'` ou `'cook'` (`public.user_role` no banco). O aplicativo é só
  /// da merendeira (decisão 1 da E6) — quem chega com o outro papel é
  /// recusado antes de qualquer tela aparecer.
  final String role;
  final String schoolId;

  bool get isCook => role == 'cook';
}
