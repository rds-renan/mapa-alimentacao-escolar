# app/

O aplicativo Android do MAE: Flutter, Material 3 sobre os tokens da E3,
falando direto com o Supabase.

```bash
supabase start                              # na raiz do repositório
cp env/local.example.json env/local.json    # e preencha com o que o supabase start imprimiu
flutter pub get
flutter run --dart-define-from-file=env/local.json
```

O que cada comando faz, os tokens no tema e os ambientes estão em
[`docs/06-app/fundacao-do-app.md`](../docs/06-app/fundacao-do-app.md). O
porquê da stack está nas
[decisões técnicas](../docs/06-app/decisoes-tecnicas.md).
